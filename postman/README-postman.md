# Collection Postman — Meu Histórico Saúde

Arquivos:
- `meu-historico-saude.postman_collection.json`
- `meu-historico-saude-local.postman_environment.json`

## Importação

1. No Postman, use **Import** e selecione os dois arquivos JSON.
2. Selecione o environment **Meu Histórico Saúde - Local ou Kong**.
3. Preencha localmente:
   - `devClientSecret`
   - `aiClientSecret` apenas quando for testar o cliente técnico da IA.
4. Não envie ou versione novamente o environment depois de preencher secrets ou tokens.

## Execução sugerida

1. `00 - Autenticação / Obter token - cliente de desenvolvimento`
2. `02 - Pacientes / Cadastrar paciente`
3. `03 - Documentos do paciente / Enviar documento`
   - selecione manualmente um arquivo;
4. execute as consultas dos documentos;
5. obtenha o token da IA e execute a pasta `05 - Matriz de autorização`.

`patientId`, `documentId`, `accessToken` e `aiAccessToken` são preenchidos automaticamente.

## Testes pelo Kong

A collection usa a variável `baseUrl`.

- acesso direto à API: `http://localhost:8080`
- para o Kong: substitua `baseUrl` pela URL e pelo prefixo de rota configurados no gateway.

A URL do Keycloak permanece separada em `keycloakBaseUrl`. Caso o Keycloak também seja exposto pelo Kong, essa variável pode ser alterada independentemente.

## Observações

- Não existe endpoint próprio de login no Patient Document Service.
- Os tokens são obtidos diretamente no Keycloak pelo fluxo `client_credentials`.
- O upload exige a seleção manual do arquivo no Postman.
- Para baixar o arquivo, use **Send and Download**.
