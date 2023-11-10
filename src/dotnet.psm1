using namespace System.Management.Automation


. $PSScriptRoot/common.ps1
# . $PSScriptRoot/Sort-Reverse.ps1
remove-module $PSScriptRoot/Take.psm1 -force -ErrorAction Ignore
import-module $PSScriptRoot/Take.psm1

function returnMatch ($source, $pattern) {
    [regex]::Match($source, $pattern).Value
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
filter cleanup { $_.Trim() -replace "\s{2,}", " " } 

function ExctractParseables($raw) {
    $raw -match "(?<=commands|options).*:" | ForEach-Object { 
        $kind = $_

        $parseable = $raw | Take -from { $_ -eq $kind } -Until { isEmpty $_ } #| cleanup
       
        [PSCustomObject]@{
            Kind = $kind.Trim(" :")
            Text = ($parseable -join "`n") -split "`n  (?=[\w\-])"
        }
    }
    # $commands = $raw | Take -From { $_ -match "Commands:" } -Until { isEmpty $_ }
    # $options = $raw | Take -From { $_ -match "Options:" } -Until { isEmpty $_ } 

    # [PSCustomObject]@{
    #     Commands = $commands | cleanup
    #     Options  = ($options -join "`n") -split "`n\s*(?=\-)" | cleanup
    # }
}

function ParseOption([string]$line) {
    $options = returnMatch $line.Trim() "^(\-\-?[^,\s]+(,\s*)?)+" | cleanup
    $_args = returnMatch $line.Trim() "<[^>]+>`$"
    $helpText = ($line -replace "^$(escape $options)") | cleanup

    $options -split ",\s*" 
    | ForEach-Object { 
        [pscustomobject]@{
            Name     = $_;
            Args     = $_args
            HelpText = $helpText 
        }
    }
}

function ParseCommand([string]$line) {
    $cmd = returnMatch $line.Trim() "^[^\s]+"
    $helpText = ($line -replace "^$(escape $cmd)") | cleanup

    [pscustomobject]@{
        Name     = $cmd;
        HelpText = $helpText 
    }
}

$dotnet_scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)

    $commandline = $commandAst.CommandElements 
    | Take-While { $_.Value -notmatch "^\-" -and ($_.Value -ne $wordToComplete -or -not $wordToComplete) }

    $commandline = $commandline.Value -join " "

    $help = Invoke-Expression "$commandline --help"
    # $help | ForEach-Object { write-host -f green $_ }

    $index = ExctractParseables $help | ForEach-Object { $result = @{} } {
        $helpLine = switch ($_) {
            { $_.Kind -match "command" } { ParseCommand $_.Text }
            { $_.Kind -match "option" } { ParseOption $_.Text }
        }
        $helpLine | ForEach-Object { $result[$_.Name] = $_ }
        # $_.Commands | ForEach-Object { ParseCommand $_ } | ForEach-Object { $result[$_.Name] = $_ }
        # $_.Options | ForEach-Object { ParseOption $_ } | ForEach-Object { $result[$_.Name] = $_ }
    } { $result }

    dotnet complete --position $cursorPosition $commandAst.ToString() 
    | ForEach-Object { 
        $helpLine = $index[$_]
        
        # _] $help -match "(?(^\s+\-)$(escape $_)|\-^\s+$(escape $_))" #?.Replace($_,"")?.Trim()
        # if ($helpLine) {
        #     write-host $helpLine
        #     $opts = [regex]::Match($helpline, "^\s+(\-\-?[^,\s]+(, )?)+|^\s+[^\s]+").Value.Trim()
        #     $rx = [regex]::new((escape $opts))
        #     $toolTip = $rx.Replace($helpLine, "", 1).Trim()
        # }
        # else {
        #     write-host not in help: $_
        #     $toolTip = $_
        # }
        if ($helpline) {
            [CompletionResult]::new($helpLine.Name, "$($helpLine.Name) $($helpLine.Args)".Trim(), [CompletionResultType]::ParameterValue, $helpLine.HelpText)
        }
        else {
            [CompletionResult]::new($_, $_, [CompletionResultType]::ParameterValue, $_)
        }
    }
}

Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock $dotnet_scriptblock 

