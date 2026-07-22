# Contrato de mensageria v1

Este diretório contém a baseline do contrato Kafka entre:

- Patient Document Service;
- Med Text Analytics Processor.

O ambiente atual utiliza somente dados de teste. Por isso, esta versão
substitui integralmente o modelo anterior e não oferece compatibilidade
com mensagens legadas.

## Fluxo

```text
Patient Document Service
        |
        | DOCUMENT_PROCESSING_REQUESTED
        v
Med Text Analytics Processor
        |
        | DOCUMENT_PROCESSING_COMPLETED
        | ou
        | DOCUMENT_PROCESSING_FAILED
        v
Patient Document Service
```

Cada solicitação produz exatamente uma resposta terminal.

Uma resposta de conclusão contém todos os resultados clínicos extraídos
do documento original.

## Tópicos

| Tópico | Produtor | Consumidor |
|---|---|---|
| `document-processing-requested` | Patient Document Service | Med Text Analytics Processor |
| `document-processing-result` | Med Text Analytics Processor | Patient Document Service |

Tópicos operacionais de DLQ:

```text
document-processing-requested-dlq
document-processing-result-dlq
```

As mensagens das DLQs preservam o payload original. A causa da falha
deve ser registrada em logs, métricas e cabeçalhos Kafka apropriados.

## Estrutura

```text
v1/
├── asyncapi.yaml
├── README.md
├── examples/
│   ├── document-processing-requested.json
│   ├── document-processing-completed.json
│   └── document-processing-failed.json
├── schemas/
│   ├── document-processing-requested.schema.json
│   └── document-processing-result.schema.json
└── validate-examples.py
```

## Identificadores

### `eventId` da solicitação

Identifica unicamente a mensagem `DOCUMENT_PROCESSING_REQUESTED`.

Também é utilizado pelo inbox do Processor para impedir o processamento
duplicado da mesma solicitação.

### `eventId` da resposta

Identifica unicamente a resposta terminal publicada pelo Processor.

Esse identificador deve ser criado e persistido no outbox antes da
publicação Kafka.

Retries da mesma resposta devem reutilizar o mesmo `eventId`.

### `correlationId`

Existe na resposta terminal e contém o `eventId` da solicitação original.

```text
solicitação -> processamento -> resposta
```

### `documentId`

Identifica o arquivo original armazenado pelo Patient Document Service.

É também a chave Kafka recomendada para preservar a ordem relativa das
mensagens relacionadas ao documento.

### `resultId`

Identifica unicamente cada resultado clínico presente no array `results`.

Exemplos:

```text
EXAME_HEMOGRAMA
EXAME_LIPIDOGRAMA
EXAME_GLICEMIA_JEJUM
```

## Solicitação

O evento `DOCUMENT_PROCESSING_REQUESTED` possui:

- `schemaVersion`;
- `eventType`;
- `eventId`;
- `occurredAt`;
- `documentId`;
- `patientId`;
- `fileUrl`;
- `contentType`.

A `fileUrl` deve:

- ser interna;
- ser acessível apenas pelo Processor autorizado;
- não conter senha, token ou credencial;
- não persistir uma URL assinada no evento.

## Resposta de conclusão

O evento `DOCUMENT_PROCESSING_COMPLETED` possui:

- `schemaVersion`;
- `eventType`;
- `eventId`;
- `correlationId`;
- `occurredAt`;
- `documentId`;
- `patientId`;
- `summary`;
- `primaryDocumentType`;
- `specialty`;
- `documentDate`;
- `confidence`;
- `results`.

A resposta é agregada:

```text
1 solicitação
1 resposta terminal
N resultados clínicos
```

O array `results` deve conter pelo menos um item.

Cada item possui:

- `resultId`;
- `documentType`;
- `documentDate`;
- `data`.

O campo `data` preserva os atributos específicos de cada resultado.

## Resposta de falha

O evento `DOCUMENT_PROCESSING_FAILED` possui:

- `schemaVersion`;
- `eventType`;
- `eventId`;
- `correlationId`;
- `occurredAt`;
- `documentId`;
- `patientId`;
- `error`.

O objeto `error` possui:

| Campo | Descrição |
|---|---|
| `code` | Código estável para tratamento automatizado |
| `message` | Mensagem segura e legível |
| `retryable` | Indica se uma nova tentativa pode resolver a falha |

Uma mensagem de falha não contém:

- `results`;
- `summary`;
- `primaryDocumentType`;
- `specialty`;
- `documentDate`;
- `confidence`.

Erros não devem expor:

- credenciais;
- tokens;
- chaves;
- stack traces;
- URLs assinadas;
- detalhes internos desnecessários.

## Datas e horários

Campos de evento utilizam UTC no formato ISO-8601:

```text
2026-07-22T05:05:49.136Z
```

Nas aplicações Java, o tipo recomendado é `Instant`.

Datas clínicas sem horário utilizam:

```text
YYYY-MM-DD
```

## Idempotência

O inbox do Processor deve possuir unicidade por:

```text
request.eventId
```

O inbox do Patient deve possuir unicidade por:

```text
response.eventId
```

Também deve existir unicidade por:

```text
response.correlationId
```

Isso garante uma única resposta terminal por solicitação.

Os resultados persistidos devem possuir unicidade por:

```text
resultId
```

Uma reentrega Kafka da resposta completa não pode recriar o evento nem
os resultados.

## Outbox do Processor

O outbox deve persistir antes da publicação:

- `eventId` da resposta;
- `correlationId`;
- `occurredAt`;
- `documentId`;
- `patientId`;
- IDs dos resultados;
- resumo consolidado;
- estado de publicação.

O outbox somente pode ser marcado como publicado depois da confirmação
do Kafka.

Uma nova tentativa reutiliza o mesmo payload lógico, inclusive
`eventId` e `occurredAt`.

## Persistência no Patient

O consumo da resposta deve ser transacional:

1. validar o contrato;
2. validar o `correlationId` contra a solicitação original;
3. registrar o evento no inbox;
4. persistir todos os resultados;
5. atualizar a projeção de `health_documents`;
6. marcar o documento como `PROCESSED` ou `FAILED`;
7. confirmar o consumo Kafka somente depois do commit.

O documento principal deve ser atualizado a partir dos campos
consolidados da resposta, e não do primeiro item de `results`.

## Estados

A mensageria publica somente eventos terminais:

```text
DOCUMENT_PROCESSING_COMPLETED
DOCUMENT_PROCESSING_FAILED
```

Estados internos podem continuar existindo:

```text
PENDING_PROCESSING
PROCESSING
PROCESSED
FAILED
```

## Validação dos exemplos

Execute na raiz do repositório:

```powershell
$repoPath = (Get-Location).Path

docker run `
    --rm `
    --mount "type=bind,source=$repoPath,target=/workspace" `
    --workdir /workspace `
    python:3.13-alpine `
    sh `
    -lc `
    "pip install --quiet 'jsonschema[format]>=4,<5' && python /workspace/contracts/messaging/v1/validate-examples.py"
```

Resultado esperado:

```text
VALID: examples/document-processing-requested.json
VALID: examples/document-processing-completed.json
VALID: examples/document-processing-failed.json
OK: todos os exemplos respeitam os contratos.
```

## Validação do AsyncAPI

Execute na raiz do repositório:

```powershell
$repoPath = (Get-Location).Path

docker run `
    --rm `
    --user root `
    --mount "type=bind,source=$repoPath,target=/workspace" `
    --workdir /workspace `
    asyncapi/cli `
    validate `
    /workspace/contracts/messaging/v1/asyncapi.yaml `
    --log-diagnostics
```

Resultado esperado:

```text
File asyncapi.yaml is valid!
```

## Próximas implementações

1. atualizar o Processor para publicar uma resposta agregada;
2. atualizar o Patient para consumir a nova resposta;
3. recriar as estruturas de inbox, outbox e resultados;
4. substituir o tópico de resposta antigo;
5. executar o E2E;
6. validar reentrega e idempotência.
