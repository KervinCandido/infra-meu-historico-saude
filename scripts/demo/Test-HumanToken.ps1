[CmdletBinding()]
param(
    [string]$BaseUrl = "https://localhost:8443"
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw "Este script requer PowerShell 7 ou superior."
}

function ConvertFrom-Base64Url {
    param(
        [Parameter(Mandatory)]
        [string]$Value
    )

    $normalized =
        $Value.Replace("-", "+").Replace("_", "/")

    switch ($normalized.Length % 4) {
        0 {
        }

        2 {
            $normalized += "=="
        }

        3 {
            $normalized += "="
        }

        default {
            throw "Segmento Base64URL inválido."
        }
    }

    $bytes =
        [Convert]::FromBase64String(
            $normalized
        )

    return [Text.Encoding]::UTF8.GetString(
        $bytes
    )
}

$token = $null

try {
    $token =
        (
            [string](
                Get-Clipboard -Raw
            )
        ).Trim()

    if ([string]::IsNullOrWhiteSpace($token)) {
        throw (
            "A área de transferência não contém " +
            "um access token."
        )
    }

    $parts =
        $token.Split(".")

    if ($parts.Count -ne 3) {
        throw (
            "O conteúdo copiado não possui " +
            "o formato de um JWT."
        )
    }

    $payloadJson =
        ConvertFrom-Base64Url `
            -Value $parts[1]

    $payload =
        $payloadJson |
        ConvertFrom-Json

    $currentEpoch =
        [DateTimeOffset]::UtcNow.
            ToUnixTimeSeconds()

    if (
        $null -eq $payload.exp -or
        [long]$payload.exp -le $currentEpoch
    ) {
        throw "O access token está expirado."
    }

    $expectedUsername =
        "demo.patient"

    if (
        [string]$payload.preferred_username -cne
        $expectedUsername
    ) {
        throw (
            "Username inesperado no token: " +
            $payload.preferred_username
        )
    }

    $expectedClientId =
        "patient-portal"

    $tokenClientId = $null

    if (
        $payload.PSObject.Properties.Name -contains
        "azp"
    ) {
        $tokenClientId =
            [string]$payload.azp
    }
    elseif (
        $payload.PSObject.Properties.Name -contains
        "client_id"
    ) {
        $tokenClientId =
            [string]$payload.client_id
    }

    if ($tokenClientId -cne $expectedClientId) {
        throw (
            "Cliente inesperado no token: " +
            $tokenClientId
        )
    }

    $expectedIssuerSuffix =
        "/realms/meu-historico-saude"

    $issuer =
        [string]$payload.iss

    if (
        [string]::IsNullOrWhiteSpace($issuer) -or
        -not $issuer.EndsWith(
            $expectedIssuerSuffix,
            [StringComparison]::Ordinal
        )
    ) {
        throw (
            "Issuer inesperado no token: " +
            $issuer
        )
    }

    $tokenScopes =
        @(
            (
                [string]$payload.scope
            ).Split(
                " ",
                [StringSplitOptions]::
                    RemoveEmptyEntries
            )
        )

    $requiredScopes =
        @(
            "patients:read"
            "patients:write"
            "documents:read"
            "documents:write"
            "documents:file:read"
            "access-grants:read"
            "access-grants:write"
        )

    $missingScopes =
        @(
            $requiredScopes |
                Where-Object {
                    $_ -notin $tokenScopes
                }
        )

    if ($missingScopes.Count -gt 0) {
        throw (
            "Scopes humanos ausentes: " +
            (
                $missingScopes -join ", "
            )
        )
    }

    $forbiddenScope =
        "documents:ai-result:write"

    if ($forbiddenScope -in $tokenScopes) {
        throw (
            "O token humano contém o scope técnico " +
            "proibido: " +
            $forbiddenScope
        )
    }

    $repositoryRoot =
        Split-Path `
            -Parent `
            (
                Split-Path `
                    -Parent `
                    $PSScriptRoot
            )

    $realmPath =
        Join-Path `
            $repositoryRoot `
            (
                "docker/keycloak/" +
                "meu-historico-saude-realm.json"
            )

    $realm =
        Get-Content `
            -LiteralPath $realmPath `
            -Raw |
        ConvertFrom-Json

    $audienceScope =
        @($realm.clientScopes) |
        Where-Object {
            $_.name -eq
            "patient-document-api-audience"
        } |
        Select-Object -First 1

    if ($null -eq $audienceScope) {
        throw (
            "O client scope de audience não foi " +
            "encontrado no realm JSON."
        )
    }

    $expectedAudience =
        @(
            $audienceScope.protocolMappers |
                ForEach-Object {
                    $property =
                        $_.config.PSObject.Properties |
                        Where-Object {
                            $_.Name -eq
                            "included.client.audience"
                        } |
                        Select-Object -First 1

                    if ($null -ne $property) {
                        [string]$property.Value
                    }
                } |
                Where-Object {
                    -not [string]::IsNullOrWhiteSpace($_)
                }
        ) |
        Select-Object -First 1

    if (
        [string]::IsNullOrWhiteSpace(
            $expectedAudience
        )
    ) {
        throw (
            "A audience esperada não foi encontrada " +
            "no mapper do realm."
        )
    }

    $tokenAudiences =
        @($payload.aud)

    if ($expectedAudience -notin $tokenAudiences) {
        throw (
            "Audience esperada ausente no token: " +
            $expectedAudience
        )
    }

    $expiration =
        [DateTimeOffset]::
            FromUnixTimeSeconds(
                [long]$payload.exp
            ).
            ToLocalTime()

    Write-Host "===== TOKEN HUMANO ====="
    Write-Host (
        "Username:  " +
        $payload.preferred_username
    )
    Write-Host "Client ID: $tokenClientId"
    Write-Host (
        "Audience:  " +
        (
            $tokenAudiences -join ", "
        )
    )
    Write-Host (
        "Expiração: " +
        $expiration.ToString(
            "yyyy-MM-dd HH:mm:ss zzz"
        )
    )

    Write-Host "Scopes:"

    foreach (
        $scope in (
            $tokenScopes |
                Sort-Object
        )
    ) {
        Write-Host "  - $scope"
    }

    Write-Host ""
    Write-Host "Identidade humana: OK"
    Write-Host "Scopes humanos: OK"
    Write-Host "Scope técnico de IA ausente: OK"
    Write-Host "Audience da API: OK"

    Write-Host "`n===== ENDPOINT PROTEGIDO ====="

    $headers = @{
        Authorization = "Bearer $token"
        Accept        = "application/json"
    }

    $response =
        Invoke-WebRequest `
            -Uri (
                $BaseUrl.TrimEnd("/") +
                "/patients"
            ) `
            -Method Get `
            -Headers $headers `
            -SkipCertificateCheck

    if ($response.StatusCode -ne 200) {
        throw (
            "GET /patients retornou HTTP " +
            $response.StatusCode
        )
    }

    Write-Host (
        "GET /patients: HTTP " +
        $response.StatusCode
    )

    Write-Host "Autorização humana na API: OK"
    Write-Host ""
    Write-Host "HUMAN TOKEN READY"
}
finally {
    $token = $null
    $payloadJson = $null
    $payload = $null

    try {
        Set-Clipboard -Value ""

        Write-Host (
            "Access token removido da área " +
            "de transferência."
        )
    }
    catch {
        Write-Warning (
            "Não foi possível limpar a área " +
            "de transferência."
        )
    }
}
