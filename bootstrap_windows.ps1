function DeGZip-File{
    Param(
        $infile,
        $outfile = ($infile -replace '\.gz$','')
        )

    $input = New-Object System.IO.FileStream $inFile, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
    $output = New-Object System.IO.FileStream $outFile, ([IO.FileMode]::Create), ([IO.FileAccess]::Write), ([IO.FileShare]::None)
    $gzipStream = New-Object System.IO.Compression.GzipStream $input, ([IO.Compression.CompressionMode]::Decompress)

    $buffer = New-Object byte[](1024)
    while($true){
        $read = $gzipstream.Read($buffer, 0, 1024)
        if ($read -le 0){break}
        $output.Write($buffer, 0, $read)
        }

    $gzipStream.Close()
    $output.Close()
    $input.Close()
}


$url = "https://github.com/sl1pm4t/terraform-provider-kubernetes/releases/download/v1.0.7-custom/terraform-provider-kubernetes_windows-amd64.gz"
#Github and other sites now require tls1.2 without this line the script will fail with an SSL error.
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

Write-Host "Downloading Traefik Binary from $url" -foregroundcolor Green

$outfile = $PSScriptRoot+"/terraform-provider-kubernetes.gz"

Invoke-WebRequest -Uri $url -OutFile $outfile -UseBasicParsing
DeGZIP-File "$PSScriptRoot/terraform-provider-kubernetes.gz" "$PSScriptRoot/terraform-provider-kubernetes.exe" 

Write-Host "Download complete" -foregroundcolor Green

