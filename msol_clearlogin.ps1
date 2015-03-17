cls
Import-Module MSOnline
$stage = ""
$dev = ""
# Uncomment if using clearlogin-stage 
#$stage = "-stage"
#$dev = ""
#uncomment if using dev
#$stage = "-dev"
#$dev = ":3000"
Function Get-FileName()
{
 $initialDirectory = [Environment+SpecialFolder]::Desktop
 [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
 Out-Null

 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 $OpenFileDialog.initialDirectory = $initialDirectory
 $OpenFileDialog.filter = "All files (*.*)| *.*"
 $OpenFileDialog.ShowDialog() | Out-Null
 $OpenFileDialog.filename
} #end function Get-FileName

Write-Host "Checking if logged in..."
Get-MsolDomain -ErrorAction SilentlyContinue | out-null
if($?)
{
    Write-Host "Connected!"
}
else
{
    Write-Host "Connection not found..."
    Write-Host "Connecting..."
    $Creds = Get-Credential
    Connect-MsolService -Credential $Creds
    if($?)
    {
        Write-Host "Connected!"
    }
    else
    {
        Write-Host "Error logging in"
        Exit
    }
}
$idpSub = Read-Host 'Please enter the idP subdomain on clearlogin.com: '
$passiveLogin = "https://"+$idpSub+".clearlogin"+$stage+".com"+$dev+"/apps/office365-1/login"
$logout = "https://"+$idpSub+".clearlogin"+$stage+".com"+$dev+"/apps/logout"
$issuer = "httsp://"+$idpSub+".clearlogin"+$stage+".com"+$dev+"/"
Write-Host "Please find the public cert file you downloaded from https://admin.clearlogin.com"
$certPath = Get-FileName
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certPath)
$certData = [system.convert]::tobase64string($cert.rawdata)
$msdomain = Read-Host 'Please enter your Office365 domain.'
Set-MsolDomainAuthentication -Authentication Federated -DomainName $msdomain -FederationBrandName $msdomain -IssuerUri $issuer -LogOffUri $logout -PassiveLogOnUri $passiveLogin -SigningCertificate $certData -PreferredAuthenticationProtocol Samlp
