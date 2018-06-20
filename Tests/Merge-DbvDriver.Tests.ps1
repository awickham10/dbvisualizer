. "$PSScriptRoot\Header.ps1"

Describe 'Merge-DbvDriver Tests' {
    InModuleScope -ModuleName 'DbVisualizer' {
        Context 'Command Usage' {
            $command = Get-Command -Module 'DbVisualizer' -Name 'Merge-DbvDriver'
            It 'Should have a MasterPath parameter' {
                $command.Parameters.ContainsKey('MasterPath') | Should Be $true
            }

            Mock -CommandName 'Test-Path' -ParameterFilter { $Path -eq 'C:\MadeUpMasterPath.xml' } -MockWith { $false }
            Mock -CommandName 'Test-Path' -ParameterFilter { $Path -eq 'C:\MadeUpTargetPath.xml' } -MockWith { $true }

            It 'Should validate MasterPath existence' {
                { Merge-DbvDriver -MasterPath 'C:\MadeUpMasterPath.xml' -TargetPath 'C:\MadeUpTargetPath.xml' } | Should Throw
                Assert-MockCalled -CommandName 'Test-Path' -ParameterFilter { $Path -eq 'C:\MadeUpMasterPath.xml' } -Times 1
            }

            It 'Should have a TargetPath parameter' {
                $command.Parameters.ContainsKey('TargetPath') | Should Be $true
            }

            Mock -CommandName 'Test-Path' -ParameterFilter { $Path -eq 'C:\MadeUpMasterPath.xml' } -MockWith { $true }
            Mock -CommandName 'Test-Path' -ParameterFilter { $Path -eq 'C:\MadeUpTargetPath.xml' } -MockWith { $false }

            It 'Should validate TargetPath existence' {
                Mock -CommandName 'Test-Path' -ParameterFilter { $Path -eq 'C:\MadeUpMasterPath.xml' } -MockWith { $true }
                { Merge-DbvDriver -MasterPath 'C:\MadeUpMasterPath.xml' -TargetPath 'C:\MadeUpTargetPath.xml' } | Should Throw

                Assert-MockCalled -CommandName 'Test-Path' -ParameterFilter { $Path -eq 'C:\MadeUpMasterPath.xml' } -Times 1
            }
        }

        Context 'Functionality' {
            Mock -CommandName Save-DbvXml -MockWith {
                $script:updatedXml = $Xml
            }

            It 'Adds a driver' {
                $masterPath = '.\Tests\MockAddDriverMaster.xml'
                $targetPath = '.\Tests\MockAddDriverTarget.xml'

                $masterXml = [xml](Get-Content -Path $masterPath -Raw)
                $targetXml = [xml](Get-Content -Path $targetPath -Raw)

                Merge-DbvDriver -MasterPath $masterPath -TargetPath $targetPath
                Assert-MockCalled -CommandName 'Save-DbvXml' -Times 1

                $targetXml.DbVisualizer.Drivers.OuterXml | Should -Not -Be $masterXml.DbVisualizer.Drivers.OuterXml

                $beforeCount = $targetXml.DbVisualizer.Drivers.Driver.Count
                $afterCount = $script:updatedXml.DbVisualizer.Drivers.Driver.Count
                $afterCount | Should -BeGreaterThan $beforeCount
            }

            It 'Updates a driver' {
                $masterPath = '.\Tests\MockUpdateDriverMaster.xml'
                $targetPath = '.\Tests\MockUpdateDriverTarget.xml'

                $masterXml = [xml](Get-Content -Path $masterPath -Raw)
                $targetXml = [xml](Get-Content -Path $targetPath -Raw)

                Merge-DbvDriver -MasterPath $masterPath -TargetPath $targetPath
                Assert-MockCalled -CommandName 'Save-DbvXml' -Times 1

                $master = $masterXml.DbVisualizer.Drivers.Driver | Where-Object { $_.Name -eq 'SQL Server (Microsoft)' }
                $target = $targetXml.DbVisualizer.Drivers.Driver | Where-Object { $_.Name -eq 'SQL Server (Microsoft)' }
                $after = $script:updatedXml.DbVisualizer.Drivers.Driver | Where-Object { $_.Name -eq 'SQL Server (Microsoft)' }

                $master.URLFormat | Should -Not -Be $target.URLFormat
                $after.URLFormat | Should -Be $master.URLFormat
            }

            It "Doesn't change non-driver settings" {
                $masterPath = '.\Tests\MockUpdateDriverMaster.xml'
                $targetPath = '.\Tests\MockUpdateDriverTarget.xml'

                $masterXml = [xml](Get-Content -Path $masterPath -Raw)
                $targetXml = [xml](Get-Content -Path $targetPath -Raw)

                $master = $masterXml.DbVisualizer.General.AskQuit
                $target = $targetXml.DbVisualizer.General.AskQuit

                $master | Should -Not -Be $target

                Merge-DbvDriver -MasterPath $masterPath -TargetPath $targetPath
                Assert-MockCalled -CommandName 'Save-DbvXml' -Times 1

                $after = $script:updatedXml.DbVisualizer.General.AskQuit

                $target | Should -Be $after
            }

            It "Doesn't remove drivers" {
                $masterPath = '.\Tests\MockRemoveDriverMaster.xml'
                $targetPath = '.\Tests\MockRemoveDriverTarget.xml'

                $masterXml = [xml](Get-Content -Path $masterPath -Raw)
                $targetXml = [xml](Get-Content -Path $targetPath -Raw)

                Merge-DbvDriver -MasterPath $masterPath -TargetPath $targetPath
                Assert-MockCalled -CommandName 'Save-DbvXml' -Times 1

                $master = $masterXml.DbVisualizer.Drivers.Driver | Where-Object { $_.Name -eq 'SQL Server (Microsoft)' }
                $target = $targetXml.DbVisualizer.Drivers.Driver | Where-Object { $_.Name -eq 'SQL Server (Microsoft)' }
                $after = $script:updatedXml.DbVisualizer.Drivers.Driver | Where-Object { $_.Name -eq 'SQL Server (Microsoft)' }

                $master | Should -BeNullOrEmpty
                $target | Should -Not -BeNullOrEmpty
                $after | Should -Not -BeNullOrEmpty
            }
        }
    }
}