. "$PSScriptRoot\Header.ps1"

Describe 'Merge-DbvPreference Tests' {
    InModuleScope -ModuleName 'DbVisualizer' {
        Context 'Command Usage' {
            $command = Get-Command -Module 'DbVisualizer' -Name 'Get-DbvXml'

            It 'Should exist' {
                $command | Should -Not -BeNullOrEmpty
            }

            It 'Should have a Path parameter' {
                $command.Parameters.ContainsKey('Path') | Should Be $true
            }

            It "Should error if the file doesn't exist" {
                $path = 'C:\MadeUpFile.xml'
                { Get-DbvXml -Path $path } | Should Throw "Cannot find path '$path' because it does not exist."
            }

            It "Should error if the XML is invalid" {
                $invalidPath = 'C:\InvalidFormat.xml'

                Mock -CommandName 'Get-Content' -ParameterFilter { $Path -eq $invalidPath } -MockWith {
                    return "<test><element1></element1><element2></element4></test>"
                }

                { Get-DbvXml -Path $invalidPath } | Should Throw "Could not parse XML in '$invalidPath'"

                Assert-MockCalled -CommandName 'Get-Content' -ParameterFilter { $Path -eq $invalidPath } -Times 1
            }
        }

        Context 'Functionality' {
            It 'Should load XML from a file' {
                $mockMasterPath = '.\Tests\MockMaster.xml'

                $realMockMaster = [xml](Get-Content -Path $mockMasterPath -Raw)
                $returnMockMaster = Get-DbvXml -Path $mockMasterPath

                $returnMockMaster.OuterXml | Should -Be $realMockMaster.OuterXml
            }
        }
    }
}