# Para gerar e reiniciar a stack automaticamente, rode:
# powershell.exe -ExecutionPolicy Bypass -File .\certs\generate-certs.ps1 -RestartCompose

# Executar somente a geração de certificados:
# powershell.exe -ExecutionPolicy Bypass -File .\certs\generate-certs.ps1

[CmdletBinding()]
param(
    [switch]$RestartCompose
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Resolve-Executable {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string[]]$Candidates = @()
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "Executável '$Name' não encontrado. Instale-o ou adicione-o ao PATH."
}

function Invoke-External {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "O comando '$FilePath' falhou com código $LASTEXITCODE."
    }
}

function Import-DotEnv {
    param([Parameter(Mandatory)][string]$Path)

    foreach ($rawLine in Get-Content -LiteralPath $Path -Encoding UTF8) {
        $line = $rawLine.Trim()

        if (-not $line -or $line.StartsWith('#')) {
            continue
        }

        $separator = $line.IndexOf('=')
        if ($separator -lt 1) {
            continue
        }

        $name = $line.Substring(0, $separator).Trim()
        $value = $line.Substring($separator + 1).Trim()

        if (
            ($value.StartsWith('"') -and $value.EndsWith('"')) -or
            ($value.StartsWith("'") -and $value.EndsWith("'"))
        ) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        [Environment]::SetEnvironmentVariable($name, $value, 'Process')
    }
}

function Find-ProjectRoot {
    param([Parameter(Mandatory)][string]$StartDirectory)

    $current = (Resolve-Path -LiteralPath $StartDirectory).Path

    for ($i = 0; $i -lt 5; $i++) {
        $compose = Join-Path $current 'docker-compose.yml'
        if (Test-Path -LiteralPath $compose -PathType Leaf) {
            return $current
        }

        $parent = Split-Path -Parent $current
        if (-not $parent -or $parent -eq $current) {
            break
        }
        $current = $parent
    }

    throw "Não foi possível localizar docker-compose.yml a partir de '$StartDirectory'."
}

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Find-ProjectRoot -StartDirectory $scriptDirectory
$certsDirectory = Join-Path $projectRoot 'certs'
$envPath = Join-Path $projectRoot '.env'
$envExamplePath = Join-Path $projectRoot '.env.example'
$envCreated = $false

Write-Host "Projeto: $projectRoot" -ForegroundColor DarkGray
Write-Host "Certificados: $certsDirectory" -ForegroundColor DarkGray

if (-not (Test-Path -LiteralPath $certsDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $certsDirectory | Out-Null
}

Write-Step 'Preparando o arquivo .env'

if (-not (Test-Path -LiteralPath $envPath -PathType Leaf)) {
    if (-not (Test-Path -LiteralPath $envExamplePath -PathType Leaf)) {
        throw "Nem '.env' nem '.env.example' foram encontrados na raiz do projeto."
    }

    Copy-Item -LiteralPath $envExamplePath -Destination $envPath
    $envCreated = $true
    Write-Warning "O arquivo .env não existia e foi criado a partir de .env.example. Revise os segredos antes de subir a stack."
}

Import-DotEnv -Path $envPath

$password = [Environment]::GetEnvironmentVariable('TRUST_STORE_PASSWORD', 'Process')
if ([string]::IsNullOrWhiteSpace($password)) {
    throw 'TRUST_STORE_PASSWORD não foi definida no .env.'
}
if ($password.Length -lt 6) {
    throw 'TRUST_STORE_PASSWORD deve possuir pelo menos 6 caracteres.'
}

Write-Step 'Localizando OpenSSL e keytool'

$openssl = Resolve-Executable -Name 'openssl' -Candidates @(
    "$env:ProgramFiles\Git\usr\bin\openssl.exe",
    "${env:ProgramFiles(x86)}\Git\usr\bin\openssl.exe"
)

$keytoolCandidates = @()
if ($env:JAVA_HOME) {
    $keytoolCandidates += (Join-Path $env:JAVA_HOME 'bin\keytool.exe')
}
$keytool = Resolve-Executable -Name 'keytool' -Candidates $keytoolCandidates

Write-Host "OpenSSL: $openssl" -ForegroundColor DarkGray
Write-Host "keytool: $keytool" -ForegroundColor DarkGray

Write-Step 'Normalizando os nomes dos arquivos SAN'

$sanMappings = [ordered]@{
    'example_san_kong.cnf'             = 'san_kong.cnf'
    'example_san_patient-document.cnf' = 'san_patient-document.cnf'
    'example_san_keycloak.cnf'         = 'san_keycloak.cnf'
}

foreach ($entry in $sanMappings.GetEnumerator()) {
    $source = Join-Path $certsDirectory $entry.Key
    $target = Join-Path $certsDirectory $entry.Value

    if (Test-Path -LiteralPath $target -PathType Leaf) {
        Write-Host "Mantido: $($entry.Value)" -ForegroundColor DarkGray
        continue
    }

    if (Test-Path -LiteralPath $source -PathType Leaf) {
        Copy-Item -LiteralPath $source -Destination $target -Force
        Write-Host "Criado: $($entry.Value) a partir de $($entry.Key)" -ForegroundColor Green
        continue
    }

    throw "Arquivo SAN não encontrado: '$($entry.Value)' nem '$($entry.Key)' existem em '$certsDirectory'."
}

Write-Step 'Limpando certificados anteriormente gerados'

$generatedDirectories = @('ca', 'kong', 'patient-document', 'keycloak')
foreach ($directoryName in $generatedDirectories) {
    $directoryPath = Join-Path $certsDirectory $directoryName
    if (Test-Path -LiteralPath $directoryPath) {
        Remove-Item -LiteralPath $directoryPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $directoryPath | Out-Null
}

$caDirectory = Join-Path $certsDirectory 'ca'
$caCrt = Join-Path $caDirectory 'ca.crt'
$caKey = Join-Path $caDirectory 'ca.key'
$caSerial = Join-Path $caDirectory 'ca.srl'
$caTruststore = Join-Path $caDirectory 'ca-truststore.p12'

Write-Step 'Gerando a Autoridade Certificadora local'

Invoke-External -FilePath $openssl -Arguments @(
    'genrsa',
    '-out', $caKey,
    '2048'
)

Invoke-External -FilePath $openssl -Arguments @(
    'req',
    '-x509',
    '-new',
    '-nodes',
    '-key', $caKey,
    '-sha256',
    '-days', '1024',
    '-out', $caCrt,
    '-subj', '/C=BR/ST=SaoPaulo/L=SaoPaulo/O=MeuHistoricoSaude/OU=IT/CN=meu-historico-saude-ca'
)

Write-Step 'Gerando o truststore da CA'

Invoke-External -FilePath $keytool -Arguments @(
    '-importcert',
    '-trustcacerts',
    '-file', $caCrt,
    '-keystore', $caTruststore,
    '-storetype', 'PKCS12',
    '-storepass', $password,
    '-alias', 'meu-historico-saude-ca',
    '-noprompt'
)

$services = @('kong', 'patient-document', 'keycloak')

foreach ($service in $services) {
    Write-Step "Gerando certificado para $service"

    $sanConfig = Join-Path $certsDirectory "san_$service.cnf"
    $targetDirectory = Join-Path $certsDirectory $service
    $privateKey = Join-Path $targetDirectory "$service.key"
    $csr = Join-Path $targetDirectory "$service.csr"
    $certificate = Join-Path $targetDirectory "$service.crt"
    $pkcs12 = Join-Path $targetDirectory "$service.p12"

    Copy-Item -LiteralPath $caCrt -Destination (Join-Path $targetDirectory 'ca.crt') -Force
    Copy-Item -LiteralPath $caTruststore -Destination (Join-Path $targetDirectory 'ca-truststore.p12') -Force

    Invoke-External -FilePath $openssl -Arguments @(
        'genrsa',
        '-out', $privateKey,
        '2048'
    )

    Invoke-External -FilePath $openssl -Arguments @(
        'req',
        '-new',
        '-key', $privateKey,
        '-out', $csr,
        '-config', $sanConfig
    )

    $signArguments = @(
        'x509',
        '-req',
        '-in', $csr,
        '-CA', $caCrt,
        '-CAkey', $caKey,
        '-out', $certificate,
        '-days', '365',
        '-sha256',
        '-extfile', $sanConfig,
        '-extensions', 'v3_req'
    )

    if (Test-Path -LiteralPath $caSerial -PathType Leaf) {
        $signArguments += @('-CAserial', $caSerial)
    }
    else {
        $signArguments += '-CAcreateserial'
    }

    Invoke-External -FilePath $openssl -Arguments $signArguments

    Invoke-External -FilePath $openssl -Arguments @(
        'pkcs12',
        '-export',
        '-in', $certificate,
        '-inkey', $privateKey,
        '-certfile', $caCrt,
        '-out', $pkcs12,
        '-name', $service,
        '-passout', "pass:$password"
    )

    Write-Host "Gerado: $pkcs12" -ForegroundColor Green
}

Write-Step 'Validando o PKCS12 do Patient Document Service'

$patientPkcs12 = Join-Path $certsDirectory 'patient-document\patient-document.p12'
Invoke-External -FilePath $keytool -Arguments @(
    '-list',
    '-keystore', $patientPkcs12,
    '-storetype', 'PKCS12',
    '-storepass', $password
)

Write-Host "`nCertificados gerados com sucesso em '$certsDirectory'." -ForegroundColor Green

if ($RestartCompose) {
    Write-Step 'Validando e reiniciando o Docker Compose'

    if ($envCreated) {
        throw 'O .env acabou de ser criado. Revise os segredos antes de usar -RestartCompose.'
    }

    $geminiKey = [Environment]::GetEnvironmentVariable('GEMINI_API_KEY', 'Process')
    if ([string]::IsNullOrWhiteSpace($geminiKey) -or $geminiKey -match 'MY\.\.\.API\.\.\.KEY') {
        throw 'GEMINI_API_KEY ainda não contém uma chave válida. Os certificados foram gerados, mas a stack não será reiniciada.'
    }

    $docker = Resolve-Executable -Name 'docker'

    Push-Location $projectRoot
    try {
        Invoke-External -FilePath $docker -Arguments @('compose', 'config', '--quiet')
        Invoke-External -FilePath $docker -Arguments @('compose', 'down')
        Invoke-External -FilePath $docker -Arguments @('compose', 'up', '-d', '--force-recreate')
        Invoke-External -FilePath $docker -Arguments @('compose', 'ps')
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Host "`nPara reiniciar a stack automaticamente, execute:" -ForegroundColor Yellow
    Write-Host ".\certs\generate-certs.ps1 -RestartCompose" -ForegroundColor Yellow
}
