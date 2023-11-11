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
        [scriptblock]
        $While,
        [Parameter()]
        [switch]
        $Inclusive
    )

    begin { 
        $StartConditionMet = $false
        $StopConditionMet = $false
        $StartConditionAge = 0
        
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

        if ($StartConditionMet) {
            $StartConditionAge++
        }
       
        if ($inclusive -and -not $StartConditionMet) {
            <# After condition met, don't run From() again #>
            $StartConditionMet = $From.InvokeWithContext($null, $vars)
        }

        if (-not $inclusive -and $StartConditionMet -and -not $StopConditionMet -and $StartConditionAge -gt 0) {
            <# Age > 0 prevents terminal condition from being set immediately if it is the same as the start condition #>
            $StopConditionMet = $Until.InvokeWithContext($null, $vars)
        }
        
        if ($StartConditionMet -and -not $StopConditionMet) {
            $_
        }

        if ($inclusive -and $StartConditionMet -and -not $StopConditionMet -and $StartConditionAge -gt 0) {
            $StopConditionMet = $Until.InvokeWithContext($null, $vars)
        }

        if (-not $inclusive -and -not $StartConditionMet) {
            $StartConditionMet = $From.InvokeWithContext($null, $vars)
        }
    }
}
