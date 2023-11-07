using namespace System.Management.Automation

# Import-Module pester -MinimumVersion 5.5.0
Remove-Module "$PSScriptRoot/CustomAssertions.psm1" -Force -ErrorAction Ignore
Import-Module "$PSScriptRoot/CustomAssertions.psm1" -DisableNameChecking -Force    

Remove-Module Take -Force -ErrorAction Ignore
$module = "$PSScriptRoot/../src/Take.psm1" 

Import-Module $module -force

InModuleScope Take {

    BeforeDiscovery {        
     
        $simpleTestCases = @(
            @{  
                Case = "Slice inclusive"; Source = 1..15; Result = 5..10; 
                TakeArgs = @{ From = { $_ -eq 5 }; Until = { $_ -eq 10 }; Inclusive = $true } 
            },
            @{ 
                Case = "Slice exclusive"; Source = 1..15; Result = 6..9; 
                TakeArgs = @{ From = { $_ -eq 5 }; Until = { $_ -eq 10 } } 
            },
            @{ 
                Case = "Slice until end (no terminal condition), inclusive"; Source = 1..15; Result = 5..15; 
                TakeArgs = @{ From = { $_ -eq 5 }; Inclusive = $true } 
            },
            @{ 
                Case = "Slice until end (no terminal condition), exclusive"; Source = 1..15; Result = 6..15; 
                TakeArgs = @{ From = { $_ -eq 5 }; } 
            },
            @{ 
                Case = "Slice from start until terminal, inclusive"; Source = 1..15; Result = 1..5; 
                TakeArgs = @{ Until = { $_ -eq 5 }; Inclusive = $true } 
            },
            @{ 
                Case = "Slice from start until terminal, exclusive"; Source = 1..15; Result = 1..4; 
                TakeArgs = @{ Until = { $_ -eq 5 }; } 
            },
            @{ 
                Case = "Slice unconditionally, inclusive"; Source = 1..15; Result = 1..15; 
                TakeArgs = @{ Inclusive = $true } 
            },
            @{ 
                Case = "Slice unconditionally, exclusive"; Source = 1..15; Result = 1..15; 
                TakeArgs = @{  } 
            },
            @{ 
                Case = "Ignore terminal condition if it happens before starting, exclusive"; Source = 1..15; Result = 11..15; 
                TakeArgs = @{ From = { $_ -eq 10 }; Until = { $_ -eq 5 } } 
            },
            @{ 
                Case = "Ignore terminal condition if it happens before starting, inclusive"; Source = 1..15; Result = 10..15; 
                TakeArgs = @{ From = { $_ -eq 10 }; Until = { $_ -eq 5 }; Inclusive = $true } 
            }
            @{ 
                Case = "If terminal condition occurs several times, only the first after starting condition counts, exclusive"; 
                Source = @(1, 5, 1, 5, 2, 3, 4, 5, 6, 1, 5, 10, 15); Result = @(3, 4); 
                TakeArgs = @{ From = { $_ -eq 2 }; Until = { $_ -eq 5 } } 
            },
            @{ 
                Case = "If terminal condition occurs several times, only the first after starting condition counts, inclusive"; 
                Source = @(1, 5, 1, 5, 2, 3, 4, 5, 6, 1, 5, 10, 15); Result = @(2, 3, 4, 5); 
                TakeArgs = @{ From = { $_ -eq 2 }; Until = { $_ -eq 5 }; Inclusive = $true } 
            },
            @{ 
                Case = "If starting condition occurs several times, only the first one counts, exclusive"; 
                Source = @(1, 5, 1, 5, 2, 3, 4, 5, 6, 1, 5, 10, 15); Result = @(1, 5); 
                TakeArgs = @{ From = { $_ -eq 5 }; Until = { $_ -eq 2 } } 
            },
            @{ 
                Case = "If starting condition occurs several times, only the first counts, inclusive"; 
                Source = @(1, 5, 1, 5, 2, 3, 4, 5, 6, 1, 5, 10, 15); Result = @(5, 1, 5, 2); 
                TakeArgs = @{ From = { $_ -eq 5 }; Until = { $_ -eq 2 }; Inclusive = $true } 
            },
            @{ 
                Case = "If starting condition is same as terminal, terminal only counts if it occurs again after starting condition, exclusive"; 
                Source = @(1, 5, 1, 5, 2, 3, 4, 5, 6, 1, 5, 10, 15); Result = @(1); 
                TakeArgs = @{ From = { $_ -eq 5 }; Until = { $_ -eq 5 } } 
            },
            @{ 
                Case = "If starting condition is same as terminal, terminal only counts if it occurs again after starting condition, inclusive"; 
                Source = @(1, 5, 1, 5, 2, 3, 4, 5, 6, 1, 5, 10, 15); Result = @(5, 1, 5); 
                TakeArgs = @{ From = { $_ -eq 5 }; Until = { $_ -eq 5 }; Inclusive = $true } 
            },
            @{ 
                Case = "Consequent terminal and starting conditions return empty if exclusive"; 
                Source = @(1, 5, 1, 5, 2, 3, 4, 5, 6, 1, 5, 10, 15); Result = @(); 
                TakeArgs = @{ From = { $_ -eq 3 }; Until = { $_ -eq 4 } } 
            },
            @{ 
                Case = "Consequent terminal and starting conditions return start and stop values if inclusive"; 
                Source = @(1, 5, 1, 5, 2, 3, 4, 5, 6, 1, 5, 10, 15); Result = @(3, 4); 
                TakeArgs = @{ From = { $_ -eq 3 }; Until = { $_ -eq 4 }; Inclusive = $true } 
            }
        )
    }
    
    BeforeAll {
        . $PSScriptRoot/../src/common.ps1
        . $PSScriptRoot/common.ps1
    }

    Context "Simple tests with arrays of primitives" {

        it "<Case>" -ForEach $simpleTestCases {
            $expected = $Result
            $actual = $Source | Take @TakeArgs 

            $actual | Should -BeEqualArray $expected
        }
    }
}