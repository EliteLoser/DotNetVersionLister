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
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('Cn', 'PSComputerName', 'Name')]
        [String[]]$ComputerName,
        
        [PSCredential]$Credential,

        [String]$DotNetExePath = 'C:\Program Files\dotnet\dotnet.exe'
    )

    Begin {
        $InnerComputerName = @()
    }
    Process {
        # I want all of the collected for one call to Invoke-Command rather
        # than multiple, so therefore, if people pipe in computer names,
        # I collect them in an array and run the code in the end block.
        # The Process{} block's "$ComputerName" will be one single string/object
        # for each pipeline element, or if they are passed as an argument, it will
        # simply append the (possibly one-element) array to the inner array.
        $InnerComputerName += $ComputerName
    }

    End {
        $ScriptBlock = {
            Param(
                [String]$DotNetExePath
            )
            $ErrorActionPreference = 'Stop'
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
        # from parsed dotnet.exe output (has to be in $Env:Path or you must modify).

        $PSRSplat = @{
            ComputerName = $InnerComputerName
            ScriptBlock = $ScriptBlock
            ArgumentList = $DotNetExePath
        }

        if ($Credential.Username -match '\S') {
            $PSRSplat['Credential'] = $Credential
        }

        $Results = Invoke-Command @PSRSplat
        $Results
    
    } # End of advanced function End block.

} # End of function.

