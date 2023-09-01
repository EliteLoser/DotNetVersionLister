# Get .NET 5+ SDK And Runtime Versions

Usage:

``` 
Invoke-WebRequest -OutFile Get-STDotNetVersion2.psm1 -Uri 'https://raw.githubusercontent.com/EliteLoser/DotNetVersionLister/master/5AndUp/Get-STDotNetVersion2.ps1'
Import-Module -Name ./Get-STDotNetVersion2.psm1    
# . D:\temp\Get-STDotNetVersion2.ps1
$Results = Get-STDotNetVersion2 -ComputerName $ArrayOfComputers
$SDKs = $Results | Where-Object {$_.SDKVersion}
$Runtimes = $Results | Where-Object {$_.RuntimeType}
$Results
```  
# Get The Local Computer's .NET 5+ SDK And Runtime Versions

```
$Results = Get-STDotNetVersion2
$SDKs = $Results | Where-Object {$_.SDKVersion}
$Runtimes = $Results | Where-Object {$_.RuntimeType}
$Results
``` 

NB. If you want to merge these results with the Get-STDotNetVersion/DotNetVersionLister results, you can use Merge-Csv with the 
-AllowDuplicates switch: https://github.com/EliteLoser/MergeCsv (`Install-Module -Scope CurrentUser -Name MergeCsv #-Force`). 
Despite the function name Merge-Csv, it handles custom PowerShell objects directly as well. It won't be perfect, though, but "works". :)

Example (censored). Only one SDK, and some runtimes. In the script's default output you will have a ComputerName property
that is the remote computer's `$Env:ComputerName` variable and also a PSComputerName property from PowerShell (in version
3 and up) that is the computer name passed in to Invoke-Command, plus a runspace ID (by default). I filtered these out here
for privacy reasons.

```
> Get-STDotNetVersion2 -ComputerName serverA | 
    Select SDKVersion, SDKPath, RuntimeType, RuntimeVersion, RuntimePath
    # This to censor the computer name

SDKVersion     : 6.0.408
SDKPath        : C:\Program Files\dotnet\sdk
RuntimeType    :
RuntimeVersion :
RuntimePath    :


SDKVersion     :
SDKPath        :
RuntimeType    : Microsoft.AspNetCore.All
RuntimeVersion : 2.1.2
RuntimePath    : C:\Program Files\dotnet\shared\Microsoft.AspNetCore.All

SDKVersion     :
SDKPath        :
RuntimeType    : Microsoft.AspNetCore.All
RuntimeVersion : 2.1.3
RuntimePath    : C:\Program Files\dotnet\shared\Microsoft.AspNetCore.All

SDKVersion     :
SDKPath        :
RuntimeType    : Microsoft.AspNetCore.App
RuntimeVersion : 2.1.2
RuntimePath    : C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App

SDKVersion     :
SDKPath        :
RuntimeType    : Microsoft.AspNetCore.App
RuntimeVersion : 2.1.3
RuntimePath    : C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App

SDKVersion     :
SDKPath        :
RuntimeType    : Microsoft.AspNetCore.App
RuntimeVersion : 3.1.9
RuntimePath    : C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App

SDKVersion     :
SDKPath        :
RuntimeType    : Microsoft.AspNetCore.App
RuntimeVersion : 6.0.16
RuntimePath    : C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App

SDKVersion     :
SDKPath        :
RuntimeType    : Microsoft.NETCore.App
RuntimeVersion : 2.1.2
RuntimePath    : C:\Program Files\dotnet\shared\Microsoft.NETCore.App

SDKVersion     :
SDKPath        :
RuntimeType    : Microsoft.NETCore.App
RuntimeVersion : 2.1.3
RuntimePath    : C:\Program Files\dotnet\shared\Microsoft.NETCore.App

SDKVersion     :
SDKPath        :
RuntimeType    : Microsoft.NETCore.App
RuntimeVersion : 3.1.9
RuntimePath    : C:\Program Files\dotnet\shared\Microsoft.NETCore.App

SDKVersion     :
SDKPath        :
RuntimeType    : Microsoft.NETCore.App
RuntimeVersion : 6.0.16
RuntimePath    : C:\Program Files\dotnet\shared\Microsoft.NETCore.App

SDKVersion     :
SDKPath        :
RuntimeType    : Microsoft.WindowsDesktop.App
RuntimeVersion : 6.0.16
RuntimePath    : C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App


```

