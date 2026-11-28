using namespace System.Security.Cryptography
using namespace System.Security.Cryptography.X509Certificates
param([Parameter(Mandatory)][string]$Directory)
$ErrorActionPreference = 'Stop'
$server = New-Item -ItemType Directory -Path (Join-Path $Directory 'server')
$client = New-Item -ItemType Directory -Path (Join-Path $Directory 'client')
$null = New-Item -ItemType Directory -Path (Join-Path $Directory 'public')
$now = [DateTimeOffset]::UtcNow.AddMinutes(-5)
$end = $now.AddDays(1)
function New-Authority([string]$Name) {
    $key = [RSA]::Create(3072)
    $req = [CertificateRequest]::new("CN=$Name",$key,[HashAlgorithmName]::SHA256,[RSASignaturePadding]::Pkcs1)
    $req.CertificateExtensions.Add([X509BasicConstraintsExtension]::new($true,$false,0,$true))
    $req.CertificateExtensions.Add([X509KeyUsageExtension]::new([X509KeyUsageFlags]::KeyCertSign -bor [X509KeyUsageFlags]::CrlSign,$true))
    $cert = $req.CreateSelfSigned($now,$end)
    return @{ Key=$key; Cert=$cert }
}
function New-Leaf($Authority,[string]$Name,[string]$Folder,[string]$File,[bool]$Server,[bool]$Client) {
    $key = [RSA]::Create(3072)
    try {
        $req = [CertificateRequest]::new("CN=$Name",$key,[HashAlgorithmName]::SHA256,[RSASignaturePadding]::Pkcs1)
        $req.CertificateExtensions.Add([X509BasicConstraintsExtension]::new($false,$false,0,$true))
        $req.CertificateExtensions.Add([X509KeyUsageExtension]::new([X509KeyUsageFlags]::DigitalSignature -bor [X509KeyUsageFlags]::KeyEncipherment,$true))
        $oids = [OidCollection]::new()
        if ($Server) {
            $null = $oids.Add([Oid]::new('1.3.6.1.5.5.7.3.1'))
            $san = [SubjectAlternativeNameBuilder]::new()
            $san.AddDnsName('temporal')
            $san.AddIpAddress([Net.IPAddress]::Loopback)
            $req.CertificateExtensions.Add($san.Build())
        }
        if ($Client) { $null = $oids.Add([Oid]::new('1.3.6.1.5.5.7.3.2')) }
        $req.CertificateExtensions.Add([X509EnhancedKeyUsageExtension]::new($oids,$true))
        $serial = [RandomNumberGenerator]::GetBytes(16)
        $serial[0] = $serial[0] -band 127
        $leaf = $req.Create($Authority.Cert,$now,$end,$serial)
        try {
            [IO.File]::WriteAllText((Join-Path $Folder "$File.crt"),$leaf.ExportCertificatePem())
            [IO.File]::WriteAllText((Join-Path $Folder "$File.key"),$key.ExportPkcs8PrivateKeyPem())
        } finally { $leaf.Dispose() }
    } finally { $key.Dispose() }
}
$ca = New-Authority 'H2 ephemeral authority'
$bad = New-Authority 'H2 untrusted authority'
try {
    foreach ($folder in @($server.FullName,$client.FullName)) {
        [IO.File]::WriteAllText((Join-Path $folder 'ca.crt'),$ca.Cert.ExportCertificatePem())
    }
    [IO.File]::WriteAllText((Join-Path $client.FullName 'wrong-ca.crt'),$bad.Cert.ExportCertificatePem())
    New-Leaf $ca 'temporal' $server.FullName 'internode' $true $true
    New-Leaf $ca 'temporal' $server.FullName 'frontend' $true $false
    New-Leaf $ca 'h2-client' $client.FullName 'client' $false $true
    New-Leaf $bad 'untrusted-client' $client.FullName 'untrusted' $false $true
} finally {
    foreach ($authority in @($ca,$bad)) { $authority.Cert.Dispose(); $authority.Key.Dispose() }
}
