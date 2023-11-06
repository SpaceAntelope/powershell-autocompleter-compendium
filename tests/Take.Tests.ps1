using namespace System.Management.Automation

Remove-Module Take -Force -ErrorAction Ignore
$module = "$PSScriptRoot/../src/Take.psm1" 

BeforeDiscovery {
    Remove-Module "$PSScriptRoot/CustomAssertions.psm1" -Force -ErrorAction Ignore
    Import-Module "$PSScriptRoot/CustomAssertions.psm1" -DisableNameChecking -Force    
}

Import-Module $module -force

InModuleScope Take {
    BeforeAll {
        . $PSScriptRoot/../src/common.ps1
        . $PSScriptRoot/common.ps1
    }

    Context "Inclusive sliceing with simple numbered arrays" {

        it "Start at 5 stop at 10" {
            
            $expected = 5..10
            $actual = 1..20 | Take -Start { $_ -eq 5 } -Stop { $_ -eq 10 } -Inclusive

            $actual |  
        }
    }
}