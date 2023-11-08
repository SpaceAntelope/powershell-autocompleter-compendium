function Should-HaveSameProperties {
    param(
        $ActualValue,
        $ExpectedValue,
        [switch] $Negate, 
        [string] $Because
    )
    $x = $ActualValue
    $y = $ExpectedValue
    
    function simpleDeepEquality ($x, $y) {
        $xProps = $x.GetType().GetProperties().Name ?? $x.psobject.Properties.Name
        $yProps = $y.GetType().GetProperties().Name ?? $y.psobject.Properties.Name

        if (($null -eq $x -or $null -eq $y) -and $x -ne $y) {
            $failureMessage = "one of the compared objects is null. Are you comparing arrays of different size? Non-null item is $(ConvertTo-Json ($x ?? $y))"
        }
        elseif ($x.GetType() -ne $y.GetType()) {
            $failureMessage = "Objects are of different type: [$($x.GetType())] != [$($y.GetType())]"
        }
        elseif (Compare-Object $xProps $yProps) {
            $diff = switch (Compare-Object $xProps $yProps) {
                { $_.SideIndicator -eq "=>" } { "- $($_.InputObject) property expected but not found" }
                { $_.SideIndicator -eq "<=" } { "- $($_.InputObject) found but not expected" }
            }
            
            $failureMessage = "Objects have different sets of properties:`n$diff"
        }
        else {
            $x.gettype().GetProperties().Name 
            | ForEach-Object {

                $diff = Compare-Object `
                    -ReferenceObject $x `
                    -DifferenceObject $y `
                    -Property $_
                    
                if ($diff) {                
                    $failureMessage = "Property $_ is '$($x.$_)' but was expected to be '$($y.$_)'"
                    # TO DO: Convert to recursion so we get nested objects, maybe
                }
            }            
        }

        [pscustomobject]@{
            AreEqual = -not $failureMessage
            Message  = $failureMessage
        }        
    }

    if ($null -eq $x) {
        $failureMessage = "Actual object is null. Use -BeNullOrEmpty operator instead of -HaveSameProperties."
    }
    elseif ($x -is [array] -and $x.count -ne $y.count) {
        $failureMessage = "Arrays of different size or only one item is array. Actual is $($x.count) while Expected is $($y.count)"
    }
    else {
        for ($i = 0; $i -lt $x.Count; $i++) {
            $left = $x[$i]
            $right = $y[$i]
            $result = simpleDeepEquality $left $right
            
            if (-not $result.AreEqual) {
                $failureMessage = "At index $i $($result.Message)"
                
                break;
            }
        }
    }

    [PSCustomObject]@{
        Succeeded      = $Negate ? [bool]$failureMessage : -not $failureMessage
        FailureMessage = $failureMessage -and $Because ? "$failureMessage because $because" : $failureMessage
    }
}

function Should-HaveSameMembersInSameOrder {
    param(
        $ActualValue,
        [array]$ExpectedValue,
        [switch] $Negate, 
        [string] $Because
    )

    if ($ActualValue.Count -ne $ExpectedValue.Count) {
        $failureMessage = "Arrays have different lengths, expected count to be $($ExpectedValue.Count) but got $($ActualValue.Count)"
    }
    else {
        for ($i = 0; $i -lt $ActualValue.Count; $i++) {
            $actual = $ActualValue[$i]
            $expected = $ExpectedValue[$i]

            if ($actual -ne $expected) {
                $failureMessage = "At index $i element was expected to be $expected but was $actual"
                break;
            }
        }
    }

    [PSCustomObject]@{
        Succeeded      = $Negate ? [bool]$failureMessage : -not $failureMessage
        FailureMessage = $failureMessage -and $Because ? "$failureMessage because $because" : $failureMessage
    }
}
# }

# try {
#     Get-ShouldOperator HaveSameProperties
# }
# catch {

Add-ShouldOperator -Name HaveSameProperties  `
    -Alias EQV `
    -InternalName 'Should-HaveSameProperties' `
    -Test ${function:Should-HaveSameProperties} `
    -SupportsArrayInput

Add-ShouldOperator -Name Should-HaveSameMembersInSameOrder  `
    -Alias BeEqualArray `
    -InternalName 'Should-HaveSameMembersInSameOrder' `
    -Test ${function:Should-HaveSameMembersInSameOrder} `
    -SupportsArrayInput
    
# }