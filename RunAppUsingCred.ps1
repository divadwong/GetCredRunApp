# RunAppUsingCred.ps1
# Created 5/10/19 - David Wong
# This script Maps the user's R: Drive, runs usrstartup.cmd and then runs EXE
#**********************************************************************************
Param(
	[Parameter(Mandatory=$True)]
	[string]$RunExe)

#  Popup Message function
function PopupMsg($Msg,$PopupTitle,$Timeout,$Icon)
{
    $vbOKOnly=0;$vbOKCancel=1;$vbYesNoCancel=3;$vbYesNo=4
    $VBCritical=16;$vbQuestion=32;$vbExclamation=48;$vbInformation=64
    $vbDefaultButton1=0;$vbDefaultButton2=256;$vbDefaultButton3=512
    $vbOK=1;$vbCancel=2;$vbAbort=3;$vbRetry=4;$vbIgnore=5;$vbYes=6;$vbNo=7
    $DefaultButton=$vbDefaultButton1
    $wshell = New-Object -ComObject Wscript.Shell
    $Result = $wshell.Popup($Msg,$TimeOut,$PopupTitle,$vbOKOnly+$Icon+$vbDefaultButton)
    if ($Result -eq $vbOK -or $Result -eq -1)
        {return $True}
    elseif ($Result -eq $vbCancel)
        {return $false}
}

###  START ###
# Unmap R:
Remove-SmbMapping -LocalPath 'R:' -Force
# Map User R Drive
try{New-SmbMapping -LocalPath 'R:' -HomeFolder -Persistent $False -EA Stop}
catch{PopupMsg "Your personal folder failed to map. Your work will not be saved to your H: drive." "******** NOTICE ********" 60 16}

# Run user startup script
& usrstartup.cmd

# Run exe and it's arguments
[string]$arg = $null

#$RunIt = $RunEXE.Split(" "); $R = $RunIt[0]
#For ($i=1; $i -le $RunIt.Count-1; $i++){$arg += " " + $RunIt[$i]}
#if (Test-Path $R)
#	{if ($arg){Start-Process $R $Arg} else {Start-Process $R}}		
#else
#	{PopupMsg "$R not found" "Critical Error launching application" 15 16}
	
$RunIt = $RunEXE.Split(" "); $R = $RunIt[0]
For ($i=1; $i -le $RunIt.Count-1; $i++){$arg += $RunIt[$i] + ","}
if (Test-Path $R){& $R $Arg} else {PopupMsg "$R not found" "Critical Error launching application" 15 16}