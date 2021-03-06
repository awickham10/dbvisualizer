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
        if ($Category -contains 'Databases' -and (-not $PSBoundParameters.ContainsKey('TargetFolder') -or $TargetFolder -eq '')) {
            throw 'When merging databases you must specify a target folder. Merging into the root folder is not supported.'
        }

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
                    $compareOperator = ''
                }
                'Databases' {
                    $groupString = 'Databases'
                    $singularString = 'Database'
                    $compareProperty = 'id'
                    $compareOperator = '@'
                    $keepProperties = @('Userid', 'Password')
                }
            }

            # add or update from master
            foreach ($masterObject in $masterXml.DbVisualizer.$groupString.GetEnumerator()) {
                Write-Verbose "Should add or update $singularString $($masterObject.$compareProperty)?"

                $xpath = "/DbVisualizer/$groupString/$singularString[$compareOperator$compareProperty = '$($masterObject.$compareProperty)']"
                Write-Verbose "Searching target XML with $xpath"
                $targetObject = $targetXml |
                    Select-Xml -XPath $xpath |
                    Select-Object -ExpandProperty Node -First 1

                # add
                if (-not $targetObject) {
                    Write-Verbose "Adding $singularString $compareProperty $($masterObject.$compareProperty)"

                    # add to main section
                    $targetGroup = $targetXml |
                        Select-Xml -XPath "/DbVisualizer/$groupString" |
                        Select-Object -ExpandProperty Node

                    $targetGroup.InnerXml += $masterObject.OuterXml
                }
                # update
                else {
                    Write-Verbose "Updating $singularString $($masterObject.$compareProperty)"

                    # save properties
                    $keep = @{}
                    foreach ($keepProperty in $keepProperties) {
                        $keep[$keepProperty] = $targetObject.$keepProperty
                    }

                    $targetObject.InnerXml = $masterObject.InnerXml

                    # replace properties
                    foreach ($keepProperty in $keepProperties) {
                        $targetObject.$keepProperty = $keep[$keepProperty]
                    }
                }
            }

            if ($Category -eq 'Databases') {
                # replace folder
                Write-Verbose "Replacing $TargetFolder folder"

                $objectsXml = $targetXml |
                    Select-Xml -XPath "/DbVisualizer/Objects" |
                    Select-Object -ExpandProperty Node

                if (-not ($objectsXml.Folder | Where-Object { $_.name -eq $TargetFolder }))
                {
                    Write-Verbose "Adding folder $TargetFolder"
                    $objectsXml.InnerXml = "<Folder name=`"$TargetFolder`"></Folder>" + $objectsXml.InnerXml
                }

                $folderXml = $targetXml |
                    Select-Xml -XPath "/DbVisualizer/Objects/Folder[@name='$TargetFolder']" |
                    Select-Object -ExpandProperty Node

                $masterFolderXml = $masterXml |
                    Select-Xml -XPath "/DbVisualizer/Objects/Folder[@name='$TargetFolder']" |
                    Select-Object -ExpandProperty Node

                $folderXml.InnerXml  = $masterFolderXml.InnerXml
            }
        }
    }

    end {
        Save-DbvXml -Xml $targetXml -Path $TargetPath
    }
}