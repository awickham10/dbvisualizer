$scriptName = $MyInvocation.MyCommand.Source
$baseDirectory = Split-Path -Path $scriptName -Parent
$configName = Split-Path -Path $scriptName.Replace('.ps1', '.psd1') -Leaf

Import-LocalizedData -BaseDirectory $baseDirectory `
    -FileName $configName `
    -BindingVariable 'Config'

$env:PSModulePath += ';' + $Config.ModulePath
if (-not (Get-Module -Name 'DbVisualizer' -ListAvailable)) {
    throw 'DbVisualizer module is not in an accessible path'
}
else {
    Import-Module -Name 'DbVisualizer'
}

$targetPath = Join-Path -Path $env:APPDATA `
    -ChildPath '.dbvis\config70\dbvis.xml'

# update user's drivers
Merge-DbvPreference -Category 'Drivers' `
    -MasterPath $Config.MasterPath `
    -TargetPath $targetPath

# update user's managed databases
Merge-DbvPreference -Category 'Databases' `
    -MasterPath $Config.MasterPath `
    -TargetPath $targetPath `
    -TargetFolder $Config.TargetFolder