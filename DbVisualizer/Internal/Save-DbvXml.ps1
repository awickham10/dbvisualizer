function Save-DbvXml {
    [CmdletBinding()]
    param (
        [System.Xml.XmlDocument] $Xml,
        [string] $Path
    )

    process {
        try {
            $Xml.Save($Path)
        }
        catch {
            throw "Could not save to path '$Path'."
        }
    }
}