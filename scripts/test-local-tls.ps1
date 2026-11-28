[CmdletBinding()]
param([string]$TraefikImage)
$ErrorActionPreference = 'Stop'
$folder = Join-Path ([IO.Path]::GetTempPath()) ('nl-local-tls-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $folder | Out-Null
$keys = [System.Collections.Generic.List[System.IDisposable]]::new()
try {
    function New-Ca([string]$name) {
        $key = [System.Security.Cryptography.RSA]::Create(3072)
        $keys.Add($key)
        $request = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new("CN=$name",$key,[System.Security.Cryptography.HashAlgorithmName]::SHA256,[System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
        $request.CertificateExtensions.Add([System.Security.Cryptography.X509Certificates.X509BasicConstraintsExtension]::new($true,$false,0,$true))
        $request.CertificateExtensions.Add([System.Security.Cryptography.X509Certificates.X509KeyUsageExtension]::new([System.Security.Cryptography.X509Certificates.X509KeyUsageFlags]'KeyCertSign, CrlSign',$true))
        $cert = $request.CreateSelfSigned([DateTimeOffset]::UtcNow.AddMinutes(-5),[DateTimeOffset]::UtcNow.AddDays(2))
        $keys.Add($cert)
        return $cert
    }
    $ca = New-Ca 'Infrastructure fixture CA'
    $wrong = New-Ca 'Untrusted fixture CA'
    [IO.File]::WriteAllText((Join-Path $folder 'ca.pem'),$ca.ExportCertificatePem())
    [IO.File]::WriteAllText((Join-Path $folder 'wrong.pem'),$wrong.ExportCertificatePem())
    foreach ($name in @('site-a.fixture.test','site-b.fixture.test')) {
        $key = [System.Security.Cryptography.RSA]::Create(2048)
        $keys.Add($key)
        $request = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new("CN=$name",$key,[System.Security.Cryptography.HashAlgorithmName]::SHA256,[System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
        $san = [System.Security.Cryptography.X509Certificates.SubjectAlternativeNameBuilder]::new()
        $san.AddDnsName($name)
        $request.CertificateExtensions.Add($san.Build())
        $request.CertificateExtensions.Add([System.Security.Cryptography.X509Certificates.X509BasicConstraintsExtension]::new($false,$false,0,$true))
        $request.CertificateExtensions.Add([System.Security.Cryptography.X509Certificates.X509KeyUsageExtension]::new([System.Security.Cryptography.X509Certificates.X509KeyUsageFlags]'DigitalSignature, KeyEncipherment',$true))
        $oids = [System.Security.Cryptography.OidCollection]::new()
        [void]$oids.Add([System.Security.Cryptography.Oid]::new('1.3.6.1.5.5.7.3.1'))
        $request.CertificateExtensions.Add([System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]::new($oids,$false))
        $serial = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16)
        $cert = $request.Create($ca,[DateTimeOffset]::UtcNow.AddMinutes(-1),[DateTimeOffset]::UtcNow.AddDays(1),$serial)
        $keys.Add($cert)
        [IO.File]::WriteAllText((Join-Path $folder "$name.crt"),$cert.ExportCertificatePem())
        [IO.File]::WriteAllText((Join-Path $folder "$name.key"),$key.ExportPkcs8PrivateKeyPem())
    }
    & node (Join-Path $PSScriptRoot '../tests/site-hosting/acceptance.mjs') $folder
    if ($LASTEXITCODE -ne 0) { throw 'Local TLS fixture failed.' }
    if ($TraefikImage) { & (Join-Path $PSScriptRoot 'invoke-proxy-fixture.ps1') -TraefikImage $TraefikImage -CertificateFolder $folder }
} finally {
    foreach ($item in $keys) { $item.Dispose() }
    Remove-Item -LiteralPath $folder -Recurse -Force
}
