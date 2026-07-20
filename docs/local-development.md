# Desenvolvimento local

A infraestrutura possui dois modos de execução.

## Modo integrado

Utiliza as imagens publicadas nos registros de containers.

```powershell
docker compose pull

docker compose up -d --wait
```

Por padrão, o Patient Document Service utiliza:

```text
ghcr.io/alex-dev-br/patient-document-service:main
```

As imagens podem ser sobrescritas pelo arquivo `.env`:

```text
PATIENT_DOCUMENT_IMAGE=ghcr.io/alex-dev-br/patient-document-service:main
MED_TEXT_ANALYTICS_IMAGE=kervincandido/med-text-analytics-processor:latest
```

## Modo de desenvolvimento local

O `docker-compose.local.yml` constrói o Patient Document Service diretamente do repositório local.

A estrutura esperada é:

```text
C:\Dev
├── infra-meu-historico-saude
└── patient-document-service
```

Para iniciar:

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
    up -d --build --force-recreate `
    patient-document-service
```

O arquivo local substitui somente a imagem do Patient Document Service.
As redes, volumes, certificados, variáveis e dependências são herdados do `docker-compose.yml`.

## Encerramento

Para encerrar os containers preservando os volumes:

```powershell
docker compose `
    -f docker-compose.yml `
    -f docker-compose.local.yml `
    down
```

Não utilize `down -v`, pois essa opção remove os volumes persistentes.
