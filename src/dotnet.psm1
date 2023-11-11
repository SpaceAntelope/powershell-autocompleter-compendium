using namespace System.Management.Automation


. $PSScriptRoot/common.ps1
# . $PSScriptRoot/Sort-Reverse.ps1
remove-module $PSScriptRoot/Take.psm1 -force -ErrorAction Ignore
import-module $PSScriptRoot/Take.psm1


filter cleanup { $_.Trim() -replace "\s{2,}", " " } 

function ExctractParseables($raw) {
    $raw -match "(?<=commands|options).*:" | ForEach-Object { 
        $kind = $_

        $parseable = $raw | Take -from { $_ -eq $kind } -Until { isEmpty $_ } #| cleanup
       
        [PSCustomObject]@{
            Kind = $kind.Trim(" :")
            Text = ($parseable -join "`n") -split "`n\s{2}(?=[\w\-])"
        }
    }
}

function ParseOption([string]$line) {
    $options = returnMatch $line.Trim() "^(\-\-?[^,\s\|]+(,\s*|\|)?)+" | cleanup
    $_args = returnMatch $line.Trim() "<[^>]+>`$"
    $helpText = ($line -replace "^\s*$(escape $options)") | cleanup

    $options -split ",\s*|\|" 
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
    $helpText = ($line -replace "^\s*$(escape $cmd)") | cleanup

    [pscustomobject]@{
        Name     = $cmd;
        HelpText = $helpText 
    }
}

$dotnet_scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)

    $commandline = $commandAst.CommandElements 
    | Take -Until { -not(  $_.Value -notmatch "^\-" -and ($_.Value -ne $wordToComplete -or -not $wordToComplete)) }

    $commandline = $commandline.Value -join " "

    $help = Invoke-Expression "$commandline --help"

    $index = ExctractParseables $help | ForEach-Object { $result = @{} } {
        $helpLine = switch ($_) {
            { $_.Kind -match "command" } { $_.Text | ForEach-Object { ParseCommand $_ } }
            { $_.Kind -match "option" } { $_.Text | ForEach-Object { ParseOption $_ } }
        }
        
        $helpLine | ForEach-Object { $result[$_.Name] = $_ }
        
    } { $result }

    dotnet complete --position $cursorPosition $commandAst.ToString() 
    | ForEach-Object { 
        $helpLine = $index[$_]
        
        if ($helpline) {
            [CompletionResult]::new($helpLine.Name, "$($helpLine.Name) $($helpLine.Args)".Trim(), [CompletionResultType]::ParameterValue, $helpLine.HelpText)
        }
        else {
            [CompletionResult]::new($_, $_, [CompletionResultType]::ParameterValue, $_)
        }
    }
}

Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock $dotnet_scriptblock 

