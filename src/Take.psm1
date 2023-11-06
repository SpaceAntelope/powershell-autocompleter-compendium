using namespace System.Collections.Generic


function Join {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [Object]
        $Value,
        [Parameter()]
        [string]
        $Separator = " "
    )

    begin {
        $str = [System.Text.StringBuilder]::new()
    }

    process {
        $str.Append($separator) | Out-Null
        $str.Append($_) | Out-Null
    }

    end {
        $str.ToString()
    }
}

function Take-While {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [Object]
        $Value,
        [Parameter(Mandatory, Position = 0)]
        [scriptblock]
        $Predicate
    )

    begin {
        $predicateSatisfied = $true
    }

    process {
        # write-host $predicateSatisfied $Predicate.InvokeWithContext($null, $_)
        $vars = [List[psvariable]]::new()
        $vars.Add([psvariable]::new("_", $_))
        $predicateSatisfied = $predicateSatisfied ? $Predicate.InvokeWithContext($null, $vars) : $false
        
        if ($predicateSatisfied) { $_ }
    }
}

function Take {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [Object]
        $Value,
        [Parameter()]
        [scriptblock]
        $From,
        [Parameter()]
        [scriptblock]
        $Until,
        [Parameter()]
        [switch]
        $Inclusive
    )

    begin { 
        $StartConditionMet = $false
        $StopConditionMet = $false
        
        if (-not $From) {
            $StartConditionMet = $true
        }

        if (-not $Until) {
            $Until = { $false }
        }
    }

    process {
        $vars = [List[psvariable]]::new()
        $vars.Add([psvariable]::new("_", $_))

        if ($inclusive) {
            $StartConditionMet = $StartConditionMet ? $true : $From.InvokeWithContext($null, $vars)
        }

        if (-not $inclusive) {
            $StopConditionMet = $StopConditionMet ? $true : ($Until.InvokeWithContext($null, $vars) -and $StartConditionMet)
        }
        
        if ($StartConditionMet -and -not $StopConditionMet) {
            $_
        }

        if ($inclusive) {
            $StopConditionMet = $StopConditionMet ? $true : ($Until.InvokeWithContext($null, $vars) -and $StartConditionMet)
        }

        if (-not $inclusive) {
            $StartConditionMet = $StartConditionMet ? $true : $From.InvokeWithContext($null, $vars)
        }
    }
}

# 1..15 | Take -from { $_ -eq 5 } -Until { $_ -eq 10 } -Inclusive  | Join | % { write-host -f green $_ }
# 1..15 | Take -from { $_ -eq 5 } -Until { $_ -eq 10 }  | Join | % { write-host -f blue $_ } 
# 1..15 | Take -from { $_ -eq 5 } | Join | % { write-host -f magenta $_ } 
# 1..15 | Take -from { $_ -eq 5 } -Inclusive | Join | % { write-host -f magenta $_ } 
# 1..15 | Take -Until { $_ -eq 10 }  | Join | % { write-host -f yellow $_ } 
# 1..15 | Take -Until { $_ -eq 10 } -Inclusive  | Join | % { write-host -f yellow $_ } 