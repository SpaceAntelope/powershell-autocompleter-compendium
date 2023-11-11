
function objectify {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [hashtable]
        $dic
    )

    [PSCustomObject]$dic
}

function escape {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]
        $str
    )

    [regex]::Escape($str)
}

function isEmpty ($str) { [string]::IsNullOrWhitespace($str) }

function returnMatch ($source, $pattern) {
    [regex]::Match($source, $pattern).Value
}