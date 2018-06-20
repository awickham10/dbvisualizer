. "$PSScriptRoot\Header.ps1"

Describe 'Merge-DbvPreference Tests' {
    InModuleScope -ModuleName 'DbVisualizer' {
        Context 'Command Usage' {
            $command = Get-Command -Module 'DbVisualizer' -Name 'Merge-DbvPreference'

            It 'Should havve a Category parameter' {
                $command.Parameters.ContainsKey('Category') | Should Be $true
            }

            It 'Should have a MasterPath parameter' {
                $command.Parameters.ContainsKey('MasterPath') | Should Be $true
            }

            Mock -CommandName 'Test-Path' -ParameterFilter { $Path -eq 'C:\MadeUpMasterPath.xml' } -MockWith { $false }
            Mock -CommandName 'Test-Path' -ParameterFilter { $Path -eq 'C:\MadeUpTargetPath.xml' } -MockWith { $true }

            It 'Should validate MasterPath existence' {
                { Merge-DbvPreference -Category 'Drivers' -MasterPath 'C:\MadeUpMasterPath.xml' -TargetPath 'C:\MadeUpTargetPath.xml' } | Should Throw
                Assert-MockCalled -CommandName 'Test-Path' -ParameterFilter { $Path -eq 'C:\MadeUpMasterPath.xml' } -Times 1
            }

            It 'Should have a TargetPath parameter' {
                $command.Parameters.ContainsKey('TargetPath') | Should Be $true
            }

            It 'Should have a TargetFolder parameter' {
                $command.Parameters.ContainsKey('TargetFolder') | Should Be $true
            }

            Mock -CommandName 'Test-Path' -ParameterFilter { $Path -eq 'C:\MadeUpMasterPath.xml' } -MockWith { $true }
            Mock -CommandName 'Test-Path' -ParameterFilter { $Path -eq 'C:\MadeUpTargetPath.xml' } -MockWith { $false }

            It 'Should validate TargetPath existence' {
                Mock -CommandName 'Test-Path' -ParameterFilter { $Path -eq 'C:\MadeUpMasterPath.xml' } -MockWith { $true }
                { Merge-DbvPreference -Category 'Drivers' -MasterPath 'C:\MadeUpMasterPath.xml' -TargetPath 'C:\MadeUpTargetPath.xml' } | Should Throw

                Assert-MockCalled -CommandName 'Test-Path' -ParameterFilter { $Path -eq 'C:\MadeUpMasterPath.xml' } -Times 1
            }

            It 'Should enforce usage of TargetFolder when Category is Databases' {
                { Merge-DbvPreference -Category 'Databases' -MasterPath 'C:\MadeUpMasterPath.xml' -TargetPath 'C:\MadeUpTargetPath.xml' } | Should Throw

                Assert-MockCalled -CommandName 'Test-Path' -ParameterFilter { $Path -eq 'C:\MadeUpMasterPath.xml' } -Times 1
                Assert-MockCalled -CommandName 'Test-Path' -ParameterFilter { $Path -eq 'C:\MadeUpTargetPath.xml' } -Times 1
            }
        }

        Context 'Drivers' {
            Mock -CommandName Save-DbvXml -MockWith {
                $script:updatedXml = $Xml
            }

            $masterPath = '.\Tests\MockMaster.xml'
            $targetPath = '.\Tests\MockTarget.xml'

            $masterXml = [xml](Get-Content -Path $masterPath -Raw)
            $targetXml = [xml](Get-Content -Path $targetPath -Raw)

            It 'Adds' {
                $driverName = 'Netezza'

                $master = $masterXml.DbVisualizer.Drivers.Driver | Where-Object { $_.Name -eq $driverName }
                $master | Should -Not -BeNullOrEmpty

                $target = $targetXml.DbVisualizer.Drivers.Driver | Where-Object { $_.Name -eq $driverName }
                $target | Should -BeNullOrEmpty

                Merge-DbvPreference -Category 'Drivers' -MasterPath $masterPath -TargetPath $targetPath
                Assert-MockCalled -CommandName 'Save-DbvXml' -Times 1

                $updated = $script:updatedXml.DbVisualizer.Drivers.Driver | Where-Object { $_.Name -eq $driverName }
                $master.Name | Should -Be $updated.Name
            }

            It 'Updates' {
                $driverName = 'SQL Server (Microsoft)'

                $master = $masterXml.DbVisualizer.Drivers.Driver | Where-Object { $_.Name -eq $driverName }
                $target = $targetXml.DbVisualizer.Drivers.Driver | Where-Object { $_.Name -eq $driverName }
                $master.URLFormat | Should -Not -Be $target.URLFormat

                Merge-DbvPreference -Category 'Drivers' -MasterPath $masterPath -TargetPath $targetPath
                Assert-MockCalled -CommandName 'Save-DbvXml' -Times 1

                $after = $script:updatedXml.DbVisualizer.Drivers.Driver | Where-Object { $_.Name -eq $driverName }
                $after.URLFormat | Should -Be $master.URLFormat
            }

            It "Doesn't remove" {
                $driverName = 'DB2 z/OS'

                $master = $masterXml.DbVisualizer.Drivers.Driver | Where-Object { $_.Name -eq $driverName }
                $master | Should -BeNullOrEmpty

                $target = $targetXml.DbVisualizer.Drivers.Driver | Where-Object { $_.Name -eq $driverName }
                $target | Should -Not -BeNullOrEmpty

                Merge-DbvPreference -Category 'Drivers' -MasterPath $masterPath -TargetPath $targetPath
                Assert-MockCalled -CommandName 'Save-DbvXml' -Times 1

                $updated = $script:updatedXml.DbVisualizer.Drivers.Driver | Where-Object { $_.Name -eq $driverName }
                $target.Name | Should -Be $updated.Name
            }
        }

        Context 'Databases' {
            Mock -CommandName Save-DbvXml -MockWith {
                $script:updatedXml = $Xml
            }

            $masterPath = '.\Tests\MockMaster.xml'
            $targetPath = '.\Tests\MockTarget.xml'

            $masterXml = [xml](Get-Content -Path $masterPath -Raw)
            $targetXml = [xml](Get-Content -Path $targetPath -Raw)

            It 'Adds' {
                $databaseAlias = 'FakeDatabaseToAdd'

                $master = $masterXml.DbVisualizer.Databases.Database | Where-Object { $_.Alias -eq $databaseAlias }
                $master | Should -Not -BeNullOrEmpty

                $target = $targetXml.DbVisualizer.Databases.Database | Where-Object { $_.Alias -eq $databaseAlias }
                $target | Should -BeNullOrEmpty

                Merge-DbvPreference -Category 'Databases' -MasterPath $masterPath -TargetPath $targetPath -TargetFolder 'Managed'
                Assert-MockCalled -CommandName 'Save-DbvXml' -Times 1

                $updated = $script:updatedXml.DbVisualizer.Databases.Database | Where-Object { $_.Alias -eq $databaseAlias }
                $master.Alias | Should -Be $updated.Alias
            }

            It 'Updates' {
                $databaseAlias = 'FakeDatabaseToUpdate'

                $master = $masterXml.DbVisualizer.Databases.Database | Where-Object { $_.Alias -eq $databaseAlias }
                $masterServer = $master.UrlVariables.Driver.UrlVariable | Where-Object { $_.UrlVariableName -eq 'Server' }

                $target = $targetXml.DbVisualizer.Databases.Database | Where-Object { $_.Alias -eq $databaseAlias }
                $targetServer = $target.UrlVariables.Driver.UrlVariable | Where-Object { $_.UrlVariableName -eq 'Server' }

                $masterServer.'#text' | Should -Not -Be $targetServer.'#text'

                Merge-DbvPreference -Category 'Databases' -MasterPath $masterPath -TargetPath $targetPath -TargetFolder 'Managed'
                Assert-MockCalled -CommandName 'Save-DbvXml' -Times 1

                $after = $script:updatedXml.DbVisualizer.Databases.Database | Where-Object { $_.Alias -eq $databaseAlias }
                $afterServer = $after.UrlVariables.Driver.UrlVariable | Where-Object { $_.UrlVariableName -eq 'Server' }

                $afterServer.'#text' | Should -Be $masterServer.'#text'
            }

            It "Doesn't remove" {
                $databaseAlias = 'FakeDatabaseToNotRemove'

                $master = $masterXml.DbVisualizer.Databases.Database | Where-Object { $_.Alias -eq $databaseAlias }
                $master | Should -BeNullOrEmpty

                $target = $targetXml.DbVisualizer.Databases.Database | Where-Object { $_.Alias -eq $databaseAlias }
                $target | Should -Not -BeNullOrEmpty

                Merge-DbvPreference -Category 'Databases' -MasterPath $masterPath -TargetPath $targetPath -TargetFolder 'Managed'
                Assert-MockCalled -CommandName 'Save-DbvXml' -Times 1

                $updated = $script:updatedXml.DbVisualizer.Databases.Database | Where-Object { $_.Alias -eq $databaseAlias }
                $target.Alias | Should -Be $updated.Alias
            }
        }
    }
}