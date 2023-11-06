function Sort-Reverse {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]            
        $Object
    )
    
    begin { $stack = [System.Collections.Generic.Stack[System.Object]]::new() }
    
    process { $stack.push($_) }
    
    end {
        while ($stack.Count -gt 0) {
            $stack.Pop()
        }
    }
}
