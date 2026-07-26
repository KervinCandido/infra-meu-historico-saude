# Hackathon FIAP

## Projeto

**Hackathon FIAP**  
**Curso:** Pós-Graduação em Arquitetura e Desenvolvimento em Java  
**Serviços:** `infra-meu-historico-saude`, `med-text-analytics-processor` e `patient-document-service`  
**Tema:** Cofre digital inteligente para a centralização e organização de documentos clínicos e históricos de saúde dos pacientes.

## Equipe

| Nome | RM | E-mail |
|---|---:|---|
| Alexandre Belisário Duarte Leite de Andrade | RM367163 | alexbdla@gmail.com |
| Kervin Sama Candido da Silva | RM367345 | kervincandido@gmail.com |

## Links do projeto

| Item | Link |
|---|---|
| **[infra-meu-historico-saude](https://github.com/KervinCandido/infra-meu-historico-saude)** | https://github.com/KervinCandido/infra-meu-historico-saude |
| **[med-text-analytics-processor](https://github.com/KervinCandido/med-text-analytics-processor)** | https://github.com/KervinCandido/med-text-analytics-processor |
| **[patient-document-service](https://github.com/alex-dev-br/patient-document-service)** | https://github.com/alex-dev-br/patient-document-service |

# Relatório do projeto

## 1. Resumo executivo
O Meu Histórico de Saúde consiste em um cofre digital inteligente voltado para a centralização e organização de documentos clínicos e históricos de saúde dos pacientes. A solução tem como objetivo permitir que o cidadão realize o envio de exames, laudos, receitas e outros registros, os quais são armazenados de forma segura e processados assincronamente por meio de inteligência artificial para a extração de dados estruturados. Esses dados alimentam uma linha do tempo organizada cronologicamente.

O impacto esperado baseia-se no conceito de custódia híbrida: garantir autonomia de armazenamento e portabilidade para os usuários que possuem capacidade tecnológica de gerir seus próprios dados (cofre pessoal), ao mesmo tempo em que oferece proteção e assistência digital para cidadãos em situação de vulnerabilidade (cofre público assistido). Dessa forma, a solução promove a continuidade do cuidado de saúde e reduz gargalos no atendimento médico.

## 2. Problema identificado
O paciente possui o direito de acessar seus dados de saúde, mas, na prática, depara-se com a fragmentação dessas informações, que ficam dispersas em diferentes sistemas, clínicas privadas, hospitais, receitas físicas e exames em papel.

Os problemas específicos identificados na infraestrutura do SUS incluem:
- Dependência de documentos físicos: O uso de papel continua predominante em regiões periféricas, zonas rurais e pequenos municípios devido a limitações de infraestrutura local para a digitalização completa.
- Desconexão com a rede privada: Procedimentos, exames e vacinas realizados pontualmente no setor privado para celeridade do diagnóstico não são consolidados na base de dados do e-SUS.
- Escopo limitado de exames: A visualização de exames no sistema do e-SUS restringe-se historicamente a diagnósticos específicos, o que acarreta a solicitação redundante de novos exames cujos resultados recentes já estariam disponíveis.
- Lacuna no histórico de medicamentos: O e-SUS registra apenas medicamentos dispensados por programas governamentais, omitindo tratamentos adquiridos de forma autônoma pelo paciente.
- Ineficiência na consulta médica: A ausência de um histórico centralizado e estruturado obriga os médicos a reconstruírem o histórico de forma manual e apressada durante a consulta, prejudicando a precisão do atendimento.

## 3. Descrição da solução
A solução propõe um cofre digital de saúde integrado a uma linha do tempo inteligente, organizada por especialidade médica, acessível pelo paciente e compartilhável de forma controlada com profissionais de saúde. O fluxo operacional do sistema compreende:
1. Upload de documento de saúde bruto (exame, receita, laudo ou encaminhamento) pelo próprio paciente ou por um atendente assistido, no formato de PDF, JPG ou PNG.
2. Processamento assíncrono por IA que classifica o arquivo e extrai metadados clínicos importantes (como tipo de documento, data, especialidade provável e resultados de exames), sem emitir diagnósticos.
3. Organização e indexação das informações estruturadas no sistema.
4. Visualização consolidada pelo paciente através de uma linha do tempo cronológica.
5. Compartilhamento temporário de um resumo das informações com o profissional de saúde responsável no momento do atendimento.
6. Aceleração da consulta médica com base em dados consolidados e confiáveis.

O modelo de custódia híbrida garante a inclusão de pessoas com baixa alfabetização digital ou sem acesso a dispositivos adequados através de infraestruturas públicas assistidas (como Unidades Básicas de Saúde).

## 4. Processo de desenvolvimento
O desenvolvimento da solução baseou-se em um plano estruturado de entregas incrementais divididas em etapas lógicas de execução técnica:

- **Definição de Requisitos e Arquitetura**: Foco inicial na definição do escopo do projeto, arquitetura da solução, escolha das tecnologias e definição do formato das mensagens.
- **Microsserviços**: Definição dos microsserviços que compõem a solução, separando-os em dois microserviços para facilitar o gerenciamento e escalabilidade, um para receber os arquivos e enviar para o processamento assíncrono e outro para processar os arquivos com integração com a IA do Google.
- **Prototipação da integração com a LLM**: Prototipação da integração com a LLM (Gemini) com foco na experimentação de prompts e validação do fluxo de processamento de documentos.
- **Definição de linguagem ubíqua e eventos de domínio**: Definição da linguagem ubíqua e dos eventos de domínio para facilitar a comunicação entre os microsserviços.
- **Comunicação via Kafka**: Implementação da comunicação entre microserviços via Apache Kafka.
- **Padrões Outbox/Inbox**: Implementação dos padrão de projeto Outbox e Inbox para garantir o envio e processamento de mensagens com alta confiabilidade.
- **Resiliência**: Implementação de resiliência na integração com a LLM (Gemini), utilizando o `quarkus-smallrye-fault-tolerance` com estratégia de `Retry`, `Fallback`, `CircuitBreaker` e `Ratelimit`.
- **Integração com Nextcloud**: Implementação da integração com o Nextcloud para o repositório seguro dos documentos originais enviados.
- **Integração com Keycloak**: Implementação da integração com o Keycloak para autenticação e autorização via OpenID Connect.
- **Integração com Kong Gateway**: Implementação da integração com o Kong Gateway para centralização do tráfego e roteamento seguro.
- **Implementação do HTTPS/mTLS**: Implementação do HTTPS/mTLS para garantir a segurança da comunicação com o mundo exterior.
- **Docker Compose**: Uso do Docker Compose para orquestração e gerenciamento dos containers.

## 5. Detalhes técnicos
A arquitetura do sistema baseia-se em microserviços orientados a eventos, utilizando os seguintes componentes tecnológicos:
- Gateway de APIs: Kong Gateway para centralização do tráfego HTTPS/mTLS e roteamento seguro.
- Provedor de Identidade (IAM): Keycloak para autenticação e autorização via OpenID Connect.
- Armazenamento de Arquivos: Nextcloud para o repositório seguro dos documentos originais enviados.
- Mensageria: Apache Kafka para comunicação assíncrona e desacoplada entre os microserviços.
- Serviços de Aplicação: Patient Document Service (gestão de documentos) e Med Text Analytics Processor (processador integrado à API do Gemini para extração de informações).
- Bancos de Dados: PostgreSQL (para metadados do Keycloak, Nextcloud e Patient Document Service) e MongoDB (para o processador de texto analítico).
- Orquestração: Docker Compose para execução e gerenciamento dos containers.

Abaixo consta o diagrama da arquitetura implementada:

![Diagrama de Arquitetura](diagrama-arquitetura.jpg)

## 6. Links Úteis
| Item | Link |
|---|---|
| **[infra-meu-historico-saude](https://github.com/KervinCandido/infra-meu-historico-saude)** | https://github.com/KervinCandido/infra-meu-historico-saude |
| **[med-text-analytics-processor](https://github.com/KervinCandido/med-text-analytics-processor)** | https://github.com/KervinCandido/med-text-analytics-processor |
| **[patient-document-service](https://github.com/alex-dev-br/patient-document-service)** | https://github.com/alex-dev-br/patient-document-service |

## 7. Aprendizados e próximos passos

### O que a equipe aprendeu com o projeto?

A equipe desenvolveu uma compreensão profunda sobre arquiteturas orientadas a eventos, padrões de design robustos como Outbox/Inbox, e a importância crítica da segurança em sistemas de saúde. A experiência prática na integração de tecnologias diversas, como Kafka, Keycloak, Kong Gateway e LLMs, demonstrou como compor soluções resilientes e escaláveis. Além disso, o projeto reforçou o valor da prototipação rápida para validar premissas técnicas e a necessidade de clareza nos requisitos para alinhar as expectativas entre diferentes perfis técnicos.

### O que pode ser aprimorado ou adicionado no futuro?

- **Integração com RNDS e FHIR**: Expandir a interoperabilidade para incluir a Rede Nacional de Dados em Saúde (RNDS) e adotar o padrão FHIR para troca de informações.
- **Autenticação Gov.br**: Implementar autenticação centralizada utilizando a plataforma Gov.br.
- **Conectores de Armazenamento Pessoal**: Desenvolver integrações com serviços de nuvem como Google Drive, Dropbox e OneDrive.
- **Compartilhamento Seguro de Exames**: Implementar funcionalidades de compartilhamento temporário via chaves ou QR codes, com revogação de acesso.
- **Processador de Análise de Texto**: Calibrar a IA para classificação automática de documentos por especialidade médica com índices de confiança.
