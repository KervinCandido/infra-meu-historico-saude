[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (
    Get-Variable `
        -Name PSNativeCommandUseErrorActionPreference `
        -ErrorAction SilentlyContinue
) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$KeycloakService = "keycloak-service"
$KongService = "kong-service"
$TargetRealm = "meu-historico-saude"

$KeycloakServer =
    "https://keycloak-service:8443"

$KongP12Path =
    "/tmp/mhs-kcadm-client.p12"

$KongP12PasswordPath =
    "/tmp/mhs-kcadm-client-password.txt"

$KeycloakP12Path =
    "/tmp/mhs-kcadm-client.p12"

$SecretsContainerPath =
    "/tmp/mhs-demo-secrets.txt"

$WrapperContainerPath =
    "/tmp/mhs-kcadm-wrapper.sh"

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

function Read-DotEnvFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [hashtable]$Destination
    )

    if (
        -not (
            Test-Path `
                -LiteralPath $Path `
                -PathType Leaf
        )
    ) {
        throw (
            "Arquivo de ambiente não encontrado: " +
            $Path
        )
    }

    foreach (
        $line in
        [System.IO.File]::ReadAllLines($Path)
    ) {
        $trimmed =
            $line.Trim()

        if (
            [string]::IsNullOrWhiteSpace(
                $trimmed
            ) -or
            $trimmed.StartsWith("#")
        ) {
            continue
        }

        $match =
            [regex]::Match(
                $trimmed,
                (
                    "^(?:export\s+)?" +
                    "([A-Za-z_][A-Za-z0-9_]*)" +
                    "\s*=\s*(.*)$"
                )
            )

        if (-not $match.Success) {
            continue
        }

        $name =
            $match.Groups[1].Value

        $value =
            $match.Groups[2].Value.Trim()

        if (
            $value.Length -ge 2 -and
            (
                (
                    $value.StartsWith('"') -and
                    $value.EndsWith('"')
                ) -or
                (
                    $value.StartsWith("'") -and
                    $value.EndsWith("'")
                )
            )
        ) {
            $value =
                $value.Substring(
                    1,
                    $value.Length - 2
                )
        }

        $Destination[$name] =
            $value
    }
}

function Assert-NoLineBreak {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    if (
        $Value.Contains("`r") -or
        $Value.Contains("`n")
    ) {
        throw (
            "A variável contém quebra de linha: " +
            $Name
        )
    }
}

function Get-ComposeContainerId {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Service
    )

    $containerId =
        (
            docker compose ps `
                --quiet `
                $Service
        ).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw (
            "Falha ao localizar o container de: " +
            $Service
        )
    }

    if (
        [string]::IsNullOrWhiteSpace(
            $containerId
        )
    ) {
        throw (
            "O serviço não está ativo: " +
            $Service
        )
    }

    $running =
        (
            docker inspect `
                --format "{{.State.Running}}" `
                $containerId
        ).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw (
            "Falha ao consultar o estado de: " +
            $Service
        )
    }

    if ($running -ne "true") {
        throw (
            "O serviço não está em execução: " +
            $Service
        )
    }

    return $containerId
}

function Wait-Keycloak {
    $deadline =
        [DateTimeOffset]::UtcNow.AddMinutes(2)

    $ready = $false
    $lastStatus = $null

    do {
        try {
            $response =
                Invoke-WebRequest `
                    -Uri (
                        "https://localhost:8443/realms/" +
                        $TargetRealm +
                        "/.well-known/openid-configuration"
                    ) `
                    -Method Get `
                    -SkipCertificateCheck `
                    -SkipHttpErrorCheck

            $lastStatus =
                [int]$response.StatusCode

            if ($lastStatus -eq 200) {
                $ready = $true
                break
            }
        }
        catch {
            $lastStatus = $null
        }

        Start-Sleep -Seconds 3
    }
    while (
        [DateTimeOffset]::UtcNow -lt $deadline
    )

    if (-not $ready) {
        throw (
            "O Keycloak não ficou disponível. " +
            "Último status: " +
            $lastStatus
        )
    }
}

function Invoke-KeycloakAdmin {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$CommandArguments
    )

    $output =
        @(
            docker compose exec `
                -T `
                $KeycloakService `
                sh `
                $WrapperContainerPath `
                @CommandArguments
        )

    $exitCode =
        $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw (
            "Falha no Keycloak Admin CLI. Ação: " +
            ($CommandArguments -join " ")
        )
    }

    return $output
}

function Get-ExactDemoUser {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Username
    )

    $output =
        Invoke-KeycloakAdmin `
            -CommandArguments @(
                "get-list"
                $Username
            )

    $json =
        $output -join "`n"

    try {
        $users =
            @(
                $json |
                    ConvertFrom-Json `
                        -Depth 100
            )
    }
    catch {
        throw (
            "O Keycloak retornou JSON inválido " +
            "ao consultar: " +
            $Username
        )
    }

    $exactUsers =
        @(
            $users |
                Where-Object {
                    [string]$_.username -ceq
                    $Username
                }
        )

    if ($exactUsers.Count -gt 1) {
        throw (
            "Foram encontrados usuários duplicados: " +
            $Username
        )
    }

    if ($exactUsers.Count -eq 0) {
        return $null
    }

    return $exactUsers[0]
}

function Ensure-DemoUser {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Definition
    )

    $existingUser =
        Get-ExactDemoUser `
            -Username $Definition.Username

    $created = $false

    if ($null -eq $existingUser) {
        [void](
            Invoke-KeycloakAdmin `
                -CommandArguments @(
                    "create"
                    $Definition.Username
                    $Definition.Email
                    $Definition.FirstName
                    $Definition.LastName
                )
        )

        $created = $true

        $existingUser =
            Get-ExactDemoUser `
                -Username $Definition.Username

        if ($null -eq $existingUser) {
            throw (
                "O usuário não foi encontrado após a criação: " +
                $Definition.Username
            )
        }
    }

    $userId =
        [string]$existingUser.id

    if (
        [string]::IsNullOrWhiteSpace(
            $userId
        )
    ) {
        throw (
            "O usuário não possui ID: " +
            $Definition.Username
        )
    }

    [void](
        Invoke-KeycloakAdmin `
            -CommandArguments @(
                "update"
                $userId
                $Definition.Username
                $Definition.Email
                $Definition.FirstName
                $Definition.LastName
            )
    )

    [void](
        Invoke-KeycloakAdmin `
            -CommandArguments @(
                "set-password"
                $Definition.Username
            )
    )

    $validationOutput =
        Invoke-KeycloakAdmin `
            -CommandArguments @(
                "get-one"
                $userId
            )

    try {
        $validatedUser =
            (
                $validationOutput -join "`n"
            ) |
                ConvertFrom-Json `
                    -Depth 100
    }
    catch {
        throw (
            "O Keycloak retornou JSON inválido " +
            "na validação de: " +
            $Definition.Username
        )
    }

    if (
        [string]$validatedUser.username -cne
        $Definition.Username
    ) {
        throw (
            "Username divergente após reconciliação: " +
            $Definition.Username
        )
    }

    if (
        [string]$validatedUser.email -cne
        $Definition.Email
    ) {
        throw (
            "E-mail divergente após reconciliação: " +
            $Definition.Username
        )
    }

    if (
        [string]$validatedUser.firstName -cne
        $Definition.FirstName
    ) {
        throw (
            "Nome divergente após reconciliação: " +
            $Definition.Username
        )
    }

    if (
        [string]$validatedUser.lastName -cne
        $Definition.LastName
    ) {
        throw (
            "Sobrenome divergente após reconciliação: " +
            $Definition.Username
        )
    }

    if (-not [bool]$validatedUser.enabled) {
        throw (
            "Usuário desabilitado após reconciliação: " +
            $Definition.Username
        )
    }

    if (-not [bool]$validatedUser.emailVerified) {
        throw (
            "E-mail não verificado após reconciliação: " +
            $Definition.Username
        )
    }

    $exactAfter =
        Get-ExactDemoUser `
            -Username $Definition.Username

    if ($null -eq $exactAfter) {
        throw (
            "O usuário desapareceu após a validação: " +
            $Definition.Username
        )
    }

    return [pscustomobject]@{
        Username = $Definition.Username
        UserId = $userId
        Created = $created
        Enabled = [bool]$validatedUser.enabled
        EmailVerified = [bool]$validatedUser.emailVerified
    }
}

$repositoryRoot =
    Get-RepositoryRoot

Set-Location $repositoryRoot

$environmentVariables = @{}

Read-DotEnvFile `
    -Path (
        Join-Path `
            -Path $repositoryRoot `
            -ChildPath ".env"
    ) `
    -Destination $environmentVariables

Read-DotEnvFile `
    -Path (
        Join-Path `
            -Path $repositoryRoot `
            -ChildPath ".env.demo.local"
    ) `
    -Destination $environmentVariables

$requiredVariables =
    @(
        "KEYCLOAK_ADMIN"
        "KEYCLOAK_ADMIN_PASSWORD"
        "TRUST_STORE_PASSWORD"
        "DEMO_PATIENT_PASSWORD"
        "DEMO_DOCTOR_PASSWORD"
    )

foreach ($requiredVariable in $requiredVariables) {
    if (
        -not $environmentVariables.ContainsKey(
            $requiredVariable
        ) -or
        [string]::IsNullOrWhiteSpace(
            [string]$environmentVariables[
                $requiredVariable
            ]
        )
    ) {
        throw (
            "Variável ausente ou vazia: " +
            $requiredVariable
        )
    }

    Assert-NoLineBreak `
        -Name $requiredVariable `
        -Value (
            [string]$environmentVariables[
                $requiredVariable
            ]
        )
}

if (
    [string]$environmentVariables[
        "TRUST_STORE_PASSWORD"
    ] -match "\s"
) {
    throw (
        "TRUST_STORE_PASSWORD não pode conter " +
        "espaços para esta automação."
    )
}

docker compose config --quiet

if ($LASTEXITCODE -ne 0) {
    throw "O docker-compose.yml está inválido."
}

Wait-Keycloak

$kongContainerId =
    Get-ComposeContainerId `
        -Service $KongService

$keycloakContainerId =
    Get-ComposeContainerId `
        -Service $KeycloakService

$tempDirectory =
    Join-Path `
        -Path $env:TEMP `
        -ChildPath (
            "mhs-demo-users-" +
            [guid]::NewGuid().ToString("N")
        )

New-Item `
    -ItemType Directory `
    -Path $tempDirectory `
    -Force |
    Out-Null

$hostP12Path =
    Join-Path `
        -Path $tempDirectory `
        -ChildPath "kong-kcadm-client.p12"

$hostP12PasswordPath =
    Join-Path `
        -Path $tempDirectory `
        -ChildPath "kong-kcadm-client-password.txt"

$hostSecretsPath =
    Join-Path `
        -Path $tempDirectory `
        -ChildPath "demo-secrets.txt"

$hostWrapperPath =
    Join-Path `
        -Path $tempDirectory `
        -ChildPath "kcadm-wrapper.sh"

$p12Password =
    [Convert]::ToHexString(
        [Security.Cryptography.RandomNumberGenerator]::GetBytes(
            24
        )
    )

$secretLines =
    @(
        $p12Password
        [string]$environmentVariables["TRUST_STORE_PASSWORD"]
        [string]$environmentVariables["KEYCLOAK_ADMIN"]
        [string]$environmentVariables["KEYCLOAK_ADMIN_PASSWORD"]
        [string]$environmentVariables["DEMO_PATIENT_PASSWORD"]
        [string]$environmentVariables["DEMO_DOCTOR_PASSWORD"]
    )

[System.IO.File]::WriteAllText(
    $hostP12PasswordPath,
    (
        $p12Password +
        "`n"
    ),
    [System.Text.UTF8Encoding]::new($false)
)

[System.IO.File]::WriteAllText(
    $hostSecretsPath,
    (
        ($secretLines -join "`n") +
        "`n"
    ),
    [System.Text.UTF8Encoding]::new($false)
)

$wrapperLines =
    @(
        "#!/bin/sh"
        "set -eu"
        ""
        "SECRETS_FILE=`"$SecretsContainerPath`""
        "KCADM=`"/opt/keycloak/bin/kcadm.sh`""
        "SERVER=`"$KeycloakServer`""
        "TARGET_REALM=`"$TargetRealm`""
        ""
        "P12_PASSWORD=`"`$(sed -n `"1p`" `"`${SECRETS_FILE}`")`""
        "TRUST_PASSWORD=`"`$(sed -n `"2p`" `"`${SECRETS_FILE}`")`""
        "ADMIN_USER=`"`$(sed -n `"3p`" `"`${SECRETS_FILE}`")`""
        "ADMIN_PASSWORD=`"`$(sed -n `"4p`" `"`${SECRETS_FILE}`")`""
        "PATIENT_PASSWORD=`"`$(sed -n `"5p`" `"`${SECRETS_FILE}`")`""
        "DOCTOR_PASSWORD=`"`$(sed -n `"6p`" `"`${SECRETS_FILE}`")`""
        ""
        "export KC_OPTS=`"-Djavax.net.ssl.keyStore=$KeycloakP12Path -Djavax.net.ssl.keyStorePassword=`${P12_PASSWORD} -Djavax.net.ssl.keyStoreType=PKCS12 -Djavax.net.ssl.trustStore=/opt/keycloak/certs/ca-truststore.p12 -Djavax.net.ssl.trustStorePassword=`${TRUST_PASSWORD} -Djavax.net.ssl.trustStoreType=PKCS12`""
        ""
        "run_kcadm() {"
        "    `"`${KCADM}`" `"`$@`" --no-config --server `"`${SERVER}`" --realm master --user `"`${ADMIN_USER}`" --password `"`${ADMIN_PASSWORD}`" --client admin-cli"
        "}"
        ""
        "ACTION=`"`$1`""
        "shift"
        ""
        "case `"`${ACTION}`" in"
        "    get-list)"
        "        run_kcadm get users -r `"`${TARGET_REALM}`" -q `"username=`$1`""
        "        ;;"
        "    get-one)"
        "        run_kcadm get `"users/`$1`" -r `"`${TARGET_REALM}`""
        "        ;;"
        "    create)"
        "        run_kcadm create users -r `"`${TARGET_REALM}`" -s `"username=`$1`" -s `"email=`$2`" -s `"firstName=`$3`" -s `"lastName=`$4`" -s enabled=true -s emailVerified=true"
        "        ;;"
        "    update)"
        "        run_kcadm update `"users/`$1`" -r `"`${TARGET_REALM}`" -s `"username=`$2`" -s `"email=`$3`" -s `"firstName=`$4`" -s `"lastName=`$5`" -s enabled=true -s emailVerified=true"
        "        ;;"
        "    set-password)"
        "        case `"`$1`" in"
        "            demo.patient)"
        "                NEW_PASSWORD=`"`${PATIENT_PASSWORD}`""
        "                ;;"
        "            demo.doctor)"
        "                NEW_PASSWORD=`"`${DOCTOR_PASSWORD}`""
        "                ;;"
        "            *)"
        "                echo `"Usuário de senha não suportado.`" >&2"
        "                exit 64"
        "                ;;"
        "        esac"
        "        run_kcadm set-password -r `"`${TARGET_REALM}`" --username `"`$1`" --new-password `"`${NEW_PASSWORD}`""
        "        ;;"
        "    *)"
        "        echo `"Ação não suportada: `${ACTION}`" >&2"
        "        exit 64"
        "        ;;"
        "esac"
    )

[System.IO.File]::WriteAllText(
    $hostWrapperPath,
    (
        ($wrapperLines -join "`n") +
        "`n"
    ),
    [System.Text.UTF8Encoding]::new($false)
)

try {
    docker cp `
        $hostP12PasswordPath `
        "${kongContainerId}:$KongP12PasswordPath"

    if ($LASTEXITCODE -ne 0) {
        throw (
            "Falha ao copiar a senha temporária " +
            "para o Kong."
        )
    }

    $p12Command =
        @(
            "set -eu"
            (
                "IFS= read -r P12_PASSWORD < " +
                $KongP12PasswordPath
            )
            "export P12_PASSWORD"
            (
                "openssl pkcs12 -export " +
                "-out $KongP12Path " +
                "-inkey /etc/kong/certs/kong.key " +
                "-in /etc/kong/certs/kong.crt " +
                "-certfile /etc/kong/certs/ca.crt " +
                "-passout env:P12_PASSWORD"
            )
        ) -join "`n"

    docker compose exec `
        -T `
        -u 0 `
        $KongService `
        sh `
        -lc `
        $p12Command

    if ($LASTEXITCODE -ne 0) {
        throw (
            "Falha ao criar a identidade PKCS12 " +
            "temporária."
        )
    }

    docker cp `
        "${kongContainerId}:$KongP12Path" `
        $hostP12Path

    if ($LASTEXITCODE -ne 0) {
        throw (
            "Falha ao copiar o PKCS12 do Kong."
        )
    }

    docker cp `
        $hostP12Path `
        "${keycloakContainerId}:$KeycloakP12Path"

    if ($LASTEXITCODE -ne 0) {
        throw (
            "Falha ao copiar o PKCS12 para o Keycloak."
        )
    }

    docker cp `
        $hostSecretsPath `
        "${keycloakContainerId}:$SecretsContainerPath"

    if ($LASTEXITCODE -ne 0) {
        throw (
            "Falha ao copiar os segredos temporários."
        )
    }

    docker cp `
        $hostWrapperPath `
        "${keycloakContainerId}:$WrapperContainerPath"

    if ($LASTEXITCODE -ne 0) {
        throw (
            "Falha ao copiar o wrapper do Admin CLI."
        )
    }

    $permissionCommand =
        (
            "chown 1000:0 " +
            "$KeycloakP12Path " +
            "$SecretsContainerPath " +
            "$WrapperContainerPath" +
            " && chmod 600 " +
            "$KeycloakP12Path " +
            "$SecretsContainerPath" +
            " && chmod 700 " +
            "$WrapperContainerPath"
        )

    docker compose exec `
        -T `
        -u 0 `
        $KeycloakService `
        sh `
        -lc `
        $permissionCommand

    if ($LASTEXITCODE -ne 0) {
        throw (
            "Falha ao configurar permissões " +
            "dos arquivos temporários."
        )
    }

    $definitions =
        @(
            [pscustomobject]@{
                Username = "demo.patient"
                Email =
                    "demo.patient@meu-historico-saude.local"
                FirstName = "Paciente"
                LastName = "Demo"
            }
            [pscustomobject]@{
                Username = "demo.doctor"
                Email =
                    "demo.doctor@meu-historico-saude.local"
                FirstName = "Medico"
                LastName = "Demo"
            }
        )

    $results =
        foreach ($definition in $definitions) {
            Ensure-DemoUser `
                -Definition $definition
        }

    Write-Host "===== USUÁRIOS DE DEMONSTRAÇÃO ====="

    foreach ($result in $results) {
        $operation =
            if ($result.Created) {
                "criado"
            }
            else {
                "atualizado"
            }

        Write-Host (
            $result.Username +
            ": " +
            $operation +
            "; id=" +
            $result.UserId +
            "; enabled=" +
            $result.Enabled +
            "; emailVerified=" +
            $result.EmailVerified
        )
    }

    Write-Host ""
    Write-Host "===== RESULTADO FINAL ====="
    Write-Host "demo.patient reconciliado: OK"
    Write-Host "demo.doctor reconciliado: OK"
    Write-Host "Senhas permanentes configuradas: OK"
    Write-Host "Usuários duplicados: NÃO"
    Write-Host "Segredos exibidos: NÃO"
}
finally {
    docker compose exec `
        -T `
        -u 0 `
        $KongService `
        sh `
        -lc `
        (
            "rm -f " +
            $KongP12Path +
            " " +
            $KongP12PasswordPath
        ) `
        *> $null

    docker compose exec `
        -T `
        $KeycloakService `
        sh `
        -lc `
        (
            "rm -f " +
            $KeycloakP12Path +
            " " +
            $SecretsContainerPath +
            " " +
            $WrapperContainerPath
        ) `
        *> $null

    if (
        Test-Path `
            -LiteralPath $tempDirectory
    ) {
        Remove-Item `
            -LiteralPath $tempDirectory `
            -Recurse `
            -Force
    }
}