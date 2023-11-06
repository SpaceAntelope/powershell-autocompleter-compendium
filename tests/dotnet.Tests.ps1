using namespace System.Management.Automation


Remove-Module dotnet -Force -ErrorAction Ignore
$module = "$PSScriptRoot/../src/dotnet.psm1" 

BeforeDiscovery {
    Remove-Module "$PSScriptRoot/CustomAssertions.psm1" -Force -ErrorAction Ignore
    Import-Module "$PSScriptRoot/CustomAssertions.psm1" -DisableNameChecking -Force    
}

Import-Module $module -force

InModuleScope dotnet {
    Describe "completion should return helptext as tooltip" {

        BeforeAll {
            . $PSScriptRoot/../src/common.ps1
            . $PSScriptRoot/common.ps1
        }

        Context "no partial word" {
            it "[dotnet list] -> list options with tooltip" {
                $expected = @(
                    (CompletionResult "--help" "Show command line help."),
                    (CompletionResult "-?" "Show command line help."),
                    (CompletionResult "-h" "Show command line help."),
                    (CompletionResult "/?" "/?"),
                    (CompletionResult "/h" "/h"),
                    (CompletionResult "package" "List all package references of the project or solution."),
                    (CompletionResult "reference" "List all project-to-project references of the project.")
                )
            
                $cmd = mockCommandAst @("dotnet", "list")
                $wtc = ""
                $actual = & $dotnet_scriptblock $wtc $cmd 12
            
                $actual | Should -HaveSameProperties $expected
            }
        }
    }
}