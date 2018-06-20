<#
.SYNOPSIS
Merges the connections portion of a preferences file into the target.

.DESCRIPTION
Adds or updates connections from a master dbvis.xml file to a target dbvis.xml file.

.PARAMETER MasterPath
Path to the XML file to read connections from.

.PARAMETER TargetPath
Path to the XML file to update.

.PARAMETER TargetFolder
When merging connections, the target folder to put connections in.

.EXAMPLE
Updates the user's DbVisualizer drivers from a master file.

Merge-DbvPreference -Category 'Drivers' -MasterPath '\\server\FileShare\dbvis.master.xml' -TargetPath '%AppData%\.dbvis\config70\dbvis.xml'

.EXAMPLE
Updates the user's DbVisualizer connections from a master file.

Merge-DbvPreference -Category 'Databases' -MasterPath '\\server\FileShare\dbvis.master.xml' -TargetPath '%AppData%\.dbvis\config70\dbvis.xml' -TargetFolder 'Managed'

#>
function Merge-DbvPreference {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Drivers', 'Databases')]
        [string[]] $Category,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ })]
        [string] $MasterPath,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ })]
        [string] $TargetPath,

        [Parameter()]
        [string] $TargetFolder
    )

    begin {
        $masterXml = Get-DbvXml -Path $MasterPath
        $targetXml = Get-DbvXml -Path $TargetPath
    }

    process {
        foreach ($cat in $Category) {
            if ($cat -eq 'Databases' -and (-not $PSBoundParameters.ContainsKey('TargetFolder') -or $TargetFolder -eq '')) {
                throw 'When merging databases you must specify a target folder. Merging into the root folder is not supported.'
            }

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