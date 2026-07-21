# Contrato de mensageria v1

Este diretório contém o contrato versionado das mensagens Kafka
trocadas entre:

- Patient Document Service;
- Med Text Analytics Processor.

## Tópicos

| Tópico | Produtor | Consumidor |
|---|---|---|
| `document-processing-requested` | Patient Document Service | Med Text Analytics Processor |
| `document-processed-response` | Med Text Analytics Processor | Patient Document Service |

## Estrutura

```text
v1/
├── asyncapi.yaml
├── README.md
├── examples/
│   ├── document-processing-requested.json
│   ├── document-processed-success.json
│   └── document-processed-failure.json
├── schemas/
│   ├── document-processing-requested.schema.json
│   └── document-processed-response.schema.json
└── validate-examples.py
```

## Identificação e correlação

O campo `eventId` identifica a solicitação de processamento original.

As respostas reutilizam o mesmo `eventId`, permitindo correlacionar
um ou mais resultados com a solicitação que os originou.

O campo `documentId` identifica o documento de saúde original.

Cada resultado extraído pelo processador possui seu próprio
`document.id`.

## Versão do contrato

Todas as mensagens desta versão devem possuir:

```json
{
  "schemaVersion": 1
}
```

Mudanças compatíveis podem ser adicionadas à versão 1 quando forem
opcionais e não alterarem a semântica de campos existentes.

Mudanças incompatíveis exigem uma nova versão do contrato, por exemplo:

```text
contracts/messaging/v2/
```

São consideradas incompatíveis alterações como:

- remover um campo;
- alterar o tipo de um campo;
- tornar obrigatório um campo anteriormente opcional;
- mudar a semântica de um campo;
- remover um valor aceito de uma enumeração.

## Tipos de evento

O contrato v1 define os seguintes tipos:

```text
DOCUMENT_PROCESSING_REQUESTED
DOCUMENT_PROCESSED_RESPONSE
```

O campo `eventType` permite identificar o tipo lógico da mensagem,
independentemente do nome do tópico Kafka.

## Datas e horários

Campos de eventos devem utilizar UTC no formato ISO-8601, por exemplo:

```text
2026-07-21T13:30:15.123Z
```

Nas aplicações Java, o tipo recomendado para esses campos é `Instant`.

## Solicitação de processamento

A mensagem publicada no tópico `document-processing-requested` deve
possuir:

- `schemaVersion`;
- `eventType`;
- `eventId`;
- `occurredAt`;
- `documentId`;
- `patientId`;
- `fileUrl`.

A URL do arquivo deve ser interna e acessível somente pelo serviço de
processamento autorizado.

Ela não deve conter credenciais, tokens ou outros segredos.

## Respostas de sucesso

Uma resposta com status `PROCESSED` deve possuir:

- `document` preenchido;
- `error` igual a `null`.

Uma única solicitação pode gerar mais de um resultado de sucesso.

A idempotência deve considerar a combinação:

```text
eventId + document.id
```

O campo `document.id` identifica o resultado externo produzido pelo
processador e não substitui o `documentId` do documento original.

## Respostas de falha

Uma resposta com status `FAILED` deve possuir:

- `document` igual a `null`;
- `error` estruturado.

O objeto de erro contém:

| Campo | Descrição |
|---|---|
| `code` | Código estável para tratamento automatizado |
| `message` | Mensagem segura e legível |
| `retryable` | Indica se uma nova tentativa pode resolver a falha |

Exemplo:

```json
{
  "code": "AI_QUOTA_EXCEEDED",
  "message": "A cota do serviço de inteligência artificial foi excedida.",
  "retryable": false
}
```

O campo legado `errorDetail` será mantido temporariamente durante a
migração dos serviços.

As mensagens de erro não devem conter:

- segredos;
- tokens;
- credenciais;
- stack traces;
- URLs assinadas;
- detalhes internos desnecessários.

## Status permitidos

O contrato de resposta aceita apenas estados terminais:

```text
PROCESSED
FAILED
```

Estados internos como `PENDING`, `PROCESSING` ou `ALL_RETRY_FAILED`
não devem ser publicados como status do contrato externo.

Esses estados podem continuar existindo internamente nos serviços.

## Compatibilidade durante a migração

A implantação deve ocorrer nesta ordem:

1. atualizar consumidores para aceitar mensagens legadas e v1;
2. implantar os consumidores tolerantes;
3. atualizar produtores para publicar mensagens v1;
4. validar os fluxos de sucesso, falha, repetição e DLQ;
5. remover compatibilidade legada somente em uma versão futura.

Durante o período de transição, os consumidores devem aceitar a ausência
dos novos campos em mensagens legadas.

Depois que todos os produtores estiverem publicando mensagens v1, os
novos campos deverão ser obrigatórios nas validações do contrato.

## Tratamento de falhas do consumidor

O consumidor não deve apenas registrar e ignorar exceções.

Quando uma mensagem não puder ser persistida ou processada, a exceção
deve ser propagada para permitir que o mecanismo Kafka execute:

- nova tentativa;
- política de backoff;
- envio para DLQ;
- registro observável da falha.

Isso evita que mensagens sejam confirmadas como consumidas antes de
serem efetivamente registradas no inbox.

## Idempotência

Os consumidores devem ser preparados para receber mensagens repetidas.

Para solicitações, o `eventId` identifica o evento original e deve ser
único no inbox do processador.

Para respostas bem-sucedidas, a identificação recomendada é:

```text
eventId + document.id
```

Para respostas de falha, deve existir somente uma falha terminal por
`eventId`, salvo quando a política futura definir tentativas distintas.

## Chave da mensagem Kafka

A chave Kafka recomendada para os dois tópicos é o `documentId`.

Isso mantém mensagens relacionadas ao mesmo documento na mesma
partição, preservando a ordem relativa dos eventos desse documento.

O `eventId` permanece como identificador de correlação no payload.

## `batchId`

O contrato v1 não possui `batchId`.

Atualmente, uma solicitação representa o processamento de um documento.
O `eventId` já correlaciona todos os resultados produzidos.

Um `batchId` poderá ser introduzido quando houver processamento explícito
de múltiplos documentos em uma única operação.

## Arquivos de contrato

### AsyncAPI

O arquivo `asyncapi.yaml` descreve:

- servidores Kafka;
- canais;
- tópicos;
- produtores;
- consumidores;
- operações;
- mensagens;
- correlação;
- referências aos JSON Schemas.

### JSON Schemas

Os arquivos em `schemas/` definem as regras estruturais das mensagens:

```text
document-processing-requested.schema.json
document-processed-response.schema.json
```

Os schemas utilizam JSON Schema Draft 07.

### Exemplos

Os arquivos em `examples/` representam:

- uma solicitação;
- uma resposta bem-sucedida;
- uma resposta de falha.

Os exemplos usam os mesmos `eventId`, `documentId` e `patientId` para
demonstrar a correlação do fluxo.

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

O resultado esperado é:

```text
File asyncapi.yaml is valid!
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

O resultado esperado é:

```text
VALID: examples/document-processing-requested.json
VALID: examples/document-processed-success.json
VALID: examples/document-processed-failure.json
OK: todos os exemplos respeitam os respectivos contratos.
```

## Evolução futura

Possíveis evoluções do contrato incluem:

- identificação explícita de cada resposta;
- suporte a processamento em lote;
- cabeçalhos padronizados de rastreamento;
- Schema Registry;
- geração automática de DTOs;
- validação de contrato no CI;
- publicação de documentação HTML do AsyncAPI;
- remoção definitiva do campo legado `errorDetail`.
