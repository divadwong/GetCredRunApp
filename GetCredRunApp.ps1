# GetCredRunApp.ps1
# Created 5/9/19 - David Wong
# Get credential from user and run Program with those credentials
Param(
	[Parameter(Mandatory=$False)]
	[string]$RunExe=$null,

	[Parameter(Mandatory=$False)]
	[string]$LogonTitle="Logon Page",
	
	[Parameter(Mandatory=$False)]
	[string]$LogAppName=$null
)

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

# If no -RunEXE parameters, log error and quit.
if (!($RunEXE)){Exit}	

# Get and check credentials ($Credential) from user.
$Authenticated = $false
$LogonMess = " Please enter your User name and Password"

# Get Credentials until validated or canceled (will exit script).
Do{
    $Credential = $host.ui.PromptForCredential($LogonTitle, $LogonMess , "", "yourdomainhere")
	if (!($Credential)){Exit}
	$Authenticated = Test-Credential $credential
	$LogonMess = " Invalid Login. Please try again"
}
While(!($Authenticated))	

$RunExeArg = "-File \\Server\Share\Folder\RunAppUsingCred.ps1 -RunEXE `"$RunEXE`""

# Run EXE with Credentials gathered
if ($Credential) {Start-Process Powershell.exe $RunExeArg -Credential $Credential -WindowStyle Hidden}
