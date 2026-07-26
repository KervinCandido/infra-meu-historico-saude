# Meu Histórico de Saúde
## Narrativa, proposta de valor e escopo atual do MVP para o Hackathon

**Versão:** 2.0  
**Objetivo:** consolidar a narrativa, a proposta de valor, o escopo funcional e a visão de evolução do MVP  
**Conceito central:** **autonomia sem abandono**

---

## 1. Resumo executivo

O **Meu Histórico de Saúde** é um cofre digital inteligente para documentos clínicos.

A solução permite que o paciente envie documentos de saúde, como exames, laudos e receitas. Esses arquivos são preservados no repositório de documentos e processados de forma assíncrona por inteligência artificial, que identifica o tipo do documento e extrai informações estruturadas. O resultado passa a compor uma linha do tempo cronológica, facilitando a consulta do histórico durante novos atendimentos.

O MVP também implementa compartilhamento controlado entre paciente e médico. O paciente pode conceder uma autorização temporária de leitura, impedir o download do documento original e revogar o acesso a qualquer momento. A autenticação do médico, por si só, não concede acesso ao histórico.

O projeto propõe um modelo de **custódia híbrida**:

- cidadãos com condições de administrar os próprios arquivos recebem autonomia e portabilidade;
- pessoas em situação de vulnerabilidade digital poderão contar, em uma evolução futura, com custódia pública assistida;
- o Estado permanece como garantidor de acesso, segurança, interoperabilidade e inclusão, sem precisar ser necessariamente o único custodiante de todos os arquivos brutos.

A proposta pode ser resumida pela frase:

> **Autonomia para quem pode. Proteção pública para quem precisa.**

---

## 2. Problema

Informações de saúde frequentemente ficam dispersas entre unidades públicas, clínicas privadas, laboratórios, documentos em papel, arquivos PDF, imagens recebidas por mensagens, dispositivos pessoais e sistemas ainda não integrados.

Em um novo atendimento, o profissional pode não ter acesso rápido ao histórico necessário. O paciente, por sua vez, pode ter dificuldade para localizar, organizar e apresentar seus documentos.

Um modelo exclusivamente centralizado concentra responsabilidades operacionais, armazenamento e disponibilidade em uma única infraestrutura. Por outro lado, transferir toda a responsabilidade ao cidadão excluiria pessoas sem conectividade, dispositivos adequados, armazenamento ou alfabetização digital.

O problema, portanto, não é apenas armazenar arquivos. É combinar:

- continuidade do cuidado;
- organização;
- acesso seguro;
- autonomia;
- portabilidade;
- compartilhamento controlado;
- inclusão digital.

---

## 3. Proposta de valor

### Para o paciente

- centralizar documentos dispersos;
- preservar o arquivo original;
- organizar informações por data e tipo;
- consultar dados estruturados;
- visualizar o histórico cronologicamente;
- baixar e transportar uma cópia do documento;
- controlar quem pode consultar seus dados;
- revogar autorizações;
- reduzir a dependência de uma única plataforma.

### Para o profissional de saúde

- reduzir o tempo gasto procurando documentos;
- visualizar o histórico cronologicamente;
- consultar resumo e dados extraídos;
- acessar apenas informações autorizadas;
- melhorar a compreensão do histórico apresentado;
- apoiar a continuidade do cuidado.

### Para o poder público

- promover inclusão digital;
- apoiar a continuidade do cuidado;
- favorecer interoperabilidade futura;
- oferecer, em uma evolução da solução, custódia assistida para pessoas vulneráveis;
- manter o Estado como garantidor do acesso e da inclusão, e não como único local possível de armazenamento.

---

## 4. Conceito de custódia híbrida

### 4.1 Cofre pessoal

Destinado ao cidadão que possui condições de administrar os próprios arquivos.

No MVP, o paciente pode:

- autenticar-se;
- cadastrar-se;
- enviar documentos;
- acompanhar o processamento;
- consultar dados estruturados;
- visualizar o documento na timeline;
- baixar o arquivo original;
- compartilhar temporariamente as informações;
- bloquear o download pelo médico;
- revogar o acesso.

Como evolução, o paciente poderá:

- exportar um pacote portátil com arquivo e metadados;
- armazenar os arquivos localmente;
- copiar os arquivos para o provedor de sua preferência;
- conectar Google Drive, Dropbox, OneDrive ou outro serviço.

### 4.2 Cofre público assistido

Destinado a pessoas que não possuem condições técnicas, econômicas ou funcionais para administrar o próprio armazenamento.

Exemplos:

- ausência de smartphone;
- conectividade limitada;
- baixa alfabetização digital;
- idosos;
- pessoas com deficiência;
- dependentes;
- pessoas sem conta de armazenamento em nuvem.

Essa funcionalidade ainda não faz parte do MVP implementado.

Em uma evolução futura, uma instituição pública ou conveniada poderá oferecer:

- armazenamento gerenciado;
- apoio presencial;
- recuperação de acesso;
- portabilidade quando solicitada;
- atuação autorizada por representantes legítimos;
- consentimento assistido;
- trilha de auditoria específica.

### 4.3 Papel do Estado

O Estado não deixa de participar. Seu papel é:

- garantir acesso;
- garantir inclusão;
- garantir segurança;
- promover interoperabilidade;
- definir regras de acesso e consentimento;
- oferecer custódia assistida quando necessário.

A proposta não substitui redes públicas nem sistemas institucionais. Ela os complementa ao permitir que o cidadão incorpore e organize documentos que estão sob sua guarda ou que ainda não chegaram às plataformas integradas.

---

## 5. Formulações recomendadas

### Usar

> O paciente é o titular das informações de saúde e deve ter acesso, transparência, controle e portabilidade.

> A solução propõe uma custódia híbrida, combinando autonomia individual e proteção pública.

> O Estado continua garantindo acesso, segurança, interoperabilidade e inclusão.

> O paciente pode baixar uma cópia portátil do documento original.

> Os dados estruturados podem ser consultados pela API.

> O compartilhamento é temporário, granular e revogável.

> Integrações automáticas com provedores pessoais são uma evolução futura.

### Evitar

> O paciente é o proprietário absoluto dos dados.

> O Estado não consegue armazenar os documentos.

> O sistema substitui a infraestrutura pública de saúde.

> O Google Drive comprova que os dados pertencem ao paciente.

> A IA faz diagnóstico ou substitui o médico.

> O ambiente local já está pronto para operação nacional em produção.

---

## 6. História principal do MVP

> Uma paciente envia a imagem de um exame para seu cofre digital. O sistema preserva o arquivo, processa o conteúdo de forma assíncrona, identifica o tipo do documento e extrai informações estruturadas. O resultado aparece na linha do tempo da paciente.
>
> Um médico autenticado tenta consultar os documentos, mas recebe acesso negado porque ainda não possui autorização. A paciente cria então um compartilhamento temporário de leitura, sem permitir o download do arquivo original. O médico passa a consultar as informações autorizadas.
>
> Depois do atendimento, a paciente revoga a concessão. O acesso do médico é bloqueado imediatamente, enquanto o histórico da autorização permanece registrado para rastreabilidade.

Essa história demonstra:

- centralização;
- processamento inteligente;
- organização;
- segurança;
- separação entre autenticação e autorização;
- compartilhamento granular;
- revogação;
- portabilidade;
- autonomia do paciente.

---

## 7. Perfis da demonstração

A demonstração utiliza dois perfis humanos fictícios cadastrados no Keycloak:

- `demo.patient`: representa o paciente titular do cofre e responsável pelas autorizações;
- `demo.doctor`: representa o profissional de saúde que somente consulta documentos quando possui uma concessão válida.

Também são utilizados clientes técnicos para os serviços internos.

A separação entre os perfis permite comprovar que:

- paciente e médico possuem identidades diferentes;
- autenticação não implica autorização;
- o médico não recebe acesso automático;
- a autorização depende de um compartilhamento ativo;
- as permissões podem distinguir leitura e download;
- a revogação produz efeito imediato.

---

## 8. Fluxos funcionais do MVP

### 8.1 Processamento do documento

```text
Paciente autenticado
        ↓
Cadastro do paciente
        ↓
Upload do documento
        ↓
Armazenamento do arquivo original
        ↓
Evento assíncrono de processamento
        ↓
Classificação e extração por IA
        ↓
Resposta terminal agregada
        ↓
Persistência do resultado
        ↓
Atualização do status
        ↓
Consulta do documento
        ↓
Documento na timeline
        ↓
Download do arquivo original
```

### 8.2 Compartilhamento e revogação

```text
Médico autenticado
        ↓
Tentativa sem autorização
        ↓
403 Forbidden
        ↓
Paciente cria compartilhamento temporário
        ↓
201 Created
        ↓
Médico consulta os documentos
        ↓
200 OK
        ↓
Médico tenta baixar o arquivo
        ↓
403 Forbidden
        ↓
Paciente revoga a concessão
        ↓
204 No Content
        ↓
Médico tenta consultar novamente
        ↓
403 Forbidden
```

A sequência completa validada na collection foi:

```text
403 → 201 → 200 → 200 → 403 → 204 → 403 → 200
```

Ela representa:

1. médico sem compartilhamento;
2. concessão criada;
3. compartilhamento confirmado pelo paciente;
4. consulta autorizada pelo médico;
5. download bloqueado;
6. revogação;
7. perda do acesso;
8. confirmação do histórico da revogação.

---

## 9. Escopo funcional implementado

O MVP demonstra:

- autenticação técnica com `client_credentials`;
- autenticação humana com Authorization Code e PKCE;
- validação dos perfis `demo.patient` e `demo.doctor`;
- cadastro e consulta de pacientes;
- upload de documento;
- armazenamento do arquivo original;
- status inicial de processamento;
- solicitação assíncrona por Kafka;
- processamento pela IA;
- resposta terminal agregada;
- persistência;
- status final de sucesso ou falha;
- consulta do documento;
- consulta dos dados estruturados;
- listagem paginada;
- timeline cronológica;
- download do arquivo original pelo paciente;
- acesso sem token sendo negado;
- separação entre autenticação e autorização;
- compartilhamento temporário;
- expiração da concessão;
- permissão independente de leitura;
- permissão independente de download;
- revogação;
- perda imediata de acesso;
- preservação do histórico da concessão.

---

## 10. Resultado agregado e dados estruturados

Uma solicitação de processamento produz uma resposta terminal agregada contendo os resultados extraídos.

Entre os dados possíveis estão:

- identificador da resposta;
- identificador de correlação;
- documento;
- paciente;
- momento do processamento;
- resumo;
- tipo principal;
- data;
- especialidade provável;
- palavras-chave;
- resultados estruturados;
- erro estruturado em caso de falha.

A especialidade deve ser apresentada como **metadado provável**, e não como diagnóstico ou classificação clínica definitiva.

A consulta dos dados estruturados ocorre por meio da API em formato JSON. A exportação para arquivo `.json` ou pacote `.zip` permanece como evolução futura.

Formato futuro desejado:

```text
meu-historico-saude-{documentId}.zip
├── documento-original.pdf
├── resultado-processamento.json
└── manifest.json
```

---

## 11. Tipos documentais homologados para a demonstração

### Cenário principal

**Exame laboratorial**, preferencialmente contendo mais de um resultado:

- hemograma;
- lipidograma;
- glicemia.

### Cenário secundário

Um dos seguintes:

- receita;
- encaminhamento.

Os demais tipos representam capacidade de evolução e não precisam ser demonstrados na apresentação principal.

---

## 12. Funcionalidades existentes que devem ser valorizadas

- autenticação com Keycloak;
- perfis humanos de paciente e médico;
- autenticação técnica;
- API Gateway;
- HTTPS;
- armazenamento no Nextcloud;
- Kafka;
- processamento assíncrono;
- padrão Outbox;
- Inbox idempotente;
- retry;
- DLT;
- PostgreSQL;
- MongoDB;
- validação de contratos;
- versionamento de eventos;
- resposta agregada;
- consulta dos resultados;
- listagem paginada;
- timeline;
- download do original;
- compartilhamento temporário;
- permissões granulares;
- revogação;
- testes unitários;
- testes de integração;
- collection do Postman;
- documentação OpenAPI e Swagger.

Esses elementos sustentam tecnicamente a solução, mas não devem substituir a história principal durante o pitch.

---

## 13. Funcionalidades fora do MVP

Não fazem parte do escopo implementado:

- integração OAuth com Google Drive;
- Dropbox;
- OneDrive;
- múltiplos provedores de armazenamento;
- exportação em ZIP;
- compartilhamento por QR code;
- compartilhamento por chave temporária;
- filtro de compartilhamento por especialidade;
- filtro de compartilhamento por intervalo documental;
- consentimento com finalidade declarada;
- auditoria detalhada de cada leitura e download;
- cofre público completo;
- funcionário público atuando por terceiro;
- representação legal;
- dashboard frontend;
- confiança calibrada da IA;
- alertas clínicos;
- diagnóstico;
- FHIR;
- integração direta com a RNDS;
- autenticação Gov.br;
- testes extensivos de carga;
- arquitetura nacional de produção.

---

## 14. Roadmap futuro

### Curto prazo

- melhorar a timeline;
- adicionar filtros por especialidade e período;
- ampliar o compartilhamento já implementado;
- adicionar auditoria completa de acesso;
- implementar exportação em ZIP;
- permitir download configurável por concessão;
- aumentar a cobertura dos cenários de falha.

### Médio prazo

- conectores para Google Drive, Dropbox e OneDrive;
- consentimento por escopo e finalidade;
- representação de dependentes;
- custódia pública assistida;
- dashboard para médicos e pacientes;
- taxonomia controlada de especialidades;
- índices de confiança para a IA;
- autenticação Gov.br.

### Longo prazo

- interoperabilidade por FHIR;
- integração com RNDS e outras redes públicas;
- migração entre provedores;
- assinatura e verificação de integridade;
- políticas avançadas de retenção;
- análise longitudinal;
- observabilidade completa;
- escalabilidade nacional.

---

## 15. Critérios de aceite do MVP

### Concluídos

- [x] infraestrutura reproduzível;
- [x] autenticação técnica;
- [x] autenticação humana;
- [x] perfis `demo.patient` e `demo.doctor`;
- [x] cadastro do paciente;
- [x] upload;
- [x] armazenamento do arquivo original;
- [x] processamento assíncrono;
- [x] resultado estruturado;
- [x] resposta terminal agregada;
- [x] persistência;
- [x] status final de processamento;
- [x] consulta;
- [x] listagem paginada;
- [x] timeline;
- [x] download do original pelo paciente;
- [x] acesso sem token negado;
- [x] cliente técnico com permissões restritas;
- [x] médico sem compartilhamento bloqueado;
- [x] compartilhamento temporário;
- [x] download do médico bloqueado;
- [x] revogação;
- [x] perda imediata de acesso;
- [x] fluxo repetível com dados fictícios.

### Evoluções

- [ ] exportação em ZIP;
- [ ] download separado dos dados estruturados como arquivo;
- [ ] cofre público assistido;
- [ ] integração com provedores pessoais;
- [ ] RNDS e FHIR;
- [ ] dashboard;
- [ ] auditoria completa;
- [ ] hardening para produção.

---

