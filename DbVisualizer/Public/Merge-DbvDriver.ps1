<#
.SYNOPSIS
Merges the drivers portion of a preferences file into the target.

.DESCRIPTION
Adds or updates drivers from a master dbvis.xml file to a target dbvis.xml file.

.PARAMETER MasterPath
Path to the XML file to read drivers from.

.PARAMETER TargetPath
Path to the XML file to update.

.EXAMPLE
Updates the user's DbVisualizer driver from a master file.

Merge-DbvDriver -MasterPath '\\server\FileShare\dbvis.master.xml' -TargetPath '%AppData%\.dbvis\config70\dbvis.xml'

#>
function Merge-DbvDriver {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ })]
        $MasterPath,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ })]
        $TargetPath
    )

    process {
        $masterXml = Get-DbvXml -Path $MasterPath
        $targetXml = Get-DbvXml -Path $TargetPath

        foreach ($masterDriver in $masterXml.DbVisualizer.Drivers.GetEnumerator()) {
            Write-Verbose "Processing Driver $($masterDriver.Name)"
            $targetDriver = $targetXml |
                Select-Xml -XPath "//Driver[Name = '$($masterDriver.Name)']" |
                Select-Object -ExpandProperty Node

            # add driver
            if (-not $targetDriver) {
                $targetDrivers = $targetXml |
                    Select-Xml -XPath '/DbVisualizer/Drivers' |
                    Select-Object -ExpandProperty Node

                $targetDrivers.InnerXml += $masterDriver.OuterXml
            }
            # update driver
            else {
                Write-Verbose "Updating driver $($masterDriver.Name)"
                $targetDriver.InnerXml = $masterDriver.InnerXml
            }
        }

        Save-DbvXml -Xml $targetXml -Path $TargetPath
    }
}