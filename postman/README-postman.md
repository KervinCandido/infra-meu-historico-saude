# Collection Postman — Meu Histórico Saúde

Esta pasta contém os artefatos usados para validar o Patient Document Service por meio do Kong no ambiente Docker local.

## Arquivos

- `Meu Histórico Saúde - Patient Document Service.postman_collection.json`
- `Meu Histórico Saúde - Local ou Kong.postman_environment.json`
- `files/exame-laboratorial-ficticio.png`

## Pré-requisitos

1. Docker Desktop em execução.
2. Stack iniciada:

```powershell
docker compose up -d
docker compose ps
```

3. Serviços saudáveis.
4. Postman Desktop instalado.

## Certificado HTTPS local

O Kong utiliza um certificado TLS autogerado no ambiente local.

Para simplificar a execução da collection sem instalar manualmente a CA em
cada máquina, desative no Postman:

`Settings → General → SSL certificate verification`

O Console do Postman poderá exibir:

`Warning: Unable to verify the first certificate`

Esse aviso é esperado no ambiente local e não impede a execução das
requisições. Essa configuração não deve ser utilizada em ambientes de
homologação ou produção.

## Importação

Importe os dois arquivos JSON desta pasta e selecione o environment:

`Meu Histórico Saúde - Local ou Kong`

O environment utiliza:

```text
baseUrl = https://localhost:8443
realm = meu-historico-saude
```

O mesmo endereço público do Kong é usado para a API e para os endpoints OpenID Connect do Keycloak.

## Secrets

Preencha localmente no environment:

| Variável | Origem |
|---|---|
| `devClientSecret` | `PATIENT_DOCUMENT_DEV_CLIENT_SECRET` do arquivo `.env` |
| `aiClientSecret` | `AI_PROCESSING_CLIENT_SECRET` do arquivo `.env` |

Não salve nem versione esses valores.

## Fluxo recomendado

1. Obter token do cliente de desenvolvimento.
2. Cadastrar paciente.
3. Consultar o paciente criado.
4. Enviar um documento PNG ou JPEG.
5. Consultar o documento até `processingStatus` ser `PROCESSED`.
6. Baixar o arquivo por `/documents/{documentId}/file`.
7. Obter token do serviço de IA.
8. Confirmar que o cliente de IA recebe `403` ao consultar pacientes.
9. Confirmar que o cliente de IA recebe `200` ao baixar o arquivo.
10. Validar `PATCH /documents/{documentId}/ai-result`.

## Escopos

O cliente de desenvolvimento deve receber:

- `patients:read`
- `patients:write`
- `documents:read`
- `documents:write`
- `documents:file:read`
- `documents:ai-result:write`

O cliente `ai-processing-service` deve receber somente:

- `documents:file:read`
- `documents:ai-result:write`

## Observações

- Não existe endpoint próprio de login no Patient Document Service.
- Os tokens são obtidos no Keycloak pelo fluxo `client_credentials`.
- `accessToken`, `aiAccessToken`, `patientId` e `documentId` são preenchidos automaticamente pela collection.
- `{{$timestamp}}` é uma variável dinâmica nativa do Postman.
- O upload requer a seleção manual de um arquivo local no campo multipart `file`.
- A rota de download é `/documents/{documentId}/file`.
- Não utilize a rota antiga `/documents/{documentId}/download`.
- Arquivos `.txt` ainda não são processados automaticamente pelo processador de IA atual.
