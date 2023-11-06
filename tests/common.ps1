using namespace System.Management.Automation

        
function mockCommandAst ($elements) {
    @{ CommandElements = $elements | ForEach-Object { @{ Value = $_ }  | objectify } } | objectify
    | Add-Member -MemberType ScriptMethod -Name "ToString" -Value { 
        $this.CommandElements.Value -join " " 
    } -Force -PassThru
}
        
function completionResult($name, $helpText) { 
    [CompletionResult]::new($name, $name, [CompletionResultType]::ParameterValue, $HelpText) 
}