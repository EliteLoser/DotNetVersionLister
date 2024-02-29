#requires -version 2
function Get-STDotNetVersion2 {
    <#
    .SYNOPSIS
        Get .NET versions parsed from the "dotnet.exe --list-runtimes" and
        "dotnet.exe --list-sdks" output, either as invoked via PSRemoting/WinRM
        or on the local host/system/computer.

        If you supply one or more computer names with the -ComputerName parameter,
        PowerShell remoting/WinRM will be used. If you supply no computer names,
        the local host/computer is checked.

        This is for .NET 5 and above. For retrieving .NET Framework versions,
        see https://github.com/EliteLoser/DotNetVersionLister (versions 1-4.x).

        Author: Joakim Borger Svendsen, Svendsen Tech.

        MIT License.

        2023-05-24. Disclaimer: This was written in less than two hours and tested
        against only a couple of computers. But should mostly work. You are welcome
        to provide feedback or suggest changes on GitHub.

        See https://github.com/EliteLoser/DotNetVersionLister/blob/master/5AndUp

    .PARAMETER ComputerName
        Computer names to scan for .NET 5+ versions.
    .PARAMETER Credential
        Alternate credentials for the PSRemoting.
    .PARAMETER DotNetExePath
        Custom dotnet.exe path. Default: 'C:\Program Files\dotnet\dotnet.exe'.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('Cn', 'PSComputerName', 'Name')]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [AllowNull()]
        [String[]]$ComputerName = @(),
        [PSCredential]$Credential,
        [String]$DotNetExePath = 'C:\Program Files\dotnet\dotnet.exe' #,
        #[Bool]$LocalHost = $True

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
        # simply append the (possibly one-element) array to the (then empty) inner array,
        # effectively forming a new array or replacing the empty array with itself.
        $InnerComputerName += $ComputerName
    }
    End {
        $InnerScriptBlock = {
            $ErrorActionPreference = 'Stop'
            # Return a warning if the executable doesn't exist.
            if (-not (Test-Path -LiteralPath $InnerDotNetExePath -PathType Leaf)) {
                Write-Warning "[$Env:ComputerName] Path to dotnet.exe doesn't exist ($DotNetExePath). Cannot continue with this computer."
                return
            }
            # SDK section.
            try {
                foreach ($SDK in & $InnerDotNetExePath --list-sdks) {
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
                        Write-Warning "[$Env:ComputerName] Unrecognized output from '$InnerDotNetExePath --list-sdks'. Output was '$SDK'."
                    }
                }
            
            }
            catch {
                Write-Warning "[$Env:ComputerName] Failed to execute '$InnerDotNetExePath --list-sdks'. Error was '$_'"
            }
            # Runtime section.
            try {
                foreach ($Runtime in & $InnerDotNetExePath --list-runtimes) {
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
                        Write-Warning "[$Env:ComputerName] Unrecognized output from '$InnerDotNetExePath --list-runtimes'. Output was '$Runtime'."
                    }
                }
            
            }
            catch {
                Write-Warning "[$Env:ComputerName] Failed to execute '$InnerDotNetExePath --list-runtimes'. Error was '$_'"
            }
            $ErrorActionPreference = 'Continue'
        }
        # End of inner script block to run on remote computers to rather simply gather and structure data into objects
        # from parsed dotnet.exe output (you can pass in a non-default path with -DotNetExePath <your_path>).
        # The below is a hack to avoid code duplication and a way to handle creating a script block with the
        # value of a variable in the script ($DotNetExePath).
        $ScriptBlockToHandleDotNetExePath = [ScriptBlock]::Create(@"
        Param([String]`$InnerDotNetExePath = "$DotNetExePath")
        $InnerScriptBlock
"@      )
        if ($InnerComputerName.Count -gt 0) {
            Write-Verbose -Message "Computer names piped in or specified via parameter, using WinRM."
            $PSRSplat = @{
                ComputerName = $InnerComputerName
                ScriptBlock = $ScriptBlockToHandleDotNetExePath
                ArgumentList = $DotNetExePath
            }
            if ($Credential.Username -match '\S') {
                $PSRSplat['Credential'] = $Credential
            }
            $Results = Invoke-Command @PSRSplat
            $Results
        }
        else {
            Write-Verbose -Message "No computer names piped in or specified via parameter, checking local host."
            $Results = & $ScriptBlockToHandleDotNetExePath
            $Results
        }
    } # End of advanced function End block.
} # End of function.
