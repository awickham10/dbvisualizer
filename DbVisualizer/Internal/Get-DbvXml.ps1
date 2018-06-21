function Get-DbvXml {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    process {
        $content = Get-Content -Path $Path -Raw -ErrorAction 'Stop'

        try {
            $xml = [xml]$content
        }
        catch {
            throw "Could not parse XML in '$Path'"
        }

        return $xml
    }
}