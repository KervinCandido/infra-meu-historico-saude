[CmdletBinding()]
param(
    [ValidateRange(30, 900)]
    [int]$TimeoutSeconds = 300
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (
    Get-Variable `
        -Name PSNativeCommandUseErrorActionPreference `
        -ErrorAction SilentlyContinue
) {
    $PSNativeCommandUseErrorActionPreference = $false
}

function Get-RepositoryRoot {
    $root =
        (git rev-parse --show-toplevel).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao localizar a raiz do repositório."
    }

    if (
        [string]::IsNullOrWhiteSpace(
            $root
        )
    ) {
        throw "A raiz do repositório está vazia."
    }

    return $root
}

function Wait-HttpResponse {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $true)]
        [int[]]$ExpectedStatusCodes,

        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [DateTimeOffset]$Deadline,

        [string]$Accept = "application/json"
    )

    $lastStatus = $null
    $lastError = $null

    do {
        try {
            $response =
                Invoke-WebRequest `
                    -Uri $Uri `
                    -Method Get `
                    -Headers @{
                        Accept = $Accept
                    } `
                    -SkipCertificateCheck `
                    -SkipHttpErrorCheck `
                    -TimeoutSec 10

            $lastStatus =
                [int]$response.StatusCode

            if (
                $lastStatus -in
                $ExpectedStatusCodes
            ) {
                Write-Host (
                    $Description +
                    ": HTTP " +
                    $lastStatus
                )

                return $response
            }
        }
        catch {
            $lastError =
                $_.Exception.Message
        }

        Start-Sleep -Seconds 3
    }
    while (
        [DateTimeOffset]::UtcNow -lt $Deadline
    )

    if ($null -ne $lastStatus) {
        throw (
            $Description +
            " não retornou o status esperado. " +
            "Último status: " +
            $lastStatus
        )
    }

    throw (
        $Description +
        " não ficou disponível. Último erro: " +
        $lastError
    )
}

$repositoryRoot =
    Get-RepositoryRoot

Set-Location $repositoryRoot

$ensureDemoUsersPath =
    Join-Path `
        -Path $repositoryRoot `
        -ChildPath "scripts/Ensure-DemoUsers.ps1"

$demoEnvironmentPath =
    Join-Path `
        -Path $repositoryRoot `
        -ChildPath ".env.demo.local"

if (
    -not (
        Test-Path `
            -LiteralPath $ensureDemoUsersPath `
            -PathType Leaf
    )
) {
    throw (
        "Reconciliador não encontrado: " +
        $ensureDemoUsersPath
    )
}

if (
    -not (
        Test-Path `
            -LiteralPath $demoEnvironmentPath `
            -PathType Leaf
    )
) {
    throw (
        "Arquivo local de demonstração não encontrado: " +
        $demoEnvironmentPath
    )
}

docker compose config --quiet

if ($LASTEXITCODE -ne 0) {
    throw "O docker-compose.yml está inválido."
}

Write-Host "===== INICIANDO INFRAESTRUTURA ====="

docker compose up -d

if ($LASTEXITCODE -ne 0) {
    throw "Falha ao iniciar a infraestrutura."
}

$deadline =
    [DateTimeOffset]::UtcNow.AddSeconds(
        $TimeoutSeconds
    )

Write-Host ""
Write-Host "===== AGUARDANDO KEYCLOAK ====="

[void](
    Wait-HttpResponse `
        -Uri (
            "https://localhost:8443/realms/" +
            "meu-historico-saude/" +
            ".well-known/openid-configuration"
        ) `
        -ExpectedStatusCodes @(200) `
        -Description "Keycloak" `
        -Deadline $deadline
)

Write-Host ""
Write-Host "===== RECONCILIANDO USUÁRIOS DEMO ====="

& $ensureDemoUsersPath

if (-not $?) {
    throw (
        "Falha ao reconciliar os usuários " +
        "de demonstração."
    )
}

Write-Host ""
Write-Host "===== VALIDANDO API ====="

$openApiResponse =
    Wait-HttpResponse `
        -Uri "https://localhost:8443/v3/api-docs" `
        -ExpectedStatusCodes @(200) `
        -Description "OpenAPI" `
        -Deadline $deadline

$swaggerResponse =
    Wait-HttpResponse `
        -Uri (
            "https://localhost:8443/" +
            "swagger-ui/index.html"
        ) `
        -ExpectedStatusCodes @(200) `
        -Description "Swagger UI" `
        -Deadline $deadline `
        -Accept "text/html"

$swaggerContentType =
    [string]$swaggerResponse.Headers[
        "Content-Type"
    ]

if (
    -not $swaggerContentType.Contains(
        "text/html"
    )
) {
    throw (
        "Swagger UI retornou Content-Type " +
        "inesperado: " +
        $swaggerContentType
    )
}

try {
    $openApi =
        $openApiResponse.Content |
        ConvertFrom-Json `
            -Depth 100
}
catch {
    throw "O OpenAPI não contém JSON válido."
}

$grantCollectionPath =
    "/patients/{patientId}/access-grants"

$grantItemPath =
    (
        "/patients/{patientId}/access-grants/" +
        "{grantId}"
    )

$grantCollectionProperty =
    $openApi.paths.PSObject.Properties |
    Where-Object {
        $_.Name -ceq $grantCollectionPath
    } |
    Select-Object -First 1

if ($null -eq $grantCollectionProperty) {
    throw (
        "Endpoint de concessões ausente no OpenAPI: " +
        $grantCollectionPath
    )
}

$grantCollectionOperations =
    @(
        $grantCollectionProperty.Value.
            PSObject.Properties.Name
    )

foreach (
    $requiredOperation in @(
        "get"
        "post"
    )
) {
    if (
        $requiredOperation -notin
        $grantCollectionOperations
    ) {
        throw (
            "Operação ausente no endpoint de concessões: " +
            $requiredOperation
        )
    }
}

$grantItemProperty =
    $openApi.paths.PSObject.Properties |
    Where-Object {
        $_.Name -ceq $grantItemPath
    } |
    Select-Object -First 1

if ($null -eq $grantItemProperty) {
    throw (
        "Endpoint de revogação ausente no OpenAPI: " +
        $grantItemPath
    )
}

if (
    "delete" -notin
    @(
        $grantItemProperty.Value.
            PSObject.Properties.Name
    )
) {
    throw (
        "Operação DELETE de revogação ausente " +
        "no OpenAPI."
    )
}

Write-Host "Endpoints de compartilhamento: OK"

Write-Host ""
Write-Host "===== VALIDANDO SEGURANÇA ====="

[void](
    Wait-HttpResponse `
        -Uri "https://localhost:8443/patients" `
        -ExpectedStatusCodes @(401) `
        -Description "GET /patients sem token" `
        -Deadline $deadline
)

[void](
    Wait-HttpResponse `
        -Uri (
            "https://localhost:8443/patients/" +
            "00000000-0000-0000-0000-000000000000/" +
            "access-grants"
        ) `
        -ExpectedStatusCodes @(401) `
        -Description (
            "GET access-grants sem token"
        ) `
        -Deadline $deadline
)

Write-Host ""
Write-Host "===== CONTAINERS ====="

docker compose ps

if ($LASTEXITCODE -ne 0) {
    throw "Falha ao exibir os containers."
}

Write-Host ""
Write-Host "===== RESULTADO FINAL ====="
Write-Host "Infraestrutura iniciada: OK"
Write-Host "Keycloak disponível: OK"
Write-Host "Usuários demo reconciliados: OK"
Write-Host "OpenAPI disponível: OK"
Write-Host "Swagger UI disponível: OK"
Write-Host "Endpoints de compartilhamento: OK"
Write-Host "Proteção sem token: OK"
Write-Host "Ambiente pronto para a demonstração."