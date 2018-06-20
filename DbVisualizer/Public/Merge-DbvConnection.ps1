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
function Merge-DbvConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ })]
        $MasterPath,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ })]
        $TargetPath,

        [Parameter()]
        $Folder
    )

    process {
        $masterXml = Get-DbvXml -Path $MasterPath
        $targetXml = Get-DbvXml -Path $TargetPath

        foreach ($masterDatabase in $masterXml.DbVisualizer.Databases.GetEnumerator()) {
            Write-Verbose "Processing Database $($masterDatabase.Alias)"
            $targetDatabase = $targetXml |
                Select-Xml -XPath "//Database[Alias = '$($masterDatabase.Alias)']" |
                Select-Object -ExpandProperty Node

            # add connection
            if (-not $targetDatabase) {
                $targetDatabases = $targetXml |
                    Select-Xml -XPath '/DbVisualizer/Databases' |
                    Select-Object -ExpandProperty Node

                $targetDatabases.InnerXml += $masterDatabase.OuterXml
            }
            # update driver
            else {
                Write-Verbose "Updating database $($masterDatabase.Alias)"
                $targetDatabase.InnerXml = $masterDatabase.InnerXml
            }
        }

        Save-DbvXml -Xml $targetXml -Path $TargetPath
    }
}