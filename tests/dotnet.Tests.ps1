using namespace System.Management.Automation


Remove-Module dotnet -Force -ErrorAction Ignore
$module = "$PSScriptRoot/../src/dotnet.psm1" 

BeforeDiscovery {
  Remove-Module "$PSScriptRoot/CustomAssertions.psm1" -Force -ErrorAction Ignore
  if (-not (Get-Module CustomAssertions)) {
    Import-Module "$PSScriptRoot/CustomAssertions.psm1" -DisableNameChecking -Force    
  }
}

Import-Module $module -force

InModuleScope dotnet {

  Describe "Internal text -> structured output" {
    BeforeAll {
      . $PSScriptRoot/../src/common.ps1
      . $PSScriptRoot/common.ps1

      filter objectify { [pscustomobject]$_ }

      $dotnet_list = @"
Description:
  List references or packages of a .NET project.
                                                                                                                                                                                                                                                                                    
Usage:                                                                                                                                                                                                                                                                    
  dotnet list [<PROJECT | SOLUTION>] [command] [options]                                                                                                                                                                                                                  
                                                                                                                                                                                                                                                                        
Arguments:                                                                                                                                                                                                                                                                
  <PROJECT | SOLUTION>  The project or solution file to operate on. If a file is not specified, the command will search the current directory for one. [default: C:\Users\cernu\source\powershell-autocompleter-compendium\]                                              
                                                                                                                                                                                                                                                                        
Options:
  -?, -h, --help  Show command line help.


Commands:
  package    List all package references of the project or solution.
  reference  List all project-to-project references of the project.
"@ -split "`r?`n"

      $dotnet_list_package = @"
Description:
List all package references of the project or solution.

Usage:
  dotnet list [<PROJECT | SOLUTION>] package [options]

Arguments:
  <PROJECT | SOLUTION>  The project or solution file to operate on. If a file is not specified, the command will search
                        the current directory for one. [default: C:\Users\cernu\]

Options:
  -v, --verbosity <LEVEL>                  Set the MSBuild verbosity level. Allowed values are q[uiet], m[inimal],
                                              n[ormal], d[etailed], and diag[nostic].
  --outdated                               Lists packages that have newer versions. Cannot be combined with
                                              '--deprecated' or '--vulnerable' options.
  --deprecated                             Lists packages that have been deprecated. Cannot be combined with
                                              '--vulnerable' or '--outdated' options.
  --vulnerable                             Lists packages that have known vulnerabilities. Cannot be combined with
                                              '--deprecated' or '--outdated' options.
  --framework <FRAMEWORK | FRAMEWORK\RID>  Chooses a framework to show its packages. Use the option multiple times for
                                              multiple frameworks.
  --include-transitive                     Lists transitive and top-level packages.
  --include-prerelease                     Consider packages with prerelease versions when searching for newer
                                              packages. Requires the '--outdated' option.
  --highest-patch                          Consider only the packages with a matching major and minor version numbers
                                              when searching for newer packages. Requires the '--outdated' option.
  --highest-minor                          Consider only the packages with a matching major version number when
                                              searching for newer packages. Requires the '--outdated' option.
  --config <CONFIG_FILE>                   The path to the NuGet config file to use. Requires the '--outdated',
                                              '--deprecated' or '--vulnerable' option.
  --source <SOURCE>                        The NuGet sources to use when searching for newer packages. Requires the
                                              '--outdated', '--deprecated' or '--vulnerable' option.
  --interactive                            Allows the command to stop and wait for user input or action (for example to
                                              complete authentication).
  --format <console|json>                  Specifies the output format type for the list packages command.
  --output-version <output-version>        Specifies the version of machine-readable output. Requires the '--format
                                              json' option.
  -?, -h, --help                           Show command line help.
"@ -split "`r?`n"

      $dotnet_help = @"
Usage: dotnet [runtime-options] [path-to-application] [arguments]

Execute a .NET application.

runtime-options:
  --additionalprobingpath <path>   Path containing probing policy and assemblies to probe for.
  --additional-deps <path>         Path to additional deps.json file.
  --depsfile                       Path to <application>.deps.json file.
  --fx-version <version>           Version of the installed Shared Framework to use to run the application.
  --roll-forward <setting>         Roll forward to framework version  (LatestPatch, Minor, LatestMinor, Major, LatestMajor, Disable).
  --runtimeconfig                  Path to <application>.runtimeconfig.json file.

path-to-application:
  The path to an application .dll file to execute.

Usage: dotnet [sdk-options] [command] [command-options] [arguments]

Execute a .NET SDK command.

sdk-options:
  -d|--diagnostics  Enable diagnostic output.
  -h|--help         Show command line help.
  --info            Display .NET information.
  --list-runtimes   Display the installed runtimes.
  --list-sdks       Display the installed SDKs.
  --version         Display .NET SDK version in use.

SDK commands:
  add               Add a package or reference to a .NET project.
  build             Build a .NET project.
  build-server      Interact with servers started by a build.
  clean             Clean build outputs of a .NET project.
  format            Apply style preferences to a project or solution.
  help              Show command line help.
  list              List project references of a .NET project.
  msbuild           Run Microsoft Build Engine (MSBuild) commands.
  new               Create a new .NET project or file.
  nuget             Provides additional NuGet commands.
  pack              Create a NuGet package.
  publish           Publish a .NET project for deployment.
  remove            Remove a package or reference from a .NET project.
  restore           Restore dependencies specified in a .NET project.
  run               Build and run a .NET project output.
  sdk               Manage .NET SDK installation.
  sln               Modify Visual Studio solution files.
  store             Store the specified assemblies in the runtime package store.
  test              Run unit tests using the test runner specified in a .NET project.
  tool              Install or manage tools that extend the .NET experience.
  vstest            Run Microsoft Test Engine (VSTest) commands.
  workload          Manage optional workloads.

Additional commands from bundled tools:
  dev-certs         Create and manage development certificates.
  fsi               Start F# Interactive / execute F# scripts.
  user-jwts         Manage JSON Web Tokens in development.
  user-secrets      Manage development user secrets.
  watch             Start a file watcher that runs a command when files change.

Run 'dotnet [command] --help' for more information on a command.
"@ -split "`r?`n"
    }

    Context "Parse dotnet list --help" {
      it "return options with help text" {
        $expected = @(
          @{ Name = "-?"; HelpText = "Show command line help."; Args = $null },
          @{ Name = "-h"; HelpText = "Show command line help."; Args = $null },
          @{ Name = "--help"; HelpText = "Show command line help." ; Args = $null }
        ) | objectify

        $actual = ExctractParseables $dotnet_list
        | Where-Object Kind -eq Options 
        | ForEach-Object Text
        | ForEach-Object { ParseOption $_ }

        $actual | Should -HaveSameProperties $expected
      }

      it "return commands with help text" {
        $expected = @(
          @{ Name = "package"; HelpText = "List all package references of the project or solution." }
          @{ Name = "reference"; HelpText = "List all project-to-project references of the project." }
        ) | objectify

        $actual = ExctractParseables $dotnet_list 
        | Where-Object Kind -eq Commands 
        | ForEach-Object Text
        | ForEach-Object { ParseCommand $_ }
 
        $actual | Should -HaveSameProperties $expected
      }
    }

    Context "Parse dotnet list package --help" {
      it "return options with help text" {
        $expected = @(
          @{ Name = "-v"; HelpText = "Set the MSBuild verbosity level. Allowed values are q[uiet], m[inimal], n[ormal], d[etailed], and diag[nostic]."; Args = "<LEVEL>" },
          @{ Name = "--verbosity"; HelpText = "Set the MSBuild verbosity level. Allowed values are q[uiet], m[inimal], n[ormal], d[etailed], and diag[nostic]."; Args = "<LEVEL>" },
          @{ Name = "--outdated"; HelpText = "Lists packages that have newer versions. Cannot be combined with '--deprecated' or '--vulnerable' options."; Args = $null },
          @{ Name = "--deprecated"; HelpText = "Lists packages that have been deprecated. Cannot be combined with '--vulnerable' or '--outdated' options."; Args = $null },
          @{ Name = "--vulnerable"; HelpText = "Lists packages that have known vulnerabilities. Cannot be combined with '--deprecated' or '--outdated' options."; Args = $null },
          @{ Name = "--framework <FRAMEWORK | FRAMEWORK\RID>"; HelpText = "Chooses a framework to show its packages. Use the option multiple times for multiple frameworks."; Args = "<FRAMEWORK | FRAMEWORK\RID>" },
          @{ Name = "--include-transitive"; HelpText = "Lists transitive and top-level packages." ; Args = $null },
          @{ Name = "--include-prerelease"; HelpText = "Consider packages with prerelease versions when searching for newer packages. Requires the '--outdated' option." ; Args = $null },
          @{ Name = "--highest-patch"; HelpText = "Consider only the packages with a matching major and minor version numbers when searching for newer packages. Requires the '--outdated' option." ; Args = $null },
          @{ Name = "--highest-minor"; HelpText = "Consider only the packages with a matching major version number when searching for newer packages. Requires the '--outdated' option." ; Args = $null },
          @{ Name = "--config <CONFIG_FILE>"; HelpText = "The path to the NuGet config file to use. Requires the '--outdated', '--deprecated' or '--vulnerable' option."; Args = "<CONFIG_FILE>" },
          @{ Name = "--source <SOURCE>"; HelpText = "The NuGet sources to use when searching for newer packages. Requires the '--outdated', '--deprecated' or '--vulnerable' option."; Args = "<SOURCE>" },
          @{ Name = "--interactive"; HelpText = "Allows the command to stop and wait for user input or action (for example to complete authentication)." ; Args = $null },
          @{ Name = "--format <console|json>"; HelpText = "Specifies the output format type for the list packages command." ; Args = "<console|json>" },
          @{ Name = "--output-version <output-version>"; HelpText = "Specifies the version of machine-readable output. Requires the '--format json' option." ; Args = $null },
          @{ Name = "-?"; HelpText = "Show command line help."; Args = $null }
          @{ Name = "-h"; HelpText = "Show command line help."; Args = $null }
          @{ Name = "--help"; HelpText = "Show command line help."; Args = $null }
        ) | objectify

        $actual = ExctractParseables $dotnet_list_package 
        | Where-Object Kind -eq Options 
        | ForEach-Object Text
        | ForEach-Object { ParseOption $_ }
                
        $actual | Should -HaveSameProperties $expected
      }

      it "return commands with help text" {
        $expected = @(
          @{ Name = "package"; HelpText = "List all package references of the project or solution." }
          @{ Name = "reference"; HelpText = "List all project-to-project references of the project." }
        ) | objectify

        $actual = ExctractParseables $dotnet_list 
        | Where-Object Kind -eq Commands
        | ForEach-Object Text
        | ForEach-Object { ParseCommand $_ }
 
        $actual | Should -HaveSameProperties $expected
      }
    }

    Context "Parse dotnet --help (multiple options and command segments)" {
      it "Parse all options" {

      }
    }
  }


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