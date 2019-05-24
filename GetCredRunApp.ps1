# GetCredRunApp.ps1
# Created 5/9/19 - David Wong
# Updated 5/18/19
# Get credential from user and run Program with those credentials
Param(
	[Parameter(Mandatory=$False)]
	[string]$RunExe=$null,

	[Parameter(Mandatory=$False)]
	[string]$LogonTitle="Login ",
	
	[Parameter(Mandatory=$False)]
	[array]$CheckGroup=$null
)

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

function Test-Credential {
    <# 
    .SYNOPSIS
        Takes a PSCredential object and validates it against the domain (or local machine, or ADAM instance).

    .PARAMETER cred
        A PScredential object with the username/password you wish to test. Typically this is generated using the Get-Credential cmdlet. Accepts pipeline input.

    .PARAMETER context
        An optional parameter specifying what type of credential this is. Possible values are 'Domain','Machine',and 'ApplicationDirectory.' The default is 'Domain.'

    .OUTPUTS
        A boolean, indicating whether the credentials were successfully validated.

    #>
    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [System.Management.Automation.PSCredential]$credential,
        [parameter()][validateset('Domain','Machine','ApplicationDirectory')]
        [string]$context = 'Domain'
    )
    begin {
        Add-Type -assemblyname system.DirectoryServices.accountmanagement
        $DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::$context)
    }
    process {
        $DS.ValidateCredentials($credential.UserName, $credential.GetNetworkCredential().password)
    }
}

### Start ####
$location = Split-Path $PSCommandPath -Parent
$Server=$env:computername
$Domain=$env:userdomain

# If no -RunEXE parameters, quit.
if (!($RunEXE)){Exit}	

# Get and check credentials ($Credential) from user.
$LogonMess = " Please enter your User name and Password"

# Get Credentials until validated or canceled (will exit script).
Do{
    $Credential = $host.ui.PromptForCredential($LogonTitle, $LogonMess , "", $Domain)
	if (!($Credential)){Exit}

	$UserID = $Credential.Username
	if ($UserID.Split('\').count-1 -gt 0){
		if ($UserID.Split('\')[0] -eq $Domain){$GoodDomain = $true;$UserID = ($Credential.username).Split('\')[1]} 
		else {$GoodDomain = $false}
	}	
	elseif ($UserID.Split('@')[1] -eq $Domain){$GoodDomain = $true;$UserID = ($Credential.username).Split('@')[0]}
		else {$GoodDomain = $false}
	
	if ($GoodDomain){
		$Authenticated = Test-Credential $credential
		$LogonMess = " Invalid Login. Please try again"
	}
	else {
		$Authenticated = $false
		$LogonMess = "Please type only User name and exclude domain"
	}
} While(!$Authenticated)	

$RunExeArg = "-File \\server\Share\RunAppUsingCred.ps1 -RunEXE `"$RunEXE`""

# Run EXE with Credentials gathered
if ($Credential)
{	
	$InCheckedGroup = $false	# Initialize
	
	# & X:\Apps\Wait.exe  # Please wait message	
	
	if ($CheckGroup){
		#$InGroups = (Get-ADPrincipalGroupMembership $UserID).sAMAccountName
		# Get-Aduser is more reliable. Get-ADPrincipalGroupmembership fails in certain situations.
		$InGroups = ((Get-ADUser $UserID -Properties MemberOf).MemberOf | %{[adsi]"GC://$_"}).SamAccountName
		if ($InGroups -Contains $CheckGroup){$InCheckedGroup = $true}
	}
	else {$InCheckedGroup = $null}
		
	if (($InCheckedGroup -eq $true) -or ($InCheckedGroup -eq $null)){
		Start-Process Powershell.exe $RunExeArg -Credential $Credential -WindowStyle Hidden
	}
	else
	{
		PopupMsg "You are not authorized to launch this application. Call your HelpDesk for assistance." "ERROR: Not in $CheckGroup Group" 30 16
		$UserID = $UserID + "-NotInGroup-" + $CheckGroup
	}
}
