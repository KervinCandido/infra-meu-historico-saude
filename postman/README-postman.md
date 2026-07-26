# Guia rápido da Collection Postman

## Meu Histórico Saúde — Patient Document Service

Este guia apresenta a ordem recomendada para validar a API pelo Postman, usando a collection **Meu Histórico Saúde - Patient Document Service**.

---

## 1. Pré-requisitos

Antes da execução:

- infraestrutura Docker iniciada e saudável;
- Kong acessível em `https://localhost:8443`;
- environment da collection importado e selecionado;
- `devClientSecret` e `aiClientSecret` preenchidos;
- usuários `demo.patient` e `demo.doctor` disponíveis no Keycloak;
- arquivo fictício selecionado no upload:

```text
postman/files/exame-laboratorial-ficticio.png
```

Os secrets e tokens não devem ser incluídos em commits, documentação ou capturas de tela.

---

## 2. Roteiro rápido

Execute as requisições nesta ordem:

1. **OpenAPI JSON** e **Swagger UI**.
2. **Obter token - cliente de desenvolvimento**.
3. **Obter token - serviço de IA**.
4. **Obter token - paciente (Authorization Code + PKCE)**:
   - autentique `demo.patient`;
   - clique em **Use Token**;
   - pressione **Send**.
5. **Obter token - médico (Authorization Code + PKCE)**:
   - autentique `demo.doctor`;
   - clique em **Use Token**;
   - pressione **Send**.
6. **Cadastrar paciente**.
7. **Listar pacientes** e **Consultar paciente por ID**.
8. **Enviar documento** usando `exame-laboratorial-ficticio.png`.
9. Consulte **Consultar documento por ID** até o status ficar `PROCESSED`.
10. Execute:
    - **Listar resultados processados**;
    - **Listar documentos paginados**;
    - **Consultar timeline**;
    - **Paciente baixa o próprio arquivo**.
11. Execute **Atualizar resultado da IA manualmente** somente para validar o endpoint técnico.
12. Execute a pasta **05 - Matriz de autorização**.
13. Execute a pasta **06 - Compartilhamento e revogação** na ordem numérica.

---

## 3. Variáveis principais

### Environment

| Variável | Uso |
|---|---|
| `baseUrl` | URL da API e do Keycloak |
| `realm` | Realm do Keycloak |
| `devClientId` / `devClientSecret` | Cliente técnico de desenvolvimento |
| `aiClientId` / `aiClientSecret` | Cliente técnico da IA |
| `patientAccessToken` | Token de `demo.patient` |
| `doctorAccessToken` | Token de `demo.doctor` |

### Collection

| Variável | Gerada por |
|---|---|
| `accessToken` | Token do cliente de desenvolvimento |
| `aiAccessToken` | Token do serviço de IA |
| `patientId` | Cadastro do paciente |
| `doctorSubject` | UserInfo do médico |
| `documentId` | Upload do documento |
| `accessGrantId` | Criação do compartilhamento |

Essas variáveis são preenchidas automaticamente pelos scripts da collection.

---

## 4. Autenticação humana

Paciente e médico usam **Authorization Code com PKCE**.

Para cada usuário:

1. abra a requisição correspondente;
2. acesse a aba **Authorization**;
3. clique em **Get New Access Token**;
4. faça o login;
5. clique em **Use Token**;
6. pressione **Send**.

Resultados esperados:

```text
demo.patient → patientAccessToken
demo.doctor  → doctorAccessToken + doctorSubject
```

O endpoint UserInfo valida a identidade e os scripts salvam as variáveis automaticamente.

---

## 5. Upload e processamento

A requisição **Enviar documento** deve retornar:

```text
201 Created
processingStatus = PENDING_PROCESSING
```

O `documentId` é salvo automaticamente.

Depois do upload, consulte:

```text
GET /documents/{{documentId}}
```

até obter:

```text
processingStatus = PROCESSED
```

Somente depois execute as consultas de resultado, timeline e compartilhamento.

---

## 6. Atualização manual da IA

Endpoint:

```text
PATCH /documents/{{documentId}}/ai-result
```

Token:

```text
{{aiAccessToken}}
```

Resultado esperado:

```text
200 OK
```

Essa requisição valida o contrato técnico de atualização. Ela não substitui a validação do processamento automático realizado pelo Kafka e pelo processador de IA.

---

## 7. Matriz de autorização

| Requisição | Resultado esperado |
|---|---:|
| Sem token — listar pacientes | `401` |
| Token da IA — listar pacientes | `403` |
| Token da IA — baixar arquivo | `200` |
| Cliente de desenvolvimento sem vínculo — baixar arquivo | `403` |

O serviço de IA possui o scope técnico `documents:file:read`. Já o cliente de desenvolvimento não deve baixar o arquivo quando não possuir vínculo autorizado com o paciente.

---

## 8. Compartilhamento e revogação

Execute a pasta `06` na ordem numérica.

| Etapa | Resultado |
|---:|---:|
| Médico sem compartilhamento | `403` |
| Paciente compartilha com médico | `201` |
| Paciente lista compartilhamentos | `200` |
| Médico acessa documentos | `200` |
| Médico tenta baixar o arquivo | `403` |
| Paciente revoga o compartilhamento | `204` |
| Médico tenta acessar novamente | `403` |
| Paciente consulta o histórico | `200` |

Sequência esperada:

```text
403 → 201 → 200 → 200 → 403 → 204 → 403 → 200
```

O compartilhamento atual:

- permite leitura;
- bloqueia download;
- expira em sete dias;
- pode ser revogado pelo paciente.

A versão atual do body não aplica filtro por especialidade ou intervalo documental.

---

## 9. Compartilhamentos antigos

A etapa **Paciente lista compartilhamentos** identifica grants ativos antigos.

Quando `staleAccessGrantIds` estiver preenchido:

1. execute **Manutenção / Revogar compartilhamento antigo**;
2. repita até não existirem grants antigos;
3. reinicie a pasta 06 com um compartilhamento novo.

---

## 10. Problemas comuns

### `401 Unauthorized`

Gere um token novo e confirme que **Use Token** foi acionado.

### `403 Forbidden`

Verifique:

- identidade usada;
- scopes do token;
- existência e validade do compartilhamento;
- `readAllowed`;
- `downloadAllowed`;
- revogação anterior.

### `documentId` não definido

Execute novamente **Enviar documento**.

### Documento ainda não processado

Aguarde e repita **Consultar documento por ID**.

### Arquivo não encontrado

Selecione novamente o arquivo na aba **Body**. O caminho absoluto exportado pelo Postman não é portátil entre computadores.

---

## 11. Execução pelo Runner

A autenticação PKCE, a seleção do arquivo e o acompanhamento do processamento são etapas manuais.

Depois de preparar os tokens, cadastrar o paciente, enviar o arquivo e confirmar o processamento, a pasta **06 - Compartilhamento e revogação** pode ser executada no Runner com:

- uma iteração;
- oito requisições;
- zero testes com falha;
- sequência de status esperada;
- `sharingFlowValidated = true`.

---

## 12. Exportação segura

Antes de exportar a collection e o environment, limpe:

- client secrets;
- tokens;
- `patientId`;
- `doctorSubject`;
- `documentId`;
- `accessGrantId`;
- marcadores de revogação;
- variáveis temporárias.

Confirme também:

- ausência de JWTs;
- ausência de senhas e chaves;
- uso apenas de arquivos fictícios;
- JSON válido;
- reimportação bem-sucedida em outro workspace.
