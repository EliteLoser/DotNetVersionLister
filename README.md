# DotNetVersionLister
Get a list of installed .NET versions on (remote) Windows computers.

As of 2019-01-30 versions up to .NET 4.7.2 are supported/detected. It's based on the information in this article: https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed

Blog documentation (I'm too lazy to duplicate here): https://www.powershelladmin.com/wiki/List_installed_.NET_versions_on_remote_computers 

It's published to the PowerShell Gallery, so you can install/inspect/download with `Install-Module`, `Find-Module` and `Save-Module`. Link: https://www.powershellgallery.com/packages/DotNetVersionLister/ 

Example installation for your user only:

```
Install-Module -Name DotNetVersionLister -Scope CurrentUser #-Force
```

Example use:

`Get-STDotNetVersion`

and

`Get-STDotNetVersion -ComputerName server1, server2, server3`

or

`Get-STDotNetVersion -ComputerName server1, server2, server3 -PSRemoting`

Example output:

```
Get-STDotNetVersion -NoSummary


ComputerName : localhost
>=4.x        : 4.6.2
v4\Client    : Installed
v4\Full      : Installed
v3.5         : Not installed (no key)
v3.0         : Not installed (no key)
v2.0.50727   : Not installed (no key)
v1.1.4322    : Not installed (no key)
Ping         : True
Error        : 
```

# Notes

The command/function name used to be `Get-DotNetVersion` in versions before v3 of the module. This is aliased if the command does not currently exist in the PowerShell session, but you have to either run `Get-STDotNetVersion` first to load it, as auto-load for `Get-DotNetVersion` does not work - or you can simply `Import-Module -Name DotNetVersionLister` first, as we had to on PowerShell v2.
