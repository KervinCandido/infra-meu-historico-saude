# infra-meu-historico-saude

Este repositório contém a infraestrutura e a definição dos serviços que compõem a solução **Meu Histórico de Saúde**. A arquitetura é baseada em microserviços, utilizando o **Kong Gateway** como ponto único de entrada, **Keycloak** para autenticação e autorização (IAM), **Apache Kafka** para mensageria/eventos, **Nextcloud** como provedor de armazenamento de arquivos e bancos de dados dedicados para cada componente.

## Desenho da Arquitetura

O diagrama abaixo ilustra a arquitetura da solução e a comunicação entre os componentes:

```mermaid
flowchart TB
    %% Estilos e Definições de Cores
    classDef client fill:#eceff1,stroke:#37474f,stroke-width:2px,color:#000000;
    classDef gateway fill:#e8eaf6,stroke:#3f51b5,stroke-width:2px,stroke-dasharray: 5 5,color:#000000;
    classDef service fill:#e1f5fe,stroke:#0288d1,stroke-width:2px,color:#000000;
    classDef database fill:#efebe9,stroke:#5d4037,stroke-width:2px,color:#000000;
    classDef message fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000000;
    classDef ext fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000000;
    classDef dev fill:#f1f8e9,stroke:#689f38,stroke-width:2px,color:#000000;

    %% Nodes / Componentes
    Client["📱 Cliente / Consumidor<br>(HTTPS:8443)"]:::client
    Gemini["🧠 Gemini API<br>(Classificação & Extração)"]:::ext

    subgraph GW ["Camada de API Gateway & Segurança"]
        Kong["🚦 Kong Gateway<br>(kong-gateway)"]:::gateway
        Keycloak["🔐 Keycloak<br>(keycloak-service)"]:::service
        DB_Keycloak[("💾 Postgres Keycloak<br>(postgres-keycloak)")]:::database
    end

    subgraph App ["Serviços da Aplicação"]
        PatientDoc["📄 Patient Document Service<br>(patient-document-service)"]:::service
        MedText["🧪 Med Text Analytics Processor<br>(med-text-analytics-processor)"]:::service
    end

    subgraph Storage ["Camada de Armazenamento & Dados"]
        Nextcloud["☁️ Nextcloud<br>(nextcloud)"]:::service
        DB_Nextcloud[("💾 Postgres Nextcloud<br>(postgres-nextcloud)")]:::database
        DB_PatientDoc[("💾 Postgres Patient Doc<br>(postgres-patient-document)")]:::database
        DB_Mongo[("💾 MongoDB Text Processor<br>(mongo-text-processor)")]:::database
    end

    subgraph Messaging ["Camada de Mensageria (Event-Driven)"]
        Kafka["🎼 Apache Kafka<br>(apache-kafka-broker)"]:::message
    end

    subgraph Tools ["Ferramentas de Desenvolvimento (DevTools Profile)"]
        KafkaUI["📊 Kafka UI<br>(Port 8181)"]:::dev
        MongoExpress["🗂️ Mongo Express<br>(Port 8081)"]:::dev
    end

    %% Relacionamentos e Fluxos
    Client -->|HTTPS / mTLS| Kong
    Kong -->|Roteamento / HTTPS| Keycloak
    Kong -->|Roteamento / HTTPS| PatientDoc

    %% Relacionamentos do Keycloak
    Keycloak --> DB_Keycloak
    PatientDoc -->|Validação de Token / IAM| Keycloak

    %% Fluxos do Patient Document Service
    PatientDoc --> DB_PatientDoc
    PatientDoc -->|Upload/Leitura de Arquivos| Nextcloud
    PatientDoc -->|Publica Eventos| Kafka

    %% Fluxos do Med Text Analytics Processor
    Kafka -->|Consome Eventos| MedText
    MedText --> DB_Mongo
    MedText -->|Download de Arquivos| Nextcloud
    MedText -->|Extração de Texto| Gemini

    %% Armazenamento
    Nextcloud --> DB_Nextcloud

    %% Ferramentas de Dev
    KafkaUI -.->|Monitoramento| Kafka
    MongoExpress -.->|Visualização| DB_Mongo
```

---

## Componentes da Arquitetura

### 1. Gateway & Segurança
*   **Kong Gateway (`kong-gateway`)**: Atua como o API Gateway da aplicação, centralizando o tráfego de entrada via HTTPS/mTLS (porta `8443`) e realizando o roteamento inteligente para os serviços internos (`patient-document-service` e `keycloak-service`).
*   **Keycloak (`keycloak-service`)**: Provedor de Identidade e Acesso (IAM) responsável pela autenticação e autorização, utilizando protocolo OpenID Connect (OIDC).
*   **Postgres Keycloak (`postgres-keycloak`)**: Banco de dados relacional dedicado para armazenar configurações, usuários e realms do Keycloak.

### 2. Serviços da Aplicação
*   **Patient Document Service (`patient-document-service`)**: Microserviço responsável pela gestão dos documentos de saúde dos pacientes. Integra-se com o Nextcloud para armazenamento de arquivos e publica mensagens no Kafka ao registrar novos documentos.
*   **Postgres Patient Doc (`postgres-patient-document`)**: Banco de dados relacional dedicado para armazenar os metadados dos documentos dos pacientes.
*   **Med Text Analytics Processor (`med-text-analytics-processor`)**: Processador assíncrono que consome eventos do Kafka, baixa os documentos do Nextcloud, extrai informações clínicas relevantes utilizando a **API do Gemini** e armazena os resultados processados.
*   **MongoDB Text Processor (`mongo-text-processor`)**: Banco de dados NoSQL utilizado para armazenar os textos processados e as análises médicas estruturadas.

### 3. Armazenamento de Arquivos
*   **Nextcloud (`nextcloud`)**: Solução de armazenamento em nuvem privada utilizada como repositório seguro para guardar as imagens dos exames/documentos médicos.
*   **Postgres Nextcloud (`postgres-nextcloud`)**: Banco de dados relacional dedicado às operações internas do Nextcloud.

### 4. Mensageria & Integração Event-Driven
*   **Apache Kafka (`apache-kafka-broker`)**: Broker de mensageria responsável pela comunicação assíncrona entre o `patient-document-service` e o `med-text-analytics-processor`.

### 5. Ferramentas de Desenvolvimento (Perfil `devtools`)
*   **Kafka UI**: Interface gráfica rodando na porta `8181` para visualização e gerenciamento de tópicos, partições e mensagens do Kafka.
*   **Mongo Express**: Interface administrativa baseada em web para gerenciar e visualizar os dados no MongoDB (porta `8081`).
