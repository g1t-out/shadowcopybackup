# Shadow Copy Backups in Windows
>**:warning: This script most likely has bugs in it. We are not responsible for any data loss that might occur from using this. Continue at your own risk.**

This script can create a shadow copy and mount it as a drive. Then it will run a script that has been passed to it. Last it will delete the exposed snapshot.

:warning: Do not place this script or the script this calls in a location where it can be edited by someone with lower level permissions on the system. This must run with a high level of permissions (And the script it calls will also run with those permissions).

In order to use this, you'll need to have vshadow.exe on your system. I've found it in the past in the Windows SDK ( See https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/ )

To calls this script from within Task scheduler, I set the program/script to:

`powershell.exe`

And then the arguments to:

`-File C:\BackupScripts\shadowcopybackup.ps1 -datadrive C -mountletter Z -script "powershell.exe" -passargs "-file c:\BackupScripts\email_backup.ps1"`
