function Get-DbvXml {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    process {
        $content = Get-Content -Path $Path -Raw

        if (-not $content) {
            throw "Could not read file: $Path"
        }

        [xml]$content
    }
}