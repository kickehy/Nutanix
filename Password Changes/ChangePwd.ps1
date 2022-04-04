<#
.NOTES
    Author: Brad Meyer
    Contributor: Taylor Siegrist
    Date:   April 4, 2022

    ###############################################-----LICENSE-----#######################################################
      BSD 3-Clause License

      Copyright (c) 2022, Brad Meyer
      All rights reserved.

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions are met:

      1. Redistributions of source code must retain the above copyright notice, this
           list of conditions and the following disclaimer.

      2. Redistributions in binary form must reproduce the above copyright notice,
          this list of conditions and the following disclaimer in the documentation
          and/or other materials provided with the distribution.

      3. Neither the name of the copyright holder nor the names of its
          contributors may be used to endorse or promote products derived from
          this software without specific prior written permission.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
      AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
      DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
      FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
      DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
      SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
      CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
      OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
      OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
    ######################################################################################################################
.SYNOPSIS
    Password changes for Nutanix clusters connected to Prism Central(s) or individual clusters.
.DESCRIPTION
    This script will change passwords for all Nutanix clusters connected to Prism Central(s) or individual clusters.
    Current options are for CVM nutanix, Files nutanix, Prism admin, host root, host admin (AHV only), host nutanix (AHV only), and IPMI.
    Only supported for AHV and ESXi. Hyper-V is NOT supported.
    IPMI currently only verified for NX & Dell.
.PARAMETER pclist
    List of Prism Central(s), comma separated, to run the script against.
    Ex. pc1.domain.com,pc2.domain.com,pc3.domain.com,10.10.10.10
    Ex. "pc1.domain.com","pc2.domain.com","pc3.domain.com","10.10.10.10"
    Ex. "pc1.domain.com,pc2.domain.com,pc3.domain.com,10.10.10.10"
    Alias: -pcl
.PARAMETER pelist
    List of individual Nutanix clusters, comma separated, to run the script against.
    Ex. clu01.domain.com,clu02.domain.com,10.10.10.10
    Ex. "clu01.domain.com","clu02.domain.com","10.10.10.10"
    Ex. "clu01.domain.com,clu02.domain.com,10.10.10.10"
    Alias: -pel
.PARAMETER a
    Enable password change for ALL environments.
.PARAMETER c
    Enable password change for CVM nutanix.
.PARAMETER f
    Enable password change for Nutanix Files.
.PARAMETER hr
    Enable password change for host root.
.PARAMETER ha
    Enable password change for host admin (AHV only).
.PARAMETER hn
    Enable password change for host nutanix (AHV only).
.PARAMETER i
    Enable password change for IPMI.
    NOTE: If the platform is NX, BMC version is below 3.40, and you have special characters in the new password, it will say it successfully changes the password, but doesn't actually change the password.
.PARAMETER p
    Enable password change for Prism admin.
.PARAMETER credman
    This will cause the script to look for credentials to be supplied via Windows Credential Manager.
    The following are expected depending on the environments specified:
        NTNX_PC_admin
        NTNX_CVM_nutanix
        NTNX_Files_nutanix
        NTNX_New_CVM_nutanix
        NTNX_New_Files_nutanix
        NTNX_New_Host_root
        NTNX_New_Host_admin
        NTNX_New_Host_nutanix
        NTNX_New_IPMI
        NTNX_New_Prism_admin
.PARAMETER pcadmin
    Specifies the current Prism Central (PC) admin password. REQUIRED field when not using Windows Credential Manager and using -pclist.
    Must use single quotes when specifying otherwise you may have unexpected results: -pcadmin 'Pa$$w0rd'
    Alias: -pca
.PARAMETER cvmnutanix
    Specifies the current CVM nutanix password. REQUIRED field when not using Windows Credential Manager.
    Must use single quotes when specifying otherwise you may have unexpected results: -cvmnutanix 'Pa$$w0rd'
    Alias: -cn
.PARAMETER filesnutanix
    Specifies the current Files nutanix password.
    Must use single quotes when specifying otherwise you may have unexpected results: -filesnutanix 'Pa$$w0rd'
    Alias: -fn
.PARAMETER newprismadmin
    Specifies the new Prism admin password. Must be specified if -p or -a is used.
    Must use single quotes when specifying otherwise you may have unexpected results: -newprismadmin 'Pa$$w0rd'
    Alias: -npa
    ------------------------------------------
    Password Requirements:
        At least 8 characters.
        No more than 199 characters.
        At least one upper case letter (A-Z).
        At least one lower case letter (a-z).
        At least one digit (0-9).
        At least one printable ASCII special (non-alphanumeric) character. Such as a percent (%), plus (+), or tilde (~).
        Must NOT contain any of the following special characters: ' "
        At least 4 characters difference from the old password.
        Must not be among the last 5 passwords.
        Must not have more than 2 consecutive occurrences of a character.
.PARAMETER newcvmnutanix
    Specifies the new CVM nutanix password. Must be specified if -c or -a is used.
    Must use single quotes when specifying otherwise you may have unexpected results: -newcvmnutanix 'Pa$$w0rd'
    Alias: -ncn
    ------------------------------------------
    Password Requirements:
        At least 8 characters.
        No more than 199 characters.
        At least one upper case letter (A-Z).
        At least one lower case letter (a-z).
        At least one digit (0-9).
        At least one printable ASCII special (non-alphanumeric) character. Such as a percent (%), plus (+), or tilde (~).
        Must NOT contain any of the following special characters: ' " \ | `
        At least 4 characters difference from the old password.
        Must not be among the last 5 passwords.
        Must not have more than 2 consecutive occurrences of a character.
.PARAMETER newfilesnutanix
    Specifies the new Nutanix Files password. Must be specified if -f or -a is used.
    Must use single quotes when specifying otherwise you may have unexpected results: -newfilesnutanix 'Pa$$w0rd'
    Alias: -nfn
    ------------------------------------------
    Password Requirements:
        At least 8 characters.
        No more than 39 characters.
        At least one upper case letter (A-Z).
        At least one lower case letter (a-z).
        At least one digit (0-9).
        At least one printable ASCII special (non-alphanumeric) character. Such as a percent (%), plus (+), or tilde (~).
        Must NOT contain any of the following special characters: ' " \ | `
        At least 4 characters difference from the old password.
        Must not be among the last 10 passwords.
.PARAMETER newhostr
    Specifies the new host root password. Must be specified if -hr or -a is used.
    Must use single quotes when specifying otherwise you may have unexpected results: -newhostr 'Pa$$w0rd'
    Alias: -nhr
    ------------------------------------------
    Password Requirements (Without High-Security Requirements):
        At least 8 characters.
        No more than 39 characters.
        At least one upper case letter (A-Z).
        At least one lower case letter (a-z).
        At least one digit (0-9).
        At least one printable ASCII special (non-alphanumeric) character. Such as a percent (%), plus (+), or tilde (~).
        Must NOT contain any of the following special characters: ' " \ `
        Must NOT contain any of the following special character combinations: ${  $(
        At least 3 characters difference from the old password.
        Must not be among the last 10 passwords.
        Must not have more than 3 consecutive occurrences of a character.
.PARAMETER newhosta
    Specifies the new host admin password (AHV Only). Must be specified if -ha or -a is used.
    Must use single quotes when specifying otherwise you may have unexpected results: -newhosta 'Pa$$w0rd'
    Alias: -nha
    ------------------------------------------
    Password Requirements (Without High-Security Requirements):
        At least 8 characters.
        No more than 39 characters.
        At least one upper case letter (A-Z).
        At least one lower case letter (a-z).
        At least one digit (0-9).
        At least one printable ASCII special (non-alphanumeric) character. Such as a percent (%), plus (+), or tilde (~).
        Must NOT contain any of the following special characters: ' " \ `
        Must NOT contain any of the following special character combinations: ${  $(
        At least 3 characters difference from the old password.
        Must not be among the last 10 passwords.
        Must not have more than 3 consecutive occurrences of a character.
.PARAMETER newhostn
    Specifies the new host nutanix password (AHV Only). Must be specified if -hn or -a is used.
    Must use single quotes when specifying otherwise you may have unexpected results: -newhostn 'Pa$$w0rd'
    Alias: -nhn
    ------------------------------------------
    Password Requirements (Without High-Security Requirements):
        At least 8 characters.
        No more than 39 characters.
        At least one upper case letter (A-Z).
        At least one lower case letter (a-z).
        At least one digit (0-9).
        At least one printable ASCII special (non-alphanumeric) character. Such as a percent (%), plus (+), or tilde (~).
        Must NOT contain any of the following special characters: ' " \ `
        Must NOT contain any of the following special character combinations: ${  $(
        At least 3 characters difference from the old password.
        Must not be among the last 10 passwords.
        Must not have more than 3 consecutive occurrences of a character.
.PARAMETER newipmi
    Specifies the new IPMI password. Must be specified if -i or -a is used.
    Must use single quotes when specifying otherwise you may have unexpected results: -newipmi 'Pa$$w0rd'
    CURRENT TESTED HARDWARE: NX & Dell
    Alias: -nipmi
    ------------------------------------------
    Password Requirements:
        At least 8 characters.
        No more than 20 characters.
        Password can not be the reverse of the user name.
        At least one upper case letter (A-Z).
        At least one lower case letter (a-z).
        At least one digit (0-9).
        At least one printable ASCII special (non-alphanumeric) character. Such as a percent (%), plus (+), or tilde (~).
        Must NOT contain any of the following special characters: < > & $ ( ) ` | : \ space
        Must NOT begin with a dash.
.PARAMETER log
    Specifies log location for the script. REQUIRED field.
    Ex. -log 'C:\temp\logs'
.EXAMPLE
    ChangePwd.ps1 -pclist pc1.domain.com -c -pcadmin 'current_pwd' -cvmnutanix 'current_pwd' -newcvmnutanix 'new_pwd' -log 'C:\log'
    This will change the password for CVM nutanix on all PEs attached to Prism Central pc1.domain.com.
.EXAMPLE
    ChangePwd.ps1 -pclist pc1.domain.com,10.10.10.10 -a -pcadmin 'current_pwd' -cvmnutanix 'current_pwd' -filesnutanix 'current_pwd' -newcvmnutanix 'new_pwd' -newfilesnutanix 'new_pwd' -newprismadmin 'new_pwd' -newhostr 'new_pwd' -newhosta 'new_pwd' -newhostn 'new_pwd' -newipmi 'new_pwd' -log 'C:\log'
    This will change the password for ALL environments on all PEs attached to Prism Centrals pc1.domain.com and 10.10.10.10.
.EXAMPLE
    ChangePwd.ps1 -pclist pc1.domain.com,pc2.domain.com -hr -i -credman -log 'C:\log'
    This will change the password for host root and ipmi on all PEs attached to Prism Centrals pc1.domain.com and pc2.domain.com. Pulls credentials from Windows Credential Manager.
.EXAMPLE
    ChangePwd.ps1 -pelist clu01.domain.com,10.12.12.111 -hr -ha -hn -cvmnutanix 'current_pwd' -newhostr 'new_pwd' -newhosta 'new_pwd' -newhostn 'new_pwd' -log 'C:\log'
    This will change the password for host root, admin, and nutanix on individual clusters clu01.domain.com and 10.12.12.111.
.EXAMPLE
    ChangePwd.ps1 -pelist clu01.domain.com,clu02.domain.com,10.12.12.111 -a -credman -log 'C:\log'
    This will change the password for ALL environments on individual clusters clu01.domain.com, clu02.domain.com, and 10.12.12.111.
.EXAMPLE
    ChangePwd.ps1 -pelist clu01.domain.com,clu02.domain.com -f -cvmnutanix 'current_pwd' -filesnutanix 'current_pwd' -newfilesnutanix 'new_pwd' -log 'C:\log'
    This will change the password for Files nutanix on individual clusters clu01.domain.com and clu02.domain.com.
#>

##################################################################################
############################## Region - Params ###################################
[CmdletBinding()]  
param (
    [Parameter(ParameterSetName="PCAllEnvCredMan",Mandatory=$true,Position=0)]
    [Parameter(ParameterSetName="PCAllEnvCredPrompt",Mandatory=$true,Position=0)]
    [Parameter(ParameterSetName="PCIndividualEnvCredMan",Mandatory=$true,Position=0)]
    [Parameter(ParameterSetName="PCIndividualEnvCredPrompt",Mandatory=$true,Position=0)]
    [Alias("pcl")]
    [string[]] $pclist,
	[Parameter(ParameterSetName="PEAllEnvCredMan",Mandatory=$true,Position=0)]
    [Parameter(ParameterSetName="PEAllEnvCredPrompt",Mandatory=$true,Position=0)]
    [Parameter(ParameterSetName="PEIndividualEnvCredMan",Mandatory=$true,Position=0)]
    [Parameter(ParameterSetName="PEIndividualEnvCredPrompt",Mandatory=$true,Position=0)]
    [Alias("pel")]
    [string[]] $pelist,
    [Parameter(ParameterSetName="PCAllEnvCredMan")]
    [Parameter(ParameterSetName="PCAllEnvCredPrompt")]
	[Parameter(ParameterSetName="PEAllEnvCredMan")]
    [Parameter(ParameterSetName="PEAllEnvCredPrompt")]
    [switch] $a,
    [Parameter(ParameterSetName="PCIndividualEnvCredMan")]
    [Parameter(ParameterSetName="PCIndividualEnvCredPrompt")]
    [Parameter(ParameterSetName="PEIndividualEnvCredMan")]
    [Parameter(ParameterSetName="PEIndividualEnvCredPrompt")]
    [switch] $c,
    [Parameter(ParameterSetName="PCIndividualEnvCredMan")]
    [Parameter(ParameterSetName="PCIndividualEnvCredPrompt")]
    [Parameter(ParameterSetName="PEIndividualEnvCredMan")]
    [Parameter(ParameterSetName="PEIndividualEnvCredPrompt")]
    [switch] $f,
    [Parameter(ParameterSetName="PCIndividualEnvCredMan")]
    [Parameter(ParameterSetName="PCIndividualEnvCredPrompt")]
    [Parameter(ParameterSetName="PEIndividualEnvCredMan")]
    [Parameter(ParameterSetName="PEIndividualEnvCredPrompt")]
    [switch] $hr,
    [Parameter(ParameterSetName="PCIndividualEnvCredMan")]
    [Parameter(ParameterSetName="PCIndividualEnvCredPrompt")]
	[Parameter(ParameterSetName="PEIndividualEnvCredMan")]
    [Parameter(ParameterSetName="PEIndividualEnvCredPrompt")]
    [switch] $ha,
    [Parameter(ParameterSetName="PCIndividualEnvCredMan")]
    [Parameter(ParameterSetName="PCIndividualEnvCredPrompt")]
    [Parameter(ParameterSetName="PEIndividualEnvCredMan")]
    [Parameter(ParameterSetName="PEIndividualEnvCredPrompt")]
    [switch] $hn,
    [Parameter(ParameterSetName="PCIndividualEnvCredMan")]
    [Parameter(ParameterSetName="PCIndividualEnvCredPrompt")]
    [Parameter(ParameterSetName="PEIndividualEnvCredMan")]
    [Parameter(ParameterSetName="PEIndividualEnvCredPrompt")]
    [switch] $i,
    [Parameter(ParameterSetName="PCIndividualEnvCredMan")]
    [Parameter(ParameterSetName="PCIndividualEnvCredPrompt")]
    [Parameter(ParameterSetName="PEIndividualEnvCredMan")]
    [Parameter(ParameterSetName="PEIndividualEnvCredPrompt")]
    [switch] $p,
    [Parameter(ParameterSetName="PCAllEnvCredMan", Mandatory=$true)]
    [Parameter(ParameterSetName="PCIndividualEnvCredMan", Mandatory=$true)]
    [Parameter(ParameterSetName="PEAllEnvCredMan", Mandatory=$true)]
    [Parameter(ParameterSetName="PEIndividualEnvCredMan", Mandatory=$true)]
    [switch] $credman,
    [Parameter(ParameterSetName="PCAllEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PCIndividualEnvCredPrompt", Mandatory=$true)]
    [Alias("pca")]
    [string] $pcadmin,
    [Parameter(ParameterSetName="PCAllEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PCIndividualEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PEAllEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PEIndividualEnvCredPrompt", Mandatory=$true)]
    [Alias("cn")]
    [string] $cvmnutanix,
    [Parameter(ParameterSetName="PCAllEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PCIndividualEnvCredPrompt")]
    [Parameter(ParameterSetName="PEAllEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PEIndividualEnvCredPrompt")]
    [Alias("fn")]
    [string] $filesnutanix,
    [Parameter(ParameterSetName="PCAllEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PCIndividualEnvCredPrompt")]
    [Parameter(ParameterSetName="PEAllEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PEIndividualEnvCredPrompt")]
    [Alias("npa")]
    [string] $newprismadmin,
    [Parameter(ParameterSetName="PCAllEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PCIndividualEnvCredPrompt")]
    [Parameter(ParameterSetName="PEAllEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PEIndividualEnvCredPrompt")]
    [Alias("ncn")]
    [string] $newcvmnutanix,
    [Parameter(ParameterSetName="PCAllEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PCIndividualEnvCredPrompt")]
    [Parameter(ParameterSetName="PEAllEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PEIndividualEnvCredPrompt")]
    [Alias("nfn")]
    [string] $newfilesnutanix,
    [Parameter(ParameterSetName="PCAllEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PCIndividualEnvCredPrompt")]
    [Parameter(ParameterSetName="PEAllEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PEIndividualEnvCredPrompt")]
    [Alias("nhr")]
    [string] $newhostr,
    [Parameter(ParameterSetName="PCAllEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PCIndividualEnvCredPrompt")]
    [Parameter(ParameterSetName="PEAllEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PEIndividualEnvCredPrompt")]
    [Alias("nha")]
    [string] $newhosta,
    [Parameter(ParameterSetName="PCAllEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PCIndividualEnvCredPrompt")]
    [Parameter(ParameterSetName="PEAllEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PEIndividualEnvCredPrompt")]
    [Alias("nhn")]
    [string] $newhostn,
    [Parameter(ParameterSetName="PCAllEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PCIndividualEnvCredPrompt")]
    [Parameter(ParameterSetName="PEAllEnvCredPrompt", Mandatory=$true)]
    [Parameter(ParameterSetName="PEIndividualEnvCredPrompt")]
    [Alias("nipmi")]
    [string] $newipmi,
    [Parameter(Mandatory=$true)]
    [string] $log
)
############################## End Region - Params ###############################
##################################################################################


##################################################################################
############################## Region - Environment Checks #######################
# If -a parameter is true, enable password changes for all environments
if ($a -eq $true) {
    $c=$f=$hr=$ha=$hn=$i=$p = $true
}
# Exit script if no environment is specified
if (($a -eq $false) -and ($c -eq $false) -and ($f -eq $false) -and ($hr -eq $false) -and ($ha -eq $false) -and ($hn -eq $false) -and ($i -eq $false) -and ($p -eq $false)) {
    Write-Error "No environment specified to change password on. (-a, -c, -f, -i, -hr, -ha, -hn, -p)"
    Exit
}
############################## End Region - Environment Checks ###################
##################################################################################


##################################################################################
############################## Region - Skip Cert Check ##########################
# Have to skip the certificate request since we're using self-signed certs. This is for PS 5 and below.
#   Simply use -SkipCertificateCheck in the Invoke-RestMethod API call for PS 6 or later.
Add-Type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
############################## End Region - Skip Cert Check ######################
##################################################################################


##################################################################################
############################## Region - Modules ##################################
# Verify modules required are installed and exit if anything is missing
$missingmodule = 0
if ($null -eq (Get-InstalledModule -Name "PSFramework" -ErrorAction SilentlyContinue)) {
    Write-Warning "Required module 'PSFramework' is missing. Please install."
    $missingmodule = 1
}
if ($null -eq (Get-InstalledModule -Name "Posh-SSH" -ErrorAction SilentlyContinue)) {
    Write-Warning "Required module 'Posh-SSH' is missing. Please install."
    $missingmodule = 1
}
if ($credman -eq $true) {
    if ($null -eq (Get-InstalledModule -Name "CredentialManager" -ErrorAction SilentlyContinue)) {
        Write-Warning "Required module 'CredentialManager' is missing. Please install."
        $missingmodule = 1
    }
}
if ($missingmodule -eq 1) {
    Write-Error "Exiting script due to missing modules..."
    Exit
}
# Import required modules if all modules are installed
Import-Module PSFramework
Import-Module Posh-SSH
if ($credman -eq $true) {
    Import-Module CredentialManager
}
############################## End Region - Modules ##############################
##################################################################################


##################################################################################
############################## Region - Logging ##################################
# Test log file location path and make sure it exists
if ((Test-Path -Path $log) -eq $false) {
    Write-Error "Log location path does not exist for: $log"
    Exit
}
# Documented at https://psframework.org/documentation/documents/psframework/logging/providers/logfile.html
$logFile = Join-Path -path $log -ChildPath "pwdlog-$(Get-date -f 'yyyyMMdd-HHmmss').CSV";
$paramSetPSFLoggingProvider = @{
    Name          = 'logfile'
    FilePath      = $logFile
    FileType      = 'CSV'
    Headers       = 'Timestamp','Level','Line','Message'
    Enabled       = $true
}
Set-PSFLoggingProvider @paramSetPSFLoggingProvider
############################## End Region - Logging ##############################
##################################################################################


##################################################################################
############################## Region - Passwords ################################
# Pull credentials from Windows Credential Manager if -credman is specified, and verify they exist and are not blank
$credmanmissing = $false
if ($credman -eq $true) {
    # Set current PC admin password
    $pcadmin = (Get-StoredCredential -Target 'NTNX_PC_admin' -AsCredentialObject).Password
    if ($pcadmin -eq "") {
        Write-Warning "Current PC admin password is blank/missing. Verify NTNX_PC_admin exists in Windows Credential Manager as a Generic Credential."
        $credmanmissing = $true
    }
    # Set current CVM nutanix password
    $cvmnutanix = (Get-StoredCredential -Target 'NTNX_CVM_nutanix' -AsCredentialObject).Password
    if ($cvmnutanix -eq "") {
        Write-Warning "Current CVM nutanix password is blank/missing. Verify NTNX_CVM_nutanix exists in Windows Credential Manager as a Generic Credential."
        $credmanmissing = $true
    }
    # Set current Files nutanix password if -f or -a is specified
    if (($f -eq $true) -or ($a -eq $true)) {
        $filesnutanix = (Get-StoredCredential -Target 'NTNX_Files_nutanix' -AsCredentialObject).Password
        if ($filesnutanix -eq "") {
            Write-Warning "New Files nutanix password is blank/missing. Verify NTNX_Files_nutanix exists in Windows Credential Manager as a Generic Credential."
            $credmanmissing = $true
        }
    }
    # Set new CVM nutanix password if -c or -a is specified
    if (($c -eq $true) -or ($a -eq $true)) {
        $newcvmnutanix = (Get-StoredCredential -Target 'NTNX_New_CVM_nutanix' -AsCredentialObject).Password
        if ($newcvmnutanix -eq "") {
            Write-Warning "New CVM nutanix password is blank/missing. Verify NTNX_New_CVM_nutanix exists in Windows Credential Manager as a Generic Credential."
            $credmanmissing = $true
        }
    }
    # Set new Files nutanix password if -f or -a is specified
    if (($f -eq $true) -or ($a -eq $true)) {
        $newfilesnutanix = (Get-StoredCredential -Target 'NTNX_New_Files_nutanix' -AsCredentialObject).Password
        if ($newfilesnutanix -eq "") {
            Write-Warning "New Files nutanix password is blank/missing. Verify NTNX_New_Files_nutanix exists in Windows Credential Manager as a Generic Credential."
            $credmanmissing = $true
        }
    }
    # Set new host root password if -hr or -a is specified
    if (($hr -eq $true) -or ($a -eq $true)) {
        $newhostr = (Get-StoredCredential -Target 'NTNX_New_Host_root' -AsCredentialObject).Password
        if ($newhostr -eq "") {
            Write-Warning "New host root password is blank/missing. Verify NTNX_New_Host_root exists in Windows Credential Manager as a Generic Credential."
            $credmanmissing = $true
        }
    }
    # Set new host admin password if -ha or -a is specified (AHV only)
    if (($ha -eq $true) -or ($a -eq $true)) {
        $newhosta = (Get-StoredCredential -Target 'NTNX_New_Host_admin' -AsCredentialObject).Password
        if ($newhosta -eq "") {
            Write-Warning "New host admin password is blank/missing. Verify NTNX_New_Host_admin exists in Windows Credential Manager as a Generic Credential."
            $credmanmissing = $true
        }
    }
    # Set new host nutanix password if -hn or -a is specified (AHV only)
    if (($hn -eq $true) -or ($a -eq $true)) {
        $newhostn = (Get-StoredCredential -Target 'NTNX_New_Host_nutanix' -AsCredentialObject).Password
        if ($newhostn -eq "") {
            Write-Warning "New host nutanix password is blank/missing. Verify NTNX_New_Host_nutanix exists in Windows Credential Manager as a Generic Credential."
            $credmanmissing = $true
        }
    }
    # Set new IPMI password if -i or -a is specified
    if (($i -eq $true) -or ($a -eq $true)) {
        $newipmi = (Get-StoredCredential -Target 'NTNX_New_IPMI' -AsCredentialObject).Password
        if ($newipmi -eq "") {
            Write-Warning "New IPMI password is blank/missing. Verify NTNX_New_IPMI exists in Windows Credential Manager as a Generic Credential."
            $credmanmissing = $true
        }
    }
    # Set new Prism admin password if -p or -a is specified
    if (($p -eq $true) -or ($a -eq $true)) {
        $newprismadmin = (Get-StoredCredential -Target 'NTNX_New_Prism_admin' -AsCredentialObject).Password
        if ($newprismadmin -eq "") {
            Write-Warning "New Prism admin password is blank/missing. Verify NTNX_New_Prism_admin exists in Windows Credential Manager as a Generic Credential."
            $credmanmissing = $true
        }
    }
    # If any credentials fail to exist or are blank, throw and error and exit the script
    if ($credmanmissing -eq $true) {
        Write-Error "Credentials not properly imported from Windows Credential Manager. Verify the proper generic credentials exist and are not blank."
        Exit
    }
}
# Verify New CVM nutanix password complexity requirements
#   Verified AOS 6.0: https://portal.nutanix.com/page/documents/details?targetId=Advanced-Admin-AOS-v6_0:app-nutanix-cvm-password-requirments-c.html
if (($c -eq $true) -or ($a -eq $true)) {
    $ncnfail = $false
    if ($newcvmnutanix.Length -lt 8) {
        Write-Warning "New CVM nutanix password is shorter than 8 characters."
        $ncnfail = $true
    } if ($newcvmnutanix.Length -gt 199) {
        Write-Warning "New CVM nutanix password is longer than 199 characters."
        $ncnfail = $true
    } if ($newcvmnutanix -cnotmatch '[a-z]') {
        Write-Warning "New CVM nutanix password is missing a lowercase letter."
        $ncnfail = $true
    } if ($newcvmnutanix -cnotmatch '[A-Z]') {
        Write-Warning "New CVM nutanix password is missing an uppercase letter."
        $ncnfail = $true
    } if ($newcvmnutanix -notmatch '[0-9]') {
        Write-Warning "New CVM nutanix password is missing a number."
        $ncnfail = $true
    } if ($newcvmnutanix -match '''') { #This is just annoying to deal with coding wise
        Write-Warning "New CVM nutanix password contains invalid character: '"
        $ncnfail = $true
    } if ($newcvmnutanix -match '\"') { #This is just annoying to deal with coding wise
        Write-Warning "New CVM nutanix password contains invalid character: `""
        $ncnfail = $true
    } if ($newcvmnutanix -match '[|`\\]') {
        Write-Warning "New CVM nutanix password contains one or more of the invalid characters: \ | ``"
        $ncnfail = $true
    } if ($newcvmnutanix -notmatch '[!#%()*+,-./:;?@[\]_~ {$}^&=<>]') {
        Write-Warning "New CVM nutanix password missing a special character: !#%()*+,-./:;?@[]_~ {$}^&=<>"
        $ncnfail = $true
    } if ($newcvmnutanix -cmatch '[^\x20-\x7F]') {
        Write-Warning "New CVM nutanix password contains non-standard ASCII character(s)."
        $ncnfail = $true
    }
    # Check for a character that repeats consecutively more than twice
    $chararray = $newcvmnutanix.ToCharArray()
    $chararraylen = $chararray.Length
    $repeatingchar = $false
    foreach ($char in $chararray) {
        $pos1, $pos2, $pos3, $charcount = 0, 1, 2, 2
        while ($charcount -le ($chararraylen-1)) {
            if (($chararray[$pos1] -ceq $char) -and ($chararray[$pos2] -ceq $char) -and ($chararray[$pos3] -ceq $char)) {
                $repeatingchar = $true
                $ncnfail = $true
            }
            $pos1++; $pos2++; $pos3++; $charcount++
        }
    }
    if ($repeatingchar -eq $true) {
        Write-Warning "New CVM nutanix password contains a character that is repeating consecutively more than twice."
    }
    # Throw error and exit script if any of the above fail
    if ($ncnfail -eq $true) {
        Write-Error "New CVM nutanix password does not meet complexity requirements."
        Exit
    }
}
# Verify New Files nutanix password complexity requirements
#   Verified Files 4.0: https://portal.nutanix.com/page/documents/details?targetId=Files-v4_0:fil-file-server-change-fsvm-password-t.html
if (($f -eq $true) -or ($a -eq $true)) {
    $nfnfail = $false
    if ($newfilesnutanix.Length -lt 8) {
        Write-Warning "New Files nutanix password is shorter than 8 characters."
        $nfnfail = $true
    } if ($newfilesnutanix.Length -gt 39) {
        Write-Warning "New Files nutanix password is longer than 39 characters."
        $nfnfail = $true
    } if ($newfilesnutanix -cnotmatch '[a-z]') {
        Write-Warning "New Files nutanix password is missing a lowercase letter."
        $nfnfail = $true
    } if ($newfilesnutanix -cnotmatch '[A-Z]') {
        Write-Warning "New Files nutanix password is missing an uppercase letter."
        $nfnfail = $true
    } if ($newfilesnutanix -notmatch '[0-9]') {
        Write-Warning "New Files nutanix password is missing a number."
        $nfnfail = $true
    } if ($newfilesnutanix -match '''') { #This is just annoying to deal with coding wise
        Write-Warning "New Files nutanix password contains invalid character: '"
        $nfnfail = $true
    } if ($newfilesnutanix -match '\"') { #This is just annoying to deal with coding wise
        Write-Warning "New Files nutanix password contains invalid character: `""
        $nfnfail = $true
    } if ($newfilesnutanix -match '[|`\\]') {
        Write-Warning "New Files nutanix password contains one or more of the invalid characters: \ | ``"
        $nfnfail = $true
    } if ($newfilesnutanix -notmatch '[!#%()*+,-./:;?@[\]_~ {$}^&=<>]') {
        Write-Warning "New Files nutanix password missing a special character: !#%()*+,-./:;?@[]_~ {$}^&=<>"
        $nfnfail = $true
    } if ($newfilesnutanix -cmatch '[^\x20-\x7F]') {
        Write-Warning "New Files nutanix password contains non-standard ASCII character(s)."
        $nfnfail = $true
    }
    # Throw error and exit script if any of the above fail
    if ($nfnfail -eq $true) {
        Write-Error "New Files nutanix password does not meet complexity requirements."
        Exit
    }
}
# Verify new host root password complexity requirements. Does not take into account "high-security requirements".
#   Verified AHV & AOS 6.0: https://portal.nutanix.com/page/documents/details?targetId=AHV-Admin-Guide-v6_0:ahv-ahv-host-password-requirments-c.html
#   ESXi 7.0: https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.vsphere.security.doc/GUID-DC96FFDB-F5F2-43EC-8C73-05ACDAE6BE43.html
if (($hr -eq $true) -or ($a -eq $true)) {
    $hostrfail= $false
    if ($newhostr.Length -lt 8) {
        Write-Warning "New host root password is shorter than 8 characters."
        $hostrfail = $true
    } if ($newhostr.Length -gt 39) {
        Write-Warning "New host root password is longer than 39 characters."
        $hostrfail = $true
    } if ($newhostr -cnotmatch '[a-z]') {
        Write-Warning "New host root password is missing a lowercase letter."
        $hostrfail = $true
    } if ($newhostr -cnotmatch '[A-Z]') {
        Write-Warning "New host root password is missing an uppercase letter."
        $hostrfail = $true
    } if ($newhostr -notmatch '[0-9]') {
        Write-Warning "New host root password is missing a number."
        $hostrfail = $true
    } if ($newhostr -match '''') { #This is just annoying to deal with coding wise
        Write-Warning "New host root password contains invalid character: '"
        $hostrfail = $true
    } if ($newhostr -match '\"') { #This is just annoying to deal with coding wise
        Write-Warning "New host root password contains invalid character: `""
        $hostrfail = $true
    } if ($newhostr -match '`') {
        Write-Warning "New host root password contains invalid character: ``"
        $hostrfail = $true
    } if ($newhostr -match '\\') {
        Write-Warning "New host root password contains invalid character: \"
        $hostrfail = $true
    } if ($newhostr -match '\${') {
        Write-Warning "New host root password contains invalid character combination of $`{"
        $hostrfail = $true
    } if ($newhostr -match '\$\(') {
        Write-Warning "New host root password contains invalid character combination of `$("
        $hostrfail = $true
    } if ($newhostr -notmatch '[!#%()*+,-./:;|?@[\]_~ {$}^&=<>]') {
        Write-Warning "New host root password missing a special character: !#%()*+,-./:;|?@[]_~ \{$}^&=<>"
        $hostrfail = $true
    } if ($newhostr -cmatch '[^\x20-\x7F]') {
        Write-Warning "New host root password contains non-standard ASCII character(s)."
        $hostrfail = $true
    }
    # Check for a character that repeats consecutively more than three times
    $chararray = $newhostr.ToCharArray()
    $chararraylen = $chararray.Length
    $repeatingchar = $false
    foreach ($char in $chararray) {
        $pos1, $pos2, $pos3, $pos4, $charcount = 0, 1, 2, 3, 3
        while ($charcount -le ($chararraylen-1)) {
            if (($chararray[$pos1] -ceq $char) -and ($chararray[$pos2] -ceq $char) -and ($chararray[$pos3] -ceq $char) -and ($chararray[$pos4] -ceq $char)) {
                $repeatingchar = $true
                $hostrfail = $true
            }
            $pos1++; $pos2++; $pos3++; $pos4++; $charcount++
        }
    }
    if ($repeatingchar -eq $true) {
        Write-Warning "New host root password contains a character that is repeating consecutively more than three times."
    }
    if ($hostrfail -eq $true) {
        Write-Error "New host root password does not meet complexity requirements."
        Exit
    }
}
# Verify new host admin password complexity requirements. Does not take into account "high-security requirements". AHV Only.
if (($ha -eq $true) -or ($a -eq $true)) {
    $hostafail= $false
    if ($newhosta.Length -lt 8) {
        Write-Warning "New host admin password is shorter than 8 characters."
        $hostafail = $true
    } if ($newhosta.Length -gt 39) {
        Write-Warning "New host admin password is longer than 39 characters."
        $hostafail = $true
    } if ($newhosta -cnotmatch '[a-z]') {
        Write-Warning "New host admin password is missing a lowercase letter."
        $hostafail = $true
    } if ($newhosta -cnotmatch '[A-Z]') {
        Write-Warning "New host admin password is missing an uppercase letter."
        $hostafail = $true
    } if ($newhosta -notmatch '[0-9]') {
        Write-Warning "New host admin password is missing a number."
        $hostafail = $true
    } if ($newhosta -match '''') { #This is just annoying to deal with coding wise
        Write-Warning "New host admin password contains invalid character: '"
        $hostafail = $true
    } if ($newhosta -match '\"') { #This is just annoying to deal with coding wise
        Write-Warning "New host admin password contains invalid character: `""
        $hostafail = $true
    } if ($newhosta -match '`') {
        Write-Warning "New host admin password contains invalid character: ``"
        $hostafail = $true
    } if ($newhosta -match '\\') {
        Write-Warning "New host admin password contains invalid character: \"
        $hostafail = $true
    } if ($newhosta -match '\${') {
        Write-Warning "New host admin password contains invalid character combination of $`{"
        $hostafail = $true
    } if ($newhosta -match '\$\(') {
        Write-Warning "New host admin password contains invalid character combination of `$("
        $hostafail = $true
    } if ($newhosta -notmatch '[!#%()*+,-./:;|?@[\]_~ {$}^&=<>]') {
        Write-Warning "New host admin password missing a special character: !#%()*+,-./:;|?@[]_~ \{$}^&=<>"
        $hostafail = $true
    } if ($newhosta -cmatch '[^\x20-\x7F]') {
        Write-Warning "New host admin password contains non-standard ASCII character(s)."
        $hostafail = $true
    }
    # Check for a character that repeats consecutively more than three times
    $chararray = $newhosta.ToCharArray()
    $chararraylen = $chararray.Length
    $repeatingchar = $false
    foreach ($char in $chararray) {
        $pos1, $pos2, $pos3, $pos4, $charcount = 0, 1, 2, 3, 3
        while ($charcount -le ($chararraylen-1)) {
            if (($chararray[$pos1] -ceq $char) -and ($chararray[$pos2] -ceq $char) -and ($chararray[$pos3] -ceq $char) -and ($chararray[$pos4] -ceq $char)) {
                $repeatingchar = $true
                $hostafail = $true
            }
            $pos1++; $pos2++; $pos3++; $pos4++; $charcount++
        }
    }
    if ($repeatingchar -eq $true) {
        Write-Warning "New host admin password contains a character that is repeating consecutively more than three times."
    }
    if ($hostafail -eq $true) {
        Write-Error "New host admin password does not meet complexity requirements."
        Exit
    }
}
# Verify new host nutanix password complexity requirements. Does not take into account "high-security requirements". AHV Only.
if (($hn -eq $true) -or ($a -eq $true)) {
    $hostnfail= $false
    if ($newhostn.Length -lt 8) {
        Write-Warning "New host nutanix password is shorter than 8 characters."
        $hostnfail = $true
    } if ($newhostn.Length -gt 39) {
        Write-Warning "New host nutanix password is longer than 39 characters."
        $hostnfail = $true
    } if ($newhostn -cnotmatch '[a-z]') {
        Write-Warning "New host nutanix password is missing a lowercase letter."
        $hostnfail = $true
    } if ($newhostn -cnotmatch '[A-Z]') {
        Write-Warning "New host nutanix password is missing an uppercase letter."
        $hostnfail = $true
    } if ($newhostn -notmatch '[0-9]') {
        Write-Warning "New host nutanix password is missing a number."
        $hostnfail = $true
    } if ($newhostn -match '''') { #This is just annoying to deal with coding wise
        Write-Warning "New host nutanix password contains invalid character: '"
        $hostnfail = $true
    } if ($newhostn -match '\"') { #This is just annoying to deal with coding wise
        Write-Warning "New host nutanix password contains invalid character: `""
        $hostnfail = $true
    } if ($newhostn -match '`') {
        Write-Warning "New host nutanix password contains invalid character: ``"
        $hostnfail = $true
    } if ($newhostn -match '\\') {
        Write-Warning "New host nutanix password contains invalid character: \"
        $hostnfail = $true
    } if ($newhostn -match '\${') {
        Write-Warning "New host nutanix password contains invalid character combination of $`{"
        $hostnfail = $true
    } if ($newhostn -match '\$\(') {
        Write-Warning "New host nutanix password contains invalid character combination of `$("
        $hostnfail = $true
    } if ($newhostn -notmatch '[!#%()*+,-./:;|?@[\]_~ {$}^&=<>]') {
        Write-Warning "New host nutanix password missing a special character: !#%()*+,-./:;|?@[]_~ \{$}^&=<>"
        $hostnfail = $true
    } if ($newhostn -cmatch '[^\x20-\x7F]') {
        Write-Warning "New host nutanix password contains non-standard ASCII character(s)."
        $hostnfail = $true
    }
    # Check for a character that repeats consecutively more than three times
    $chararray = $newhostn.ToCharArray()
    $chararraylen = $chararray.Length
    $repeatingchar = $false
    foreach ($char in $chararray) {
        $pos1, $pos2, $pos3, $pos4, $charcount = 0, 1, 2, 3, 3
        while ($charcount -le ($chararraylen-1)) {
            if (($chararray[$pos1] -ceq $char) -and ($chararray[$pos2] -ceq $char) -and ($chararray[$pos3] -ceq $char) -and ($chararray[$pos4] -ceq $char)) {
                $repeatingchar = $true
                $hostnfail = $true
            }
            $pos1++; $pos2++; $pos3++; $pos4++; $charcount++
        }
    }
    if ($repeatingchar -eq $true) {
        Write-Warning "New host nutanix password contains a character that is repeating consecutively more than three times."
    }
    if ($hostnfail -eq $true) {
        Write-Error "New host nutanix password does not meet complexity requirements."
        Exit
    }
}
# Verify new IPMI password complexity requirements (this is attempting to cover the requirements across hardware vendors)
#       TESTING CONFIRMED ON: NX & Dell
#       NX: https://portal.nutanix.com/page/documents/details?targetId=Hardware-Admin-Guide:har-password-change-ipmi-t.html
#       Dell: https://www.dell.com/support/manuals/en-us/idrac9-lifecycle-controller-v5.x-series/idrac9_5.00.00.00_ug/recommended-characters-in-user-names-and-passwords?guid=guid-2255506d-6aa3-446c-909b-4fffb41c4cfb&lang=en-us
#           Verified requirements for iDRAC 7/8/9
#       HPE: https://support.hpe.com/hpesc/public/docDisplay?docId=a00105236en_us
#           Verified requirements for iLO 4/5
#       Lenovo: https://thinksystem.lenovofiles.com/help/topic/7Y98/bmc_user_guide.pdf
#       Inspur: Could not find documentation.
#       Fujitsu: Could not find documentation.
if (($i -eq $true) -or ($a -eq $true)) {
    $newipmifail = $false
    if ($newipmi.Length -lt 8) {
        Write-Host $newipmi
        Write-Warning "New IPMI password is shorter than 8 characters."
        $newipmifail = $true
    } if ($newipmi.Length -gt 20) {
        Write-Warning "New IPMI password is longer than 20 characters."
        $newipmifail = $true
    } if ($newipmi -cnotmatch '[a-z]') {
        Write-Warning "New IPMI password is missing a lowercase letter."
        $newipmifail = $true
    } if ($newipmi -cnotmatch '[A-Z]') {
        Write-Warning "New IPMI password is missing an uppercase letter."
        $newipmifail = $true
    } if ($newipmi -notmatch '[0-9]') {
        Write-Warning "New IPMI password is missing a number."
        $newipmifail = $true
    } if ($newipmi -match '''') { #This is just annoying to deal with coding wise
        Write-Warning "New IPMI password contains invalid character: '"
        $newipmifail = $true
    } if ($newipmi -match '\"') { #This is just annoying to deal with coding wise
        Write-Warning "New IPMI password contains invalid character: `""
        $newipmifail = $true
    } if ($newipmi[0] -eq '-') {
        Write-Warning "New IPMI password cannot begin with a dash."
        $newipmifail = $true
    } if ($newipmi -match ' ') {
        Write-Warning "New IPMI password contains a space. This is invalid."
        $newipmifail = $true
    } if ($newipmi -match '[()`|:\\$&<>]') {
        Write-Warning "New IPMI password contains one or more invalid special characters:  < > & $ ( ) `` | : \"
        $newipmifail = $true
    } if ($newipmi -notmatch '[!#%*+,-./;?@[\]_~{}^=]') {
        Write-Warning "New IPMI password missing a special character: !#%*+,-./;?@[]_~{}^="
        $newipmifail = $true
    } if ($newipmi -cmatch '[^\x20-\x7F]') {
        Write-Warning "New IPMI password contains non-standard ASCII character(s)."
        $newipmifail = $true
    }
    # Throw error and exit script if any of the above fail
    if ($newipmifail -eq $true) {
        Write-Error "New IPMI password does not meet complexity requirements."
        Exit
    }
}
# Verify new Prism admin password complexity requirements
#   Verified AOS 6.0: https://portal.nutanix.com/page/documents/details?targetId=Web-Console-Guide-Prism-v6_0:wc-login-wc-t.html
# Currently doesn't check for dictionary words
if (($p -eq $true) -or ($a -eq $true)) {
    $npafail = $false
    if ($newprismadmin.Length -lt 8) {
        Write-Warning "New Prism admin password is shorter than 8 characters."
        $npafail = $true
    } if ($newprismadmin.Length -gt 199) {
        Write-Warning "New Prism admin password is longer than 199 characters."
        $npafail = $true
    } if ($newprismadmin -cnotmatch '[a-z]') {
        Write-Warning "New Prism admin password is missing a lowercase letter."
        $npafail = $true
    } if ($newprismadmin -cnotmatch '[A-Z]') {
        Write-Warning "New Prism admin password is missing an uppercase letter."
        $npafail = $true
    } if ($newprismadmin -notmatch '[0-9]') {
        Write-Warning "New Prism admin password is missing a number."
        $npafail = $true
    } if ($newprismadmin -match '''') { #This is just annoying to deal with coding wise
        Write-Warning "New Prism admin password contains invalid character: '"
        $npafail = $true
    } if ($newprismadmin -match '\"') { #This is just annoying to deal with coding wise
        Write-Warning "New Prism admin password contains invalid character: `""
        $npafail = $true
    } if ($newprismadmin -notmatch '[!#%()*+,-./\\:;|`?@\[\]_~ {$}^&=<>]') {
        Write-Warning "New Prism admin password missing a special character: !#%()*+,-./\:;|``?@[]_~ \{$}^&=<>"
        $npafail = $true
    } if ($newprismadmin -cmatch '[^\x20-\x7F]') {
        Write-Warning "New Prism admin password contains non-standard ASCII character(s)."
        $npafail = $true
    }
    # Check for a character that repeats consecutively more than twice
    $chararray = $newprismadmin.ToCharArray()
    $chararraylen = $chararray.Length
    $repeatingchar = $false
    foreach ($char in $chararray) {
        $pos1, $pos2, $pos3, $charcount = 0, 1, 2, 2
        while ($charcount -le ($chararraylen-1)) {
            if (($chararray[$pos1] -ceq $char) -and ($chararray[$pos2] -ceq $char) -and ($chararray[$pos3] -ceq $char)) {
                $repeatingchar = $true
                $npafail = $true
            }
            $pos1++; $pos2++; $pos3++; $charcount++
        }
    }
    if ($repeatingchar -eq $true) {
        Write-Warning "New Prism admin password contains a character that is repeating consecutively more than twice."
    }
    # Throw error and exit script if any of the above fail
    if ($npafail -eq $true) {
        Write-Error "New Prism admin password does not meet complexity requirements."
        Exit
    }
}
############################## End Region - Passwords ############################
##################################################################################


##################################################################################
############################## Region - Functions ################################
# Function to get cluster (PE) list from Prism Central
function pcClusterList ($pcnameip) {
    # Create the HTTP Basic Authorization header
    $pair = "admin:" + $pcadmin
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $basicAuthValue = "Basic $base64"

    # Setup the request headers
    $headers = @{
        'Accept' = 'application/json'
        'Authorization' = $basicAuthValue
    }

    # Invoke REST method for cluster list
    $uriPC = "https://" + $pcnameip + ":9440/api/nutanix/v3/clusters/list"
    $payload = '{"kind":"cluster","offset":0,"length":1}'
    try {
        $pcCluList = (Invoke-RestMethod -Uri $uriPC -Headers $headers -Method POST -Body $payload -ContentType 'application/json' -TimeoutSec 60)
        Return $pcCluList
    } Catch {
        Write-PSFMessage -Level Critical "Error connecting to $pcnameip"
        Write-PSFMessage -Level Warning $Error[0]
    }
}

# Generic function to pass commands to a SSH session
#    Courtesy: Taylor Siegrist
function Invoke-CvmCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][String] $ip,
        [Parameter(Mandatory = $true)][String] $cmd,
        [switch] $stream,
        [switch] $summary,
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )
    # Try running the command 3 times before timing out
    $flag = $true
    $attempt = 1
    Do {
        try {
            $maxSeconds = 240
            $count=$fulloutput = $null
            $sshConn = New-SSHSession -ComputerName $ip -Credential $Credential -AcceptKey
            $SSHStream = New-SSHShellStream -SSHSession $sshconn
            $SSHStream.WriteLine($cmd)
            #setup loop
            $TimeStart = Get-Date
            $TimeEnd = $timeStart.AddSeconds($maxSeconds)
            Do { 
                $TimeNow = Get-Date
                $out = $SSHStream.read()
                if ($out) {
                    if ($stream) {
                        Write-Host $out
                    }
                    $fulloutput = $fulloutput + $out
                    if (([regex]::Matches($fulloutput, "\bsudo\sshutdown\s-P\snow\b")).count -ge 1) {
                        start-sleep 60
                        $count = 2
                    } else {
                        $count = ([regex]::Matches($fulloutput, "nutanix@NTNX.+-.+CVM:*")).count
                    }
                }
            }
            Until ($TimeNow -ge $TimeEnd -or $count -ge 2) 
            $SSHStream.Close()
            Remove-SSHSession $sshConn | Out-null
            $flag = $false
        } catch {
            if ($attempt -gt 3) {
                Write-PSFMessage -Level Warning "[ERROR] Failed to run command on $($ip) after 3 tries"
                $flag = $false
                break
            } else {
                Write-PSFMessage -Level Critical $Error[0]
                Write-PSFMessage -Level Output "Re-trying connection to $($ip)"
                $attempt++
            }
        }
    } While ($flag -eq $true)
    # Get command output and return it
    if ($summary) {
        $summaryOutput = ($fulloutput -split "nutanix@NTNX.+-.+CVM:*")[1]
        Write-PSFMessage -Level Output "$summaryOutput"
        return $summaryOutput       
    } else {
        return $fulloutput
    }
}
# Function to get the currently installed hypervisor on the cluster
function getHyperVer ($ip,$crds) {
    Write-PSFMessage -Level Output "Determining hypervisor version for $ip"
    $cmd = "ncli host ls | grep `"Version`" | head -1"
    $hyp = Invoke-CvmCommand $ip $cmd $crds
    $hyp = ($hyp -split "nutanix@NTNX.+-.+CVM:*")[1]
    Write-PSFMessage -Level Output $hyp
    if ($hyp -match "Nutanix") {
        $hypver = "AHV"
    } elseif ($hyp -match "VMware") {
        $hypver = "VMware"
    }
    return $hypver
}
# Function to change Host root password
function chgHostRoot ($ip,$hypervisor,$crds,$nhrpwd) {
    if ($hypervisor -eq "AHV") {
        Write-PSFMessage -Level Output "Changing host root password for $ip"
        # Need to add escape character on $ for bash
        $nhrpwd = $nhrpwd.replace("$","\$")
        $cmd = "hostssh `'echo -e `"root:$nhrpwd`" | chpasswd`'"
        $output = (Invoke-CvmCommand $ip $cmd $crds)
        $output = ($output -split "nutanix@NTNX.+-.+CVM:*")[1]
        Write-PSFMessage -Level Output ($output -replace '\"root:.+\"',"`"root:XXXXXXXX`"")
    } elseif ($hypervisor -eq "VMware") {
        Write-PSFMessage -Level Output "Changing host root password for $ip"
        # Need to add escape character on $ for bash
        $nhrpwd = $nhrpwd.replace("$","\$")
        $cmd = "hostssh `'echo -e `"$nhrpwd`" | passwd root --stdin`'"
        $output = (Invoke-CvmCommand $ip $cmd $crds)
        $output = ($output -split "nutanix@NTNX.+-.+CVM:*")[1]
        Write-PSFMessage -Level Output ($output -replace '-e \".+\"',"-e `"XXXXXXXX`"")
    }
}
# Function to change Host admin password
function chgHostAdmin ($ip,$crds,$nhapwd) {
    Write-PSFMessage -Level Output "Changing host admin password for $ip"
    # Need to add escape character on $ for bash
    $nhapwd = $nhapwd.replace("$","\$")
    $cmd = "hostssh `'echo -e `"admin:$nhapwd`" | chpasswd`'"
    $output = (Invoke-CvmCommand $ip $cmd $crds)
    $output = ($output -split "nutanix@NTNX.+-.+CVM:*")[1]
    Write-PSFMessage -Level Output ($output -replace '\"admin:.+\"',"`"admin:XXXXXXXX`"")
}
# Function to change Host nutanix password
function chgHostNutanix ($ip,$crds,$nhnpwd) {
    Write-PSFMessage -Level Output "Changing host nutanix password for $ip"
    # Need to add escape character on $ for bash
    $nhnpwd = $nhnpwd.replace("$","\$")
    $cmd = "hostssh `'echo -e `"nutanix:$nhnpwd`" | chpasswd`'"
    $output = (Invoke-CvmCommand $ip $cmd $crds)
    $output = ($output -split "nutanix@NTNX.+-.+CVM:*")[1]
    Write-PSFMessage -Level Output ($output -replace '\"nutanix:.+\"',"`"nutanix:XXXXXXXX`"")
}
# Function to change IPMI password
function chgIPMI ($ip,$hypervisor,$crds,$nipwd) {
    if ($hypervisor -eq "AHV") {
        Write-PSFMessage -Level Output "Changing IPMI password for $ip"
        # Need to add escape character on ! # ; for bash
        $nipwd = $nipwd.replace("!","\!").replace("#","\#").replace(";","\;")
        #$cmd = "hostssh `"ipmitool user list | grep -e root -e `'ADMIN `'; ipmitool user set password \`$(ipmitool user list 1 | grep -e root -e `'ADMIN `' | awk `'{print \`$1}`') $nipwd 20`""
        $cmd = "hostssh `"ipmitool user set password 2 $nipwd 20`""
        $output = (Invoke-CvmCommand $ip $cmd $crds)
        $output = ($output -split "nutanix@NTNX.+-.+CVM:*")[1]
        Write-PSFMessage -Level Output ($output -replace '2 .+ 2',"2 XXXXXXXX 2")
    } elseif ($hypervisor -eq "VMware") {
        Write-PSFMessage -Level Output "Changing IPMI password for $ip"
        # Need to add escape character on ! # ; for bash
        $nipwd = $nipwd.replace("!","\!").replace("#","\#").replace(";","\;")
        #$cmd = "hostssh `"/ipmitool user list | grep -e root -e `'ADMIN `'; /ipmitool user set password \`$(/ipmitool user list 1 | grep -e root -e `'ADMIN `' | awk `'{print \`$1}`') $nipwd 20`""
        $cmd = "hostssh `"/ipmitool user set password 2 $nipwd 20`""
        $output = (Invoke-CvmCommand $ip $cmd $crds)
        $output = ($output -split "nutanix@NTNX.+-.+CVM:*")[1]
        Write-PSFMessage -Level Output ($output -replace '2 .+ 2',"2 XXXXXXXX 2")
    }
}
# Function to change Prism admin password
function chgPrismAdmin ($ip,$crds,$npapwd) {
    Write-PSFMessage -Level Output "Changing Prism admin password for $ip"
    $cmd = "ncli user reset-password user-name=`'admin`' password=`'$npapwd`'"
    $output = (Invoke-CvmCommand $ip $cmd $crds)
    $output = ($output -split "nutanix@NTNX.+-.+CVM:*")[1]
    Write-PSFMessage -Level Output ($output -replace 'password=''.+''',"password=`'XXXXXXXX`'")
}
# Function to change CVM nutanix password
function chgCVMNutanix ($ip,$crds,$cvmoldpwd,$ncpwd) {
    Write-PSFMessage -Level Output "Changing CVM nutanix password for $ip"
    $cmd = "echo $`'$cvmoldpwd\n$ncpwd\n$ncpwd`' | passwd"
    $output = (Invoke-CvmCommand $ip $cmd $crds)
    $output = ($output -split "nutanix@NTNX.+-.+CVM:*")[1]
    Write-PSFMessage -Level Output ($output -replace '''.+\\n.+\\n.+''',"`'XXXXXXXX\nXXXXXXXX\nXXXXXXXX`'")
}
# Function to check to see if Files exists on the cluster
function getFSList ($ip,$crds) {
    Write-PSFMessage -Level Output "Determining if Nutanix Files is used on $ip"
    $cmd = "ncli fs ls"
    $output = (Invoke-CvmCommand $ip $cmd $crds)
    $output = ($output -split "nutanix@NTNX.+-.+CVM:*")[1]
    Return $output
}
# Function to change Files nutanix password
function chgFilesNutanix ($ip,$crds,$fslist,$filesoldpwd,$nfnpwd) {
    foreach ($fs in ($fslist -split "Uuid                      : ")) {
        if (($fs -match "ncli fs ls") -eq $false) {
            # Get Fileserver name
            $fs -match "Name                      : (?<fsname>.+)" | Out-null
            $fsname = $matches['fsname']
            Write-PSFMessage -Level Output "Changing Files nutanix password for $fsname"
            # Get one of the internal fileserver IPs
            $fs -match "Nvm IP Addresses          : .+, (?<fsip>.+)" | Out-null
            $fsip = $matches['fsip']
            # Change password for Files nutanix
            $cmd = "ssh $fsip hostname; echo $`'$filesoldpwd\n$nfnpwd\n$nfnpwd`' | passwd; exit"
            $output = (Invoke-CvmCommand $ip $cmd $crds)
            $output = ($output -split "nutanix@NTNX.+-.+FSVM:*")[1]
            Write-PSFMessage -Level Output ($output -replace '''.+\\n.+\\n.+''',"`'XXXXXXXX\nXXXXXXXX\nXXXXXXXX`'")
        }
    }
}
############################## End Region - Functions ############################
##################################################################################


##################################################################################
############################## Region - Body #####################################
# Prism Central section
if ($null -ne $pclist) {
    foreach ($pc in $pclist) {
        # Get cluster list from PC
        Write-PSFMessage -Level Output "Obtaining cluster list from Prism Central: $pc"
        $pcCluList = pcClusterList $pc
        foreach ($peclu in $pcCluList.entities) {
            # We only want clusters and not PC, which is filtered by AOS under service_list
            if ($peclu.status.resources.config.service_list -eq "AOS") {
                # Gather IP of the cluster and build credentials for ssh commands
                $pe = $peclu.status.resources.network.external_ip
                $secpasswd = ConvertTo-SecureString "$cvmnutanix" -AsPlainText -Force
                $Credentials = New-Object System.Management.Automation.PSCredential("nutanix", $secpasswd)
                # Determine hypervisor version if we are changing the hypervisor or IPMI password
                if (($hr -eq $true) -or ($ha -eq $true) -or ($hn -eq $true) -or ($i -eq $true) -or ($a -eq $true)) {
                    $hypver = getHyperVer $pe $Credentials
                }
                # Change host root password
                if (($hr -eq $true) -or ($a -eq $true)) {
                    chgHostRoot $pe $hypver $Credentials $newhostr
                }
                # (AHV Only) Change host admin password
                if ((($ha -eq $true) -or ($a -eq $true)) -and ($hypver -eq "AHV")) {
                    chgHostAdmin $pe $Credentials $newhosta
                } elseif ((($ha -eq $true) -or ($a -eq $true)) -and ($hypver -eq "VMware")) {
                    Write-PSFMessage -Level Output "Hosts are VMware. Skipping host admin password change for $pe."
                }
                # (AHV Only) Change host nutanix password
                if ((($hn -eq $true) -or ($a -eq $true)) -and ($hypver -eq "AHV")) {
                    chgHostNutanix $pe $Credentials $newhostn
                } elseif ((($hn -eq $true) -or ($a -eq $true)) -and ($hypver -eq "VMware")) {
                    Write-PSFMessage -Level Output "Hosts are VMware. Skipping host nutanix password change for $pe."
                }
                # Change IPMI password password
                if (($i -eq $true) -or ($a -eq $true)) {
                    chgIPMI $pe $hypver $Credentials $newipmi
                }
                # Change Prism admin password
                if (($p -eq $true) -or ($a -eq $true)) {
                    chgPrismAdmin $pe $Credentials $newprismadmin
                }
                # Determine if Nutanix Files is being used and change the password
                if (($f -eq $true) -or ($a -eq $true)) {
                    $fslist = getFSList $pe $Credentials
                    if ($fslist -match "\[None\]") {
                        Write-PSFMessage -Level Output "Skipping Nutanix Files password change as no Fileserver exists on $pe"
                    } else {
                        chgFilesNutanix $pe $Credentials $fslist $filesnutanix $newfilesnutanix
                    }
                }
                # Change CVM password (Should be last one to run)
                if (($c -eq $true) -or ($a -eq $true)) {
                    chgCVMNutanix $pe $Credentials $cvmnutanix $newcvmnutanix
                }
            }
        }
    }
}

# Prism Element section
if ($null -ne $pelist) {
    foreach ($pe in $pelist) {
        # Build credentials for ssh commands
        $secpasswd = ConvertTo-SecureString "$cvmnutanix" -AsPlainText -Force
        $Credentials = New-Object System.Management.Automation.PSCredential("nutanix", $secpasswd)
        # Determine hypervisor version if we are changing the hypervisor or IPMI password
        if (($hr -eq $true) -or ($ha -eq $true) -or ($hn -eq $true) -or ($i -eq $true) -or ($a -eq $true)) {
            $hypver = getHyperVer $pe $Credentials
        }
        # Change host root password
        if (($hr -eq $true) -or ($a -eq $true)) {
            chgHostRoot $pe $hypver $Credentials $newhostr
        }
        # (AHV Only) Change host admin password
        if ((($ha -eq $true) -or ($a -eq $true)) -and ($hypver -eq "AHV")) {
            chgHostAdmin $pe $Credentials $newhosta
        } elseif ((($ha -eq $true) -or ($a -eq $true)) -and ($hypver -eq "VMware")) {
            Write-PSFMessage -Level Output "Hosts are VMware. Skipping host admin password change for $pe."
        }
        # (AHV Only) Change host nutanix password
        if ((($hn -eq $true) -or ($a -eq $true)) -and ($hypver -eq "AHV")) {
            chgHostNutanix $pe $Credentials $newhostn
        } elseif ((($hn -eq $true) -or ($a -eq $true)) -and ($hypver -eq "VMware")) {
            Write-PSFMessage -Level Output "Hosts are VMware. Skipping host nutanix password change for $pe."
        }
        # Change IPMI password password
        if (($i -eq $true) -or ($a -eq $true)) {
            chgIPMI $pe $hypver $Credentials $newipmi
        }
        # Change Prism admin password
        if (($p -eq $true) -or ($a -eq $true)) {
            chgPrismAdmin $pe $Credentials $newprismadmin
        }
        # Determine if Nutanix Files is being used and change the password
        if (($f -eq $true) -or ($a -eq $true)) {
            $fslist = getFSList $pe $Credentials
            if ($fslist -match "\[None\]") {
                Write-PSFMessage -Level Output "Skipping Nutanix Files password change as no Fileserver exists on $pe"
            } else {
                chgFilesNutanix $pe $Credentials $fslist $filesnutanix $newfilesnutanix
            }
        }
        # Change CVM password (Should be last one to run)
        if (($c -eq $true) -or ($a -eq $true)) {
            chgCVMNutanix $pe $Credentials $cvmnutanix $newcvmnutanix
        }
    }
}
############################## End Region - Body #################################
##################################################################################