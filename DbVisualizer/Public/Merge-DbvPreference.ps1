<#
.SYNOPSIS
Merges the connections portion of a preferences file into the target.

.DESCRIPTION
Adds or updates connections from a master dbvis.xml file to a target dbvis.xml file.

.PARAMETER MasterPath
Path to the XML file to read connections from.

.PARAMETER TargetPath
Path to the XML file to update.

.EXAMPLE
Updates the user's DbVisualizer connections from a master file.

Merge-DbvConnection -MasterPath '\\server\FileShare\dbvis.master.xml' -TargetPath '%AppData%\.dbvis\config70\dbvis.xml'

#>
function Merge-DbvPreference {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Drivers', 'Databases', 'Folders')]
        [string[]] $Category,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ })]
        [string] $MasterPath,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ })]
        [string] $TargetPath
    )

    begin {
        $masterXml = Get-DbvXml -Path $MasterPath
        $targetXml = Get-DbvXml -Path $TargetPath
    }

    process {
        foreach ($cat in $Category) {
            switch ($cat) {
                'Drivers' {
                    $groupString = 'Drivers'
                    $singularString = 'Driver'
                    $compareProperty = 'Name'
                    $mergeLower = $false
                }
                'Databases' {
                    $groupString = 'Databases'
                    $singularString = 'Database'
                    $compareProperty = 'Alias'
                    $mergeLower = $false
                }
                'Folders' {
                    $groupString = 'Objects'
                    $singularString = 'Folder'
                    $compareProperty = 'name'
                }
            }

            foreach ($masterObject in $masterXml.DbVisualizer.$groupString.GetEnumerator()) {
                Write-Verbose "Processing $singularString $($masterObject.$compareProperty)"
                $targetObject = $targetXml |
                    Select-Xml -XPath "//$singularString[$compareProperty = '$($masterObject.$compareProperty)']" |
                    Select-Object -ExpandProperty Node

                if (-not $targetObject) {
                    $targetGroup = $targetXml |
                        Select-Xml -XPath "/DbVisualizer/$groupString" |
                        Select-Object -ExpandProperty Node

                    $targetGroup.InnerXml += $masterObject.OuterXml
                }
                else {
                    Write-Verbose "Updating $singularString $($masterObject.$compareProperty)"
                    $targetObject.InnerXml = $masterObject.InnerXml
                }
            }
        }
    }

    end {
        Save-DbvXml -Xml $targetXml -Path $TargetPath
    }
}