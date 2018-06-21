$ModuleName = 'DbVisualizer'
$ModuleManifestName = 'DbVisualizer\DbVisualizer.psd1'
$ModuleManifestPath = "$PSScriptRoot\..\$ModuleManifestName"
Import-Module -FullyQualifiedName $moduleManifestPath -Force

Describe 'Module Manifest Tests' {
    Context 'Strict mode' {
        Set-StrictMode -Version 3.0

        It 'Should load' {
            $module = Get-Module -Name $ModuleName
            $module.Name | Should be $ModuleName
        }
    }

    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $ModuleManifestPath | Should -Not -BeNullOrEmpty
        $? | Should Be $true
    }
}