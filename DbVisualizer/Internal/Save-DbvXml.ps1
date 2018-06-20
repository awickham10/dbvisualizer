function Save-DbvXml {
    [CmdletBinding()]
    param (
        [System.Xml.XmlDocument] $Xml,
        [string] $Path
    )

    process {
        $Xml.Save($Path)
    }
}