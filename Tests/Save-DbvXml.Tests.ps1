. "$PSScriptRoot\Header.ps1"

Describe 'Save-DbvXml Tests' {
    InModuleScope -ModuleName 'DbVisualizer' {
        Context 'Command Usage' {
            $command = Get-Command -Module 'DbVisualizer' -Name 'Save-DbvXml'

            It 'Should exist' {
                $command | Should -Not -BeNullOrEmpty
            }

            It 'Should have a Xml parameter' {
                $command.Parameters.ContainsKey('Xml') | Should Be $true
            }

            It 'Should have a Path parameter' {
                $command.Parameters.ContainsKey('Path') | Should Be $true
            }

            It "Should error if trying to save to an invalid path" {
                $path = 'R:\MadeUpFile.xml'
                { Save-DbvXml -Xml '<test><element1>value</element1></test>' -Path $path } | Should Throw "Could not save to path '$path'."
            }
        }

        Context 'Functionality' {
            It 'Should save XML to a file' {
                $parent = [System.IO.Path]::GetTempPath()
                $name = [System.IO.Path]::GetRandomFileName()

                $filePath = Join-Path -Path $parent -ChildPath $name

                $xml = [xml]'<test><element1>value</element1></test>'
                Save-DbvXml -Xml $xml -Path $filePath

                $output = [xml](Get-Content -Path $filePath -Raw)
                $output.OuterXml | Should -Be $xml.OuterXml
            }
        }
    }
}