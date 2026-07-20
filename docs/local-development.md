# Desenvolvimento local

A infraestrutura possui dois modos de execução.

## Modo integrado

Utiliza as imagens publicadas nos registros de containers.

```powershell
docker compose pull

docker compose up -d --wait
```

Por padrão, são utilizadas as seguintes imagens:

```text
ghcr.io/alex-dev-br/patient-document-service:main
ghcr.io/kervincandido/med-text-analytics-processor:main
```

As imagens podem ser sobrescritas pelo arquivo `.env`:

```text
PATIENT_DOCUMENT_IMAGE=ghcr.io/alex-dev-br/patient-document-service:main
MED_TEXT_ANALYTICS_IMAGE=ghcr.io/kervincandido/med-text-analytics-processor:main
```

## Modo de desenvolvimento local

O `docker-compose.local.yml` constrói o Patient Document Service e o Med Text Analytics Processor diretamente dos repositórios locais.

A estrutura esperada é:

```text
C:\Dev
├── infra-meu-historico-saude
├── patient-document-service
└── med-text-analytics-processor
```

Para iniciar toda a infraestrutura com os dois serviços construídos localmente:

```powershell
docker compose `
    -f docker-compose.yml `
    -f docker-compose.local.yml `
    up -d --build --wait
```

Para reconstruir somente o Patient Document Service:

```powershell
docker compose `
    -f docker-compose.yml `
    -f docker-compose.local.yml `
    up -d --build --force-recreate --no-deps `
    patient-document-service
```

Para reconstruir somente o Med Text Analytics Processor:

```powershell
docker compose `
    -f docker-compose.yml `
    -f docker-compose.local.yml `
    up -d --build --force-recreate --no-deps `
    med-text-analytics-processor-service
```

Para reconstruir os dois serviços:

```powershell
docker compose `
    -f docker-compose.yml `
    -f docker-compose.local.yml `
    up -d --build --force-recreate --no-deps `
    patient-document-service `
    med-text-analytics-processor-service
```

O arquivo local substitui somente as imagens e adiciona os contextos de build dos dois serviços.
As redes, volumes, certificados, variáveis, limites de recursos e dependências são herdados do `docker-compose.yml`.

## Encerramento

Para encerrar os containers preservando os volumes:

```powershell
docker compose `
    -f docker-compose.yml `
    -f docker-compose.local.yml `
    down
```

Não utilize `down -v`, pois essa opção remove os volumes persistentes.
