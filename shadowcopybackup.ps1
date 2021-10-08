#### Syntax is shadowcopybackup.ps1 -DataDrive <DRIVELETTER> -MountLetter <DRIVELETTER> -Script <FULL PATH TO SCRIPT> "<ARGS TO PASS SCRIPT>"
#### Syntax could aslo be: shadowcopybackup.ps1 <DataDriveLetter> <MountDriveLetter> <FULL PATH TO SCRIPT> "<ARGS TO PASS SCRIPT>"
#### DataDrive is the drive we are making a shadow copy of
#### MountLetter is a drive letter we can use to mount the shadow copy
#### PLEASE NOTE: All the args to pass to the script MUST be surrounded by double quotes (")
Param(
[string]$datadrive = $(throw "-DataDrive is required."),
[string]$mountletter = $(throw "-MountLetter is required."),
[string]$script = $(throw "-Script is required."),
[string[]] $passargs
)
#Path to your vshadow.exe file
#$vshadow = "C:\Program Files (x86)\Windows Kits\10\bin\x64\vshadow.exe"
$vshadow = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.18362.0\x64\vshadow.exe"
$logging = $true
$log_dir = "<<LOG DIRECTORY>>"
$LogDaysToKeep = 30;
if($logging) {
	$date = get-date
	$logpath = $log_dir + "Backup-" + $date.ToString("yyyyMMdd")
	Start-Transcript -Path $logpath
	Write-Host "Starting Logging...."
	Write-Host "Deleting old Logs...."
	$DeleteBefore = $date.AddDays(- $LogDaysToKeep);
	Get-ChildItem $log_dir | foreach-object {
		if($_.LastWriteTime -lt $DeleteBefore) {
			Write-host "Deleting $($_.Name)..."
			remove-Item $_.FullName
		}
	}
}


Write-Host "DataDrive is $datadrive"
Write-Host "MountLetter is $mountletter"
Write-Host "Script is $script"
Write-Host "Passargs is $passargs"

#We are adding Colons to your drive letters if you did not
if(-Not $datadrive.Endswith(":"))
{
    $datadrive = $datadrive + ":"
}
if(-Not $mountletter.Endswith(":"))
{
    $mountletter = $mountletter + ":"
}

###Lets go see if you've got a shadow copy that is hanging around.

$listshadows = "& '$vshadow' -q"
$SnapShotID = "";

invoke-expression $listshadows | foreach-object {
	if($_ -match "\* SNAPSHOT ID = \{(\S+)\} \.\.\.") {
		$SnapShotID = $matches[1]
	} elseif ($_ -match "Exposed locally as") {
		###We found a snapshow that is mounted. Perhaps this was errantly left over from another backup? We need to delete it.
		$deletecommand = "& '$vshadow' -ds=`"{$SnapShotID}`"";
		Write-host "Deleting Errant Snapshot. ID: $SnapShotID"
		invoke-expression $deletecommand;
	}
	
}

if(Test-Path $mountletter) {
	throw "It appears the Mount Letter: $mountletter is in use already";
}

$shadowcommand = "& '$vshadow' -p $datadrive"
$shadowGUID = $null
Write-Host "Creating Shadow Copy..."
invoke-expression $shadowcommand | foreach-object {
    if($_ -match "Access is denied")
    { Write-Host "You must be running as Administrator to make a shadow copy."; exit; }
    if($_ -match "\* SNAPSHOT ID = \{(\S+)\} \.\.\.") {
        if(-Not $shadowGUID -eq $null)
        {
            Write-Host "Found more than one Snapshot ID. Dying!"
            exit;
        }
        $shadowGUID = $matches[1]
    }
}
if($shadowGUID -eq $null) {
    Write-Host "Did not match a shadowcopy GUID."
    exit;
}
Write-Host "Completed Shadow Copy. GUID=$shadowGUID"
Write-Host "Mounting Shadow Copy."
$mountcommand = "& '$vshadow' -el=`"{$shadowGUID},$mountletter`""
$deletecommand = "& '$vshadow' -ds=`"{$shadowGUID}`""

Write-Host "*$mountcommand*"
invoke-expression $mountcommand
if(-Not (Test-Path $mountletter )) {
    Write-Host "Shadow Copy Mount did not work for some reason."
    invoke-expression $deletecommand
    exit
}

if($passargs -eq $null) {
    Start-Process "$script" -Wait
} else {
    Start-Process "$script" "$passargs" -Wait
} 

invoke-expression $deletecommand

Write-Host "Script Finished." 