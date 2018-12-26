# DotNetVersionLister
Get a list of installed .NET versions on (remote) Windows computers

As of 2018-12-26 versions up to .NET 4.7.2 are supported/detected.

Blog documentation (I'm too lazy to duplicate here): https://www.powershelladmin.com/wiki/List_installed_.NET_versions_on_remote_computers 

It's published to the PowerShell Gallery, so you can install/inspect/download with `Install-Module`, `Find-Module` and `Save-Module`.

Example installation for your user only:

```
Install-Module -Name DotNetVersionLister -Scope CurrentUser #-Force
```

Example use:

`Get-DotNetVersion`

and

`Get-DotNetVersion -ComputerName server1, server2, server3`.

Example output:

```
Get-DotNetVersion


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
