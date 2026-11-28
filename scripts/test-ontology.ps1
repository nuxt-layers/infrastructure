[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidatePattern('^[a-zA-Z0-9./:_-]+@sha256:[a-f0-9]{64}$')][string]$JavaImage,
    [Parameter(Mandatory)][string]$JenaArchive,
    [Parameter(Mandatory)][ValidatePattern('^[a-fA-F0-9]{128}$')][string]$JenaSha512
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$archive = (Resolve-Path -LiteralPath $JenaArchive).Path
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA512).Hash -ne $JenaSha512) { throw 'Jena archive SHA512 mismatch.' }
$source = (Resolve-Path (Join-Path $PSScriptRoot '../tests/ontology')).Path
# Reviewed JDK Linux image must provide Java source launcher, tar and timeout.
& docker run --rm --network none --read-only --cap-drop ALL --security-opt no-new-privileges --user 65534:65534 --memory 768m --cpus 1 --pids-limit 96 --tmpfs '/tmp:rw,nosuid,nodev,size=384m,mode=1777' -v "${archive}:/input/jena.tar.gz:ro" -v "${source}:/fixture:ro" --entrypoint /bin/sh $JavaImage -ec 'mkdir /tmp/jena; timeout 45s tar -xzf /input/jena.tar.gz -C /tmp/jena --strip-components=1; exec timeout 90s java -Xmx256m -Djava.io.tmpdir=/tmp -cp "/tmp/jena/lib/*" /fixture/Probe.java'
if ($LASTEXITCODE -ne 0) { throw 'Ontology acceptance failed.' }
