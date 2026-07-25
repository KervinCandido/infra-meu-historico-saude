# Relatório do projeto
Objetivo: documentar o processo de desenvolvimento e facilitar a avaliação detalhada.

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
1. Upload de documento de saúde bruto (exame, receita, laudo ou encaminhamento) pelo próprio paciente ou por um atendente assistido.
2. Processamento assíncrono por IA que classifica o arquivo e extrai metadados clínicos importantes (como tipo de documento, data, especialidade provável e resultados de exames), sem emitir diagnósticos.
3. Organização e indexação das informações estruturadas no sistema.
4. Visualização consolidada pelo paciente através de uma linha do tempo cronológica.
5. Compartilhamento temporário de um resumo das informações com o profissional de saúde responsável no momento do atendimento.
6. Aceleração da consulta médica com base em dados consolidados e confiáveis.

O modelo de custódia híbrida garante a inclusão de pessoas com baixa alfabetização digital ou sem acesso a dispositivos adequados através de infraestruturas públicas assistidas (como Unidades Básicas de Saúde).

## 4. Processo de desenvolvimento
O desenvolvimento da solução baseou-se em um plano estruturado de entregas incrementais divididas em etapas lógicas de execução técnica:
- Modelagem de Integração e Processamento: Foco inicial na definição do contrato de resposta agregado do processador e na integração com a API de inteligência artificial de maneira assíncrona.
- Persistência e Consumo de Mensageria: Implementação do consumo de eventos e garantia de idempotência no serviço de documentos do paciente, estruturando o banco de dados de destino e atualizando a linha do tempo.
- Estabilização e Portabilidade: Ajustes finais de autenticação, geração do pacote de portabilidade de dados e preparação do ambiente de testes integrados.

- TO DO: Detalhar o processo de brainstorming, etapas de design thinking e prototipação conduzidos pela equipe.

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

```mermaid
flowchart TB
    classDef client fill:#eceff1,stroke:#37474f,stroke-width:2px,color:#000000;
    classDef gateway fill:#e8eaf6,stroke:#3f51b5,stroke-width:2px,stroke-dasharray: 5 5,color:#000000;
    classDef service fill:#e1f5fe,stroke:#0288d1,stroke-width:2px,color:#000000;
    classDef database fill:#efebe9,stroke:#5d4037,stroke-width:2px,color:#000000;
    classDef message fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000000;
    classDef ext fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000000;
    classDef dev fill:#f1f8e9,stroke:#689f38,stroke-width:2px,color:#000000;

    Client["Cliente / Consumidor (HTTPS:8443)"]:::client
    Gemini["Gemini API (Classificacao & Extracao)"]:::ext

    subgraph GW ["Camada de API Gateway & Seguranca"]
        Kong["Kong Gateway (kong-gateway)"]:::gateway
        Keycloak["Keycloak (keycloak-service)"]:::service
        DB_Keycloak[("Postgres Keycloak (postgres-keycloak)")]:::database
    end

    subgraph App ["Servicos da Aplicacao"]
        PatientDoc["Patient Document Service (patient-document-service)"]:::service
        MedText["Med Text Analytics Processor (med-text-analytics-processor)"]:::service
    end

    subgraph Storage ["Camada de Armazenamento & Dados"]
        Nextcloud["Nextcloud (nextcloud)"]:::service
        DB_Nextcloud[("Postgres Nextcloud (postgres-nextcloud)")]:::database
        DB_PatientDoc[("Postgres Patient Doc (postgres-patient-document)")]:::database
        DB_Mongo[("MongoDB Text Processor (mongo-text-processor)")]:::database
    end

    subgraph Messaging ["Camada de Mensageria (Event-Driven)"]
        Kafka["Apache Kafka (apache-kafka-broker)"]:::message
    end

    subgraph Tools ["Ferramentas de Desenvolvimento"]
        KafkaUI["Kafka UI (Port 8181)"]:::dev
        MongoExpress["Mongo Express (Port 8081)"]:::dev
    end

    Client -->|HTTPS / mTLS| Kong
    Kong -->|Roteamento / HTTPS| Keycloak
    Kong -->|Roteamento / HTTPS| PatientDoc

    Keycloak --> DB_Keycloak
    PatientDoc -->|Validacao de Token / IAM| Keycloak

    PatientDoc --> DB_PatientDoc
    PatientDoc -->|Upload/Leitura de Arquivos| Nextcloud
    PatientDoc -->|Publica Eventos| Kafka

    Kafka -->|Consome Eventos| MedText
    MedText --> DB_Mongo
    MedText -->|Download de Arquivos| Nextcloud
    MedText -->|Extracao de Texto| Gemini

    Nextcloud --> DB_Nextcloud

    KafkaUI -.->|Monitoramento| Kafka
    MongoExpress -.->|Visualizacao| DB_Mongo
```

## 6. Links Úteis
- TO DO: Inserir o link do repositorio de codigo do projeto (GitHub/GitLab).
- [Narrativa e Escopo do MVP](file:///d:/workspace/fiap-hackathon-10ADJT/docs/mvp-hackathon-custodia-hibrida.md)
- [Guia de Desenvolvimento Local](file:///d:/workspace/fiap-hackathon-10ADJT/docs/local-development.md)

## 7. Aprendizados e próximos passos

### O que a equipe aprendeu com o projeto?
- TO DO: Relatar as principais licoes aprendidas, desafios de integracao superados e competencias adquiridas durante o desenvolvimento da solucao.

### O que pode ser aprimorado ou adicionado no futuro?
- Integrar a solucao com a Rede Nacional de Dados em Saude (RNDS) e adotar o padrao de interoperabilidade FHIR (Fast Healthcare Interoperability Resources).
- Implementar autenticacao centralizada via integracao oficial com a plataforma Gov.br.
- Desenvolver conectores de armazenamento pessoal para provedores de nuvem privada (como Google Drive, Dropbox e OneDrive).
- Habilitar o compartilhamento temporario de exames com profissionais de saude por meio de chaves temporarias ou codigos QR, com funcionalidade completa de revogacao de acesso.
- Estruturar o cofre publico assistido para permitir a delegacao de acesso a representantes legais e suporte a prontuarios multiprofissionais integrados.
- Calibrar o processador de analise de texto para classificar documentos por especialidade medica de forma automatica com indices de confianca definidos.
