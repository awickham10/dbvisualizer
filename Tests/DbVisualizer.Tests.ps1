$ModuleName = 'DbVisualizer'
$ModuleManifestName = 'DbVisualizer\DbVisualizer.psd1'
$ModuleManifestPath = "$PSScriptRoot\..\$ModuleManifestName"

Describe 'Module Manifest Tests' {
    Context 'Strict mode' {
        Set-StrictMode -Version 3.0

        It 'Should load' {
            $module = Get-Module $ModuleName
            $module | Should -Not -BeNullOrEmpty
        }
    }

    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $ModuleManifestPath | Should -Not -BeNullOrEmpty
        $? | Should Be $true
    }
}