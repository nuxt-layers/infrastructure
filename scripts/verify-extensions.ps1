[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not (Test-Path (Join-Path $root '.env'))) { throw 'Missing .env.' }
$compose = @('--env-file', (Join-Path $root '.env'), '-f', (Join-Path $root 'compose/compose.yaml'), '-f', (Join-Path $root 'compose/compose.dev.yaml'))
$sql = @'
SELECT CASE
  WHEN current_setting('server_version_num')::integer / 10000 = 18
   AND (SELECT count(*) FROM pg_extension WHERE extname IN ('age', 'pg_textsearch', 'pgmq')) = 3
   AND position('pg_textsearch' in current_setting('shared_preload_libraries')) > 0
   AND position('pg_cron' in current_setting('shared_preload_libraries')) > 0
   AND NOT ('age' = ANY (regexp_split_to_array(current_setting('shared_preload_libraries'), '\s*,\s*')))
  THEN 'PASS'
  ELSE 'FAIL'
END;
'@
$result = $sql | & docker compose @compose exec -T postgres-app sh -c 'psql -X -A -t -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
if ($LASTEXITCODE -ne 0 -or ($result | Out-String).Trim() -ne 'PASS') { throw "Application extension verification failed: $result" }
$cronResult = 'SELECT CASE WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = ''pg_cron'') THEN ''PASS'' ELSE ''FAIL'' END;' |
    & docker compose @compose exec -T postgres-app sh -c 'psql -X -A -t -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres'
if ($LASTEXITCODE -ne 0 -or ($cronResult | Out-String).Trim() -ne 'PASS') { throw "pg_cron verification failed: $cronResult" }
Write-Host 'Extension presence and preload verification passed. Graph, search and queue behaviour tests remain outstanding.'
