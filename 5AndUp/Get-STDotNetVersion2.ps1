#requires -version 3
function Get-STDotNetVersion2 {
    <#
    .SYNOPSIS
        Get .NET versions parsed from the "dotnet.exe --list-runtimes" and
        "dotnet.exe --list-sdks" output, as invoked via PSRemoting/WinRM.

        This is for .NET 5 and above. For retrieving .NET Framework versions,
        see https://github.com/EliteLoser/DotNetVersionLister (versions 1-4.x).

        Author: Joakim Borger Svendsen, Svendsen Tech.

        MIT License.

        2023-05-24. Disclaimer: This was written in less than two hours and tested
        against only a couple of computers. But should mostly work. You are welcome
        to provide feedback or suggest changes on GitHub.

        See https://github.com/EliteLoser/DotNetVersionLister

    .PARAMETER ComputerName
        Computer names to scan for .NET 5+ versions.
    .PARAMETER Credential
        Alternate credentials for the PSRemoting.
    .PARAMETER DotNetExePath
        Custom dotnet.exe path. Default: 'C:\Program Files\dotnet\dotnet.exe'.
    .PARAMETER NoFallbackToSearchForDotNetExePath
        Do not fall back to searching for dotnet.exe if it is not found in the
        default location (customizable with -DotNetExePath). Default drives to
        search are C: and D:. Use -DotNetExeFallbackSearchDrives X:, Y:, Z:
        to specify your own drives.
    .PARAMETER DotNetExeFallbackSearchDrives
        Drives to search for dotnet.exe if it is not found in the standard location
        (customizable with -DotNetExePath). Default is C:, D:. It will stop as soon
        as one is found.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('Cn', 'PSComputerName', 'Name')]
        [String[]]$ComputerName,
        [PSCredential]$Credential,
        [String]$DotNetExePath = 'C:\Program Files\dotnet\dotnet.exe',
        [Switch]$NoFallbackToSearchForDotNetExePath,
        [String[]]$DotNetExeFallbackSearchDrives = @('C:', 'D:')
    )

    Begin {
        $InnerComputerName = @()
    }
    Process {
        # I want all of the computers collected for one call to Invoke-Command rather
        # than multiple, so therefore, if people pipe in computer names,
        # I collect them in an array and run the code in the end block.
        # The Process{} block's "$ComputerName" will be one single string/object
        # for each pipeline element, or if they are passed as an argument, it will
        # simply append the (possibly one-element) array to the (then empty) inner array.
        $InnerComputerName += $ComputerName
    }

    End {
        $ScriptBlock = {
            Param(
                [String]$DotNetExePath,
                [Bool]$NoFallbackToSearchForDotNetExePath,
                [String[]]$SearchDrives
            )
            $ErrorActionPreference = 'Stop'
            if (-not (Test-Path -LiteralPath $DotNetExePath)) {
                if ($True -eq $NoFallbackToSearchForDotNetExePath) {
                    Write-Error ("[$Env:ComputerName] Did not find dotnet.exe in path '$DotNetExePath'. " + `
                        "Consider omitting -NoFallbackToSearchForDotNetExePath and possibly using " + `
                        "-DotNetExeFallbackSearchDrives (default is C: and D:, and it stops when one is found)") `
                        -ErrorAction Stop
                }
                else {
                    Write-Verbose -Verbose ("Did not find dotnet.exe in path '$DotNetExePath'. " + `
                        "Falling back to searching through drives $($SearchDrives -join ', ')")
                    foreach ($Drive in $SearchDrives) {
                        $DotNetExePath = Get-ChildItem -LiteralPath "$Drive\dotnet.exe" -Recurse -Force -ErrorAction SilentlyContinue |
                            Select-Object -ExpandProperty FullName -First 1 -ErrorAction SilentlyContinue
                        if (Test-Path -LiteralPath $DotNetExePath) {
                            Write-Verbose -Verbose "Found dotnet.exe in path '$DotNetExePath'."
                            break
                        }
                    }
                    if (-not (Test-Path -LiteralPath $DotNetExePath)) {
                        Write-Error "Searched, but did not find dotnet.exe in any of the following drives $($SearchDrives -join ', ')" -ErrorAction Stop
                    }
                }
            }
            # SDK section.
            try {
                foreach ($SDK in & $DotNetExePath --list-sdks) {
                    if ($SDK -match '^(?<Version>[\d.]+)\s+\[(?<Path>.+)\]\s*$') {
                        # Not [PSCustomObject] for PSv2 compatibility...
                        New-Object -TypeName PSObject -Property @{
                            ComputerName = $Env:ComputerName
                            SDKVersion = $Matches['Version']
                            SDKPath = $Matches['Path']
                        } | Select-Object -Property ComputerName, SDKVersion, SDKPath, RuntimeType, RuntimeVersion, RuntimePath
                        # The Select-Object above is for PSv2 quirks mode to include all properties for all objects.
                    }
                    else {
                        Write-Warning "[$Env:ComputerName] Unrecognized output from 'dotnet.exe --list-sdks'. Output was '$SDK'."
                    }
                }
            
            }
            catch {
                Write-Warning "[$Env:ComputerName] Failed to execute 'dotnet.exe --list-sdks'. Error was '$_'"
            }
            # Runtime section.
            try {
                foreach ($Runtime in & $DotNetExePath --list-runtimes) {
                    if ($Runtime -match '^(?<RuntimeType>\S+)\s+(?<Version>[\d.]+)\s+\[(?<Path>.+)\]\s*$') {
                        # Not [PSCustomObject] for PSv2 compatibility...
                        New-Object -TypeName PSObject -Property @{
                            ComputerName = $Env:ComputerName
                            RuntimeType = $Matches['RuntimeType']
                            RuntimeVersion = $Matches['Version']
                            RuntimePath = $Matches['Path']
                        } | Select-Object -Property ComputerName, SDKVersion, SDKPath, RuntimeType, RuntimeVersion, RuntimePath
                        # The Select-Object above is for PSv2 quirks mode to include all properties for all objects.
                    }
                    else {
                        Write-Warning "[$Env:ComputerName] Unrecognized output from 'dotnet.exe --list-runtimes'. Output was '$Runtime'."
                    }
                }
            
            }
            catch {
                Write-Warning "[$Env:ComputerName] Failed to execute 'dotnet.exe --list-runtimes'. Error was '$_'"
            }
            $ErrorActionPreference = 'Continue'
        } # End of script block to run on remote computers to rather simply gather and structure data into objects
        # from parsed dotnet.exe output (you can pass in a non-default path with -DotNetExePath <your_path>).

        $PSRSplat = @{
            ComputerName = $InnerComputerName
            ScriptBlock = $ScriptBlock
            ArgumentList = $DotNetExePath, $NoFallbackToSearchForDotNetExePath, $DotNetExeFallbackSearchDrives
        }

        if ($Credential.Username -match '\S') {
            $PSRSplat['Credential'] = $Credential
        }

        $Results = Invoke-Command @PSRSplat
        $Results
    
    } # End of advanced function End block.

} # End of function.
