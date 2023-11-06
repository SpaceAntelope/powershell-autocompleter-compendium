using namespace System.Management.Automation

. $PSScriptRoot/common.ps1
. $PSScriptRoot/Take.ps1
. $PSScriptRoot/Sort-Reverse.ps1

function escape {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]
        $str
    )

    [regex]::Escape($str)
}

function parseDotnetHelp() {
    $raw = dotnet list package --help 

    $commands = $raw | Take -From { $_ -match "Commands:" } -Until { isEmpty $_ }
    $options = $raw | Take -From { $_ -match "Options:" } -Until { isEmpty $_ }

    ($options -join "`n") -split "`n\s*\-"
}

parseDotNetHelp

$dotnet_scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)

    $commandline = $commandAst.CommandElements 
    | Take-While { 
        $_.Value -notmatch "^\-" -and ($_.Value -ne $wordToComplete -or -not $wordToComplete) 
    }
    $commandline = $commandline.Value -join " "

    $help = Invoke-Expression "$commandline --help" | Take -from { $_ -match "Options:`$" }
    $help | % { write-host -f green $_ }
    dotnet complete --position $cursorPosition $commandAst.ToString() 
    | ForEach-Object {
        $helpLine = $help -match "(?(^\s+\-)$(escape $_)|\-^\s+$(escape $_))" #?.Replace($_,"")?.Trim()
        if ($helpLine) {
            write-host $helpLine
            $opts = [regex]::Match($helpline, "^\s+(\-\-?[^,\s]+(, )?)+|^\s+[^\s]+").Value.Trim()
            $rx = [regex]::new((escape $opts))
            $toolTip = $rx.Replace($helpLine, "", 1).Trim()
        }
        else {
            write-host not in help: $_
            $toolTip = $_
        }
        [CompletionResult]::new($_, $_, [CompletionResultType]::ParameterValue, $toolTip)
    }
}

Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock $dotnet_scriptblock 

