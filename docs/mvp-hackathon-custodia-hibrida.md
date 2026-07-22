# Meu Histórico de Saúde
## Narrativa, proposta de valor e escopo do MVP para o Hackathon

**Versão:** 1.0
**Objetivo:** orientar o desenvolvimento, a demonstração e o pitch do MVP
**Conceito central:** **autonomia sem abandono**

---

## 1. Resumo executivo

O **Meu Histórico de Saúde** é um cofre digital inteligente para documentos de saúde.

A solução permite que o paciente envie exames, laudos, receitas e outros documentos clínicos. Esses arquivos são armazenados com segurança e processados de forma assíncrona por inteligência artificial, que identifica o tipo do documento e extrai informações estruturadas. O resultado passa a compor uma linha do tempo consultável, facilitando o acesso ao histórico durante novos atendimentos.

O projeto propõe um modelo de **custódia híbrida**:

- cidadãos com condições de administrar seus próprios arquivos recebem autonomia e portabilidade;
- pessoas em situação de vulnerabilidade digital podem contar com uma custódia pública assistida;
- o Estado permanece como garantidor de acesso, segurança, interoperabilidade e inclusão, sem precisar ser necessariamente a única custódia de todos os arquivos brutos.

A proposta pode ser resumida pela frase:

> **Autonomia para quem pode. Proteção pública para quem precisa.**

---

## 2. Problema

Informações de saúde frequentemente ficam dispersas entre unidades públicas, clínicas privadas, laboratórios, documentos em papel, arquivos PDF, imagens recebidas por mensagens, sistemas que ainda não estão integrados e dispositivos do próprio paciente.

Em um novo atendimento, o profissional pode não ter acesso rápido ao histórico necessário. O paciente, por sua vez, pode ter dificuldade para localizar, organizar e apresentar seus documentos.

Um modelo exclusivamente centralizado concentra responsabilidades operacionais, armazenamento e disponibilidade em uma única infraestrutura. Por outro lado, transferir toda a responsabilidade ao cidadão excluiria pessoas sem conectividade, dispositivos, armazenamento ou alfabetização digital.

O problema, portanto, não é apenas armazenar arquivos. É combinar continuidade do cuidado, organização, acesso seguro, autonomia, portabilidade e inclusão digital.

---

## 3. Proposta de valor

### Para o paciente

- centralizar documentos dispersos;
- preservar o arquivo original;
- organizar informações por data e tipo;
- baixar e transportar uma cópia;
- reduzir a dependência de uma única plataforma;
- facilitar a apresentação do histórico em novos atendimentos.

### Para o profissional de saúde

- reduzir o tempo gasto procurando documentos;
- visualizar o histórico cronologicamente;
- consultar resumo e dados extraídos;
- melhorar a compreensão do histórico apresentado;
- apoiar a continuidade do cuidado.

### Para o poder público

- oferecer custódia assistida para pessoas vulneráveis;
- promover inclusão digital;
- reduzir duplicações desnecessárias;
- favorecer interoperabilidade futura;
- manter o Estado como garantidor do acesso, e não como único local possível de armazenamento.

---

## 4. Conceito de custódia híbrida

### 4.1 Cofre pessoal

Destinado ao cidadão que possui condições de administrar os próprios arquivos.

O paciente pode:

- baixar o documento original;
- baixar os dados estruturados pela IA;
- armazenar os arquivos localmente;
- copiar os arquivos para o provedor de sua preferência;
- apresentar os dados em outro atendimento;
- futuramente conectar Google Drive, Dropbox, OneDrive ou outro serviço.

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

Nesse modelo, uma instituição pública ou conveniada pode oferecer:

- armazenamento gerenciado;
- apoio presencial;
- recuperação de acesso;
- disponibilidade;
- segurança;
- portabilidade quando solicitada;
- acesso autorizado por representantes legítimos em evoluções futuras.

### 4.3 Papel do Estado

O Estado não deixa de participar. Seu papel é:

- garantir acesso;
- garantir inclusão;
- garantir segurança;
- oferecer custódia assistida;
- promover interoperabilidade;
- definir regras de acesso e consentimento.

A proposta não substitui redes públicas nem sistemas institucionais. Ela os complementa ao permitir que o cidadão incorpore e organize documentos que estão sob sua guarda ou que ainda não chegaram às plataformas integradas.

---

## 5. Formulações recomendadas

### Usar

> O paciente é o titular das informações de saúde e deve ter acesso, transparência, controle e portabilidade.

> A solução propõe uma custódia híbrida, combinando autonomia individual e proteção pública.

> O Estado continua garantindo acesso, segurança, interoperabilidade e inclusão.

> O paciente pode baixar uma cópia portátil do documento original e dos dados estruturados.

> Integrações automáticas com provedores pessoais são uma evolução futura.

### Evitar

> O paciente é o proprietário absoluto dos dados.

> O Estado não consegue armazenar os documentos.

> O sistema substitui a infraestrutura pública de saúde.

> O Google Drive comprova que os dados pertencem ao paciente.

> A IA faz diagnóstico ou substitui o médico.

---

## 6. História principal do MVP

> Uma paciente chega a uma unidade de saúde sem conseguir apresentar seu histórico de forma organizada. Ela envia a imagem de um exame para seu cofre digital. O sistema armazena o documento com segurança, processa o conteúdo de forma assíncrona, identifica o tipo do documento e extrai informações estruturadas. O resultado aparece na linha do tempo do paciente e pode ser consultado por um usuário autorizado. Ao final, o paciente consegue baixar uma cópia portátil do documento e dos dados extraídos para guardar ou apresentar em outro atendimento.

Essa história demonstra centralização, inteligência, organização, segurança, portabilidade e inclusão.

---

## 7. Fluxo funcional do MVP

```text
Paciente autenticado
        ↓
Upload do documento
        ↓
Armazenamento seguro
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
Download portátil
```

---

## 8. Escopo obrigatório para os três dias

### 8.1 Processamento completo

O sistema deve demonstrar:

- upload de um documento;
- armazenamento do arquivo original;
- status inicial de processamento;
- solicitação assíncrona por Kafka;
- processamento pela IA;
- resposta terminal;
- persistência;
- status final `PROCESSED` ou `FAILED`.

### 8.2 Resultado agregado

Uma solicitação deve produzir uma única resposta terminal contendo todos os resultados extraídos.

Campos essenciais:

- identificador da resposta;
- identificador de correlação;
- documento;
- paciente;
- momento do processamento;
- resumo;
- tipo principal;
- data;
- resultados estruturados;
- erro estruturado em caso de falha.

Simplificações permitidas:

- `specialty = null`;
- `confidence = null`;
- resumo determinístico;
- categoria principal por regras simples;
- dados específicos em `results[].data`;
- apenas dois cenários de documento homologados.

### 8.3 Consulta e timeline

Após o processamento, deve ser possível consultar status, tipo, data, resumo, resultados extraídos, palavras-chave disponíveis e posição cronológica na timeline.

### 8.4 Portabilidade

O paciente deve conseguir baixar:

- o documento original;
- os dados estruturados do processamento.

Formato ideal:

```text
meu-historico-saude-{documentId}.zip
├── documento-original.pdf
├── resultado-processamento.json
└── manifest.json
```

Fallback aceitável:

- download do documento original;
- consulta ou download separado do JSON processado.

### 8.5 Segurança demonstrável

A apresentação deve mostrar:

- acesso autenticado funcionando;
- acesso sem token sendo negado;
- idealmente, bloqueio de acesso ao documento de outro paciente.

---

## 9. Tipos documentais homologados

### Cenário principal

**Exame laboratorial**, preferencialmente contendo mais de um resultado:

- hemograma;
- lipidograma;
- glicemia.

### Cenário secundário

Escolher apenas um:

- receita; ou
- encaminhamento.

Os demais tipos continuam como capacidade em evolução, sem compromisso de homologação para a demonstração.

---

## 10. Funcionalidades já existentes que devem ser valorizadas

- autenticação com Keycloak;
- API Gateway;
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
- timeline;
- filtros;
- testes unitários e de integração.

Esses elementos sustentam tecnicamente a solução, mas não devem substituir a história principal.

---

## 11. Funcionalidades fora do MVP

Não devem ser implementadas antes da entrega:

- integração OAuth com Google Drive;
- Dropbox;
- OneDrive;
- múltiplos provedores de armazenamento;
- compartilhamento com expiração;
- revogação avançada;
- cofre público completo;
- funcionário público atuando por terceiro;
- representação legal;
- dashboard frontend;
- classificação automática de especialidade;
- confiança calibrada da IA;
- alertas clínicos;
- diagnóstico;
- auditoria completa;
- FHIR;
- integração direta com a RNDS;
- testes extensivos de carga;
- arquitetura nacional de produção.

---

## 12. Roadmap futuro

### Curto prazo

- compartilhamento temporário;
- revogação;
- filtros por especialidade;
- exportação em ZIP;
- auditoria de acesso;
- melhoria da timeline.

### Médio prazo

- conectores para Google Drive, Dropbox e OneDrive;
- consentimento por escopo;
- representação de dependentes;
- custódia pública assistida;
- dashboard para médicos e pacientes;
- classificação por especialidade.

### Longo prazo

- interoperabilidade por FHIR;
- integração com redes públicas;
- migração entre provedores;
- assinatura e verificação de integridade;
- políticas avançadas de retenção;
- análise longitudinal;
- observabilidade e escalabilidade nacional.

---

## 13. Critérios de aceite do MVP

O MVP será considerado pronto para gravação quando:

1. a infraestrutura subir de forma reproduzível;
2. o usuário conseguir autenticar;
3. o documento puder ser enviado;
4. o arquivo original for armazenado;
5. o processamento assíncrono for disparado;
6. a IA retornar dados estruturados;
7. apenas uma resposta terminal agregada for publicada;
8. o resultado for persistido;
9. o documento mudar para `PROCESSED`;
10. o resultado puder ser consultado;
11. o item aparecer na timeline;
12. o documento original puder ser baixado;
13. os dados estruturados puderem ser obtidos;
14. uma requisição sem token for negada;
15. o fluxo funcionar com documentos fictícios e repetíveis.

---

## 14. Prioridade de implementação

### Prioridade 1 — indispensável

```text
upload
→ Kafka
→ IA
→ resultado agregado
→ persistência
→ consulta
→ timeline
```

### Prioridade 2 — maior impacto com baixo esforço

```text
download do arquivo original
+ dados estruturados
```

### Prioridade 3 — credibilidade

```text
acesso negado sem autenticação
+ idempotência
+ cenário de falha
```

### Regra de corte

O fluxo principal deve estar funcionando até o fim do segundo dia.

Caso isso não ocorra:

- cancelar ZIP;
- usar downloads separados;
- não implementar novas funcionalidades;
- dedicar o terceiro dia à estabilização, Postman e documentação.

---

## 15. Plano de três dias

### Dia 1 — Processor

- modelar o resultado agregado;
- gerar um novo `eventId`;
- preservar o evento original como `correlationId`;
- agregar os resultados;
- gerar resumo determinístico;
- determinar o tipo principal;
- publicar uma única resposta terminal;
- testar sucesso e falha.

### Dia 2 — Patient Document Service

- consumir o novo contrato;
- validar a resposta;
- garantir idempotência;
- persistir os resultados;
- atualizar status e metadados;
- disponibilizar consulta;
- confirmar timeline;
- executar o fluxo ponta a ponta.

### Dia 3 — Portabilidade e estabilização

- implementar exportação portátil, caso o fluxo principal esteja estável;
- confirmar download do original;
- organizar a collection do Postman;
- preparar documentos fictícios;
- revisar README;
- revisar diagrama;
- executar as suítes;
- congelar o código para gravação.

---

## 16. Estrutura sugerida para o pitch

### Problema

Dados de saúde podem estar espalhados entre papéis, arquivos pessoais, laboratórios, clínicas e sistemas não integrados.

### Solução

Um cofre digital inteligente que armazena o documento original, extrai informações e organiza o histórico do paciente.

### Diferencial

Custódia híbrida: autonomia para quem pode administrar seus dados e proteção pública assistida para quem precisa.

### Demonstração

Upload, processamento assíncrono, resultado estruturado, timeline, segurança e portabilidade.

### Impacto

- continuidade do cuidado;
- redução do tempo de busca;
- autonomia;
- inclusão;
- preparação para interoperabilidade.

### Próximos passos

Compartilhamento, provedores pessoais de nuvem, custódia pública assistida, dashboard e integração por padrões de saúde.

---

## 17. Pitch resumido

> Hoje, muitos pacientes carregam seu histórico de saúde em papéis, imagens e arquivos espalhados. Nem todas essas informações chegam aos sistemas integrados. O Meu Histórico de Saúde é um cofre digital inteligente: o paciente envia um documento, a solução o armazena com segurança, utiliza inteligência artificial para extrair informações e organiza tudo em uma linha do tempo. Nossa proposta usa custódia híbrida. Quem possui condições pode baixar e transportar seus dados; quem enfrenta vulnerabilidade digital pode contar com uma custódia pública assistida. É autonomia sem abandono: o Estado garante acesso e inclusão, enquanto o cidadão ganha controle e portabilidade sobre seu histórico.

---

## 18. Frase central

> **Meu Histórico de Saúde é um cofre digital inteligente com custódia híbrida: dá autonomia ao cidadão sem abandonar quem depende do Estado.**
