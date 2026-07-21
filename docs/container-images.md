# Tutorial — Imagens Docker locais e publicação automática no GHCR

> **GHCR** significa **GitHub Container Registry**. É o registro de imagens Docker integrado ao GitHub.

Neste projeto existem duas formas de trabalhar com as imagens:

```text
Desenvolvimento local
Código atual da máquina → Dockerfile → imagem :local

Integração/publicação
Código versionado no GitHub → GitHub Actions → imagem no GHCR
```

---

## 1. Imagens utilizadas pelo projeto

### Patient Document Service

```text
Local:
meu-historico-saude/patient-document-service:local

GHCR:
ghcr.io/alex-dev-br/patient-document-service:main
```

### Processador de documentos

```text
Local:
meu-historico-saude/med-text-analytics-processor:local

GHCR:
ghcr.io/kervincandido/med-text-analytics-processor:main
```

O `docker-compose.yml` principal usa por padrão as imagens do GHCR. Já o `docker-compose.local.yml` substitui essas referências pelas imagens locais e informa onde estão os respectivos Dockerfiles.

---

# 2. Como a imagem local é construída

Os três repositórios devem estar lado a lado:

```text
C:\Dev\
├── infra-meu-historico-saude
├── patient-document-service
└── med-text-analytics-processor
```

Isso é necessário porque o Compose local usa caminhos relativos:

```yaml
build:
  context: ../patient-document-service
```

e:

```yaml
build:
  context: ../med-text-analytics-processor
```

## Fluxo da construção

Quando executamos:

```powershell
docker compose `
    -f .\docker-compose.yml `
    -f .\docker-compose.local.yml `
    build `
    patient-document-service
```

o Docker Compose:

1. carrega as configurações gerais do `docker-compose.yml`;
2. aplica as substituições do `docker-compose.local.yml`;
3. entra no repositório `patient-document-service`;
4. lê o `Dockerfile`;
5. compila a aplicação;
6. gera a imagem local;
7. atribui a tag:

```text
meu-historico-saude/patient-document-service:local
```

---

# 3. Validar o código antes da imagem

O Dockerfile usa:

```dockerfile
RUN mvn clean package -DskipTests
```

Isso significa que os testes não são executados durante a construção da imagem. Eles devem ser executados antes.

## Patient Document Service

```powershell
cd C:\Dev\patient-document-service

mvn clean test
```

Resultado esperado:

```text
Tests run: 33
Failures: 0
Errors: 0
BUILD SUCCESS
```

## Processador

```powershell
cd C:\Dev\med-text-analytics-processor

mvn clean verify
```

Resultado esperado:

```text
BUILD SUCCESS
```

---

# 4. Construir o Patient Document Service localmente

Entre no repositório da infraestrutura:

```powershell
cd C:\Dev\infra-meu-historico-saude
```

## Construção normal

```powershell
docker compose `
    -f .\docker-compose.yml `
    -f .\docker-compose.local.yml `
    build `
    patient-document-service
```

Essa opção reaproveita o cache do Docker.

## Construção sem cache

Use durante validações importantes ou quando houver dúvida sobre camadas antigas:

```powershell
docker compose `
    -f .\docker-compose.yml `
    -f .\docker-compose.local.yml `
    build `
    --no-cache `
    patient-document-service
```

A construção que acabamos de executar foi concluída com sucesso e gerou:

```text
meu-historico-saude/patient-document-service:local
```



## Conferir a imagem

```powershell
docker image inspect `
    meu-historico-saude/patient-document-service:local `
    --format `
    'Image={{.Id}} Created={{.Created}}'
```

Também é possível listar as imagens:

```powershell
docker image ls `
    meu-historico-saude/patient-document-service
```

---

# 5. Construir o processador localmente

```powershell
cd C:\Dev\infra-meu-historico-saude

docker compose `
    -f .\docker-compose.yml `
    -f .\docker-compose.local.yml `
    build `
    med-text-analytics-processor-service
```

Sem cache:

```powershell
docker compose `
    -f .\docker-compose.yml `
    -f .\docker-compose.local.yml `
    build `
    --no-cache `
    med-text-analytics-processor-service
```

Conferir:

```powershell
docker image inspect `
    meu-historico-saude/med-text-analytics-processor:local `
    --format `
    'Image={{.Id}} Created={{.Created}}'
```

---

# 6. Construir as duas imagens locais

```powershell
cd C:\Dev\infra-meu-historico-saude

docker compose `
    -f .\docker-compose.yml `
    -f .\docker-compose.local.yml `
    build
```

Sem cache:

```powershell
docker compose `
    -f .\docker-compose.yml `
    -f .\docker-compose.local.yml `
    build `
    --no-cache
```

Nesse caso, todos os serviços que possuem uma configuração `build` no Compose local serão construídos.

---

# 7. Iniciar a stack usando as imagens locais

Para iniciar toda a stack com as imagens locais:

```powershell
docker compose `
    -f .\docker-compose.yml `
    -f .\docker-compose.local.yml `
    up `
    -d
```

Para recriar apenas o Patient Document Service, quando as dependências já estiverem em execução:

```powershell
docker compose `
    -f .\docker-compose.yml `
    -f .\docker-compose.local.yml `
    up `
    -d `
    --no-deps `
    --force-recreate `
    patient-document-service
```

Para recriar apenas o processador:

```powershell
docker compose `
    -f .\docker-compose.yml `
    -f .\docker-compose.local.yml `
    up `
    -d `
    --no-deps `
    --force-recreate `
    med-text-analytics-processor-service
```

Conferir os serviços:

```powershell
docker compose ps
```

Conferir qual imagem um container está utilizando:

```powershell
docker inspect `
    patient-document-service `
    --format `
    'Image={{.Config.Image}} ImageId={{.Image}}'
```

---

# 8. O que o Dockerfile faz

O Dockerfile do Patient Document Service possui duas etapas.

## Etapa 1 — Compilação

```dockerfile
FROM maven:3.9.16-eclipse-temurin-25-alpine AS builder
```

Nessa etapa:

1. utiliza Maven com Java 25;
2. copia o `pom.xml`;
3. baixa as dependências;
4. copia o código-fonte;
5. gera o arquivo JAR.

```dockerfile
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests
```

## Etapa 2 — Execução

```dockerfile
FROM eclipse-temurin:25-jre-alpine-3.23
```

Nessa etapa:

1. utiliza somente o JRE;
2. cria um usuário sem privilégios administrativos;
3. copia apenas o JAR final;
4. inicia a aplicação.

```dockerfile
RUN addgroup -S appgroup &&
    adduser -S -D -H -G appgroup appuser

COPY --from=builder \
    --chown=appuser:appgroup \
    /app/target/*.jar \
    app.jar

USER appuser:appgroup

ENTRYPOINT ["java", "-jar", "app.jar"]
```

Isso reduz o tamanho final da imagem e evita executar a aplicação como `root`.

---

# 9. Como a imagem é gerada automaticamente no GHCR

Cada repositório possui o workflow:

```text
.github/workflows/container-image.yml
```

Esse arquivo é executado pelo **GitHub Actions**.

## Pull Request para `main`

Quando um Pull Request é aberto ou atualizado:

```text
Pull Request
→ checkout do código
→ configuração do Docker Buildx
→ construção da imagem
→ validação do Dockerfile
→ imagem não é publicada
```

O workflow possui:

```yaml
push: ${{ github.event_name != 'pull_request' }}
```

Portanto, em Pull Requests a imagem é construída, mas não enviada ao GHCR.

Isso evita publicar imagens de código que ainda não foi integrado.

---

## Push ou merge na `main`

Quando o código chega à branch `main`:

```text
Merge na main
→ GitHub Actions
→ build da imagem
→ login automático no GHCR
→ publicação da imagem
```

O login usa:

```yaml
username: ${{ github.actor }}
password: ${{ secrets.GITHUB_TOKEN }}
```

Não é necessário cadastrar manualmente um token do GHCR para o workflow. O GitHub fornece um `GITHUB_TOKEN` temporário para aquela execução.

A permissão utilizada é:

```yaml
permissions:
  contents: read
  packages: write
```

---

# 10. Tags publicadas

O workflow utiliza o `docker/metadata-action` para gerar as tags.

## Tag da branch principal

Após um push na `main`:

```text
ghcr.io/alex-dev-br/patient-document-service:main
```

e:

```text
ghcr.io/kervincandido/med-text-analytics-processor:main
```

A tag `main` é atualizada a cada nova publicação.

## Tag do commit

Também é criada uma tag associada ao commit:

```text
sha-<identificador-do-commit>
```

Exemplo conceitual:

```text
ghcr.io/alex-dev-br/patient-document-service:sha-a1b2c3d
```

A vantagem dessa tag é permitir identificar exatamente qual código gerou a imagem.

## Tags de versão

Quando for criada uma tag Git:

```text
v1.2.3
```

o workflow pode publicar:

```text
:1.2.3
:1.2
:sha-<commit>
```

Assim:

* `main` representa a versão mais recente da branch principal;
* `sha-*` representa um commit específico;
* `1.2.3` representa uma versão de lançamento.

---

# 11. Baixar uma imagem do GHCR

## Patient Document Service

```powershell
docker pull `
    ghcr.io/alex-dev-br/patient-document-service:main
```

## Processador

```powershell
docker pull `
    ghcr.io/kervincandido/med-text-analytics-processor:main
```

Conferir:

```powershell
docker image inspect `
    ghcr.io/alex-dev-br/patient-document-service:main `
    --format `
    'Image={{.Id}} Created={{.Created}}'
```

---

# 12. Executar a stack com as imagens do GHCR

Para utilizar as imagens oficiais, execute somente o Compose principal, sem o arquivo `docker-compose.local.yml`:

```powershell
cd C:\Dev\infra-meu-historico-saude

docker compose pull `
    patient-document-service `
    med-text-analytics-processor-service
```

Depois:

```powershell
docker compose up `
    -d `
    --no-deps `
    --force-recreate `
    patient-document-service `
    med-text-analytics-processor-service
```

A diferença principal é:

```text
Com docker-compose.local.yml:
usa imagens :local construídas a partir da máquina

Sem docker-compose.local.yml:
usa imagens :main baixadas do GHCR
```

---

# 13. Fluxo recomendado de desenvolvimento

```text
1. Alterar o código em uma branch
2. Executar os testes Maven
3. Construir a imagem local
4. Executar o container local
5. Validar o fluxo integrado
6. Fazer commit
7. Abrir Pull Request
8. GitHub Actions valida os testes
9. GitHub Actions valida a imagem
10. Fazer merge na main
11. GitHub Actions publica a imagem no GHCR
12. Infraestrutura baixa e executa a imagem oficial
```

## Exemplo completo

```powershell
cd C:\Dev\patient-document-service

mvn clean test
```

```powershell
cd C:\Dev\infra-meu-historico-saude

docker compose `
    -f .\docker-compose.yml `
    -f .\docker-compose.local.yml `
    build `
    --no-cache `
    patient-document-service
```

```powershell
docker compose `
    -f .\docker-compose.yml `
    -f .\docker-compose.local.yml `
    up `
    -d `
    --no-deps `
    --force-recreate `
    patient-document-service
```

```powershell
docker compose ps
docker logs patient-document-service --tail 100
```

---

# 14. Resumo das diferenças

| Característica            | Imagem local            | Imagem GHCR                     |
| ------------------------- | ----------------------- | ------------------------------- |
| Origem                    | Código atual da máquina | Código versionado no GitHub     |
| Alterações não commitadas | Incluídas               | Não incluídas                   |
| Tag                       | `:local`                | `:main`, `:sha-*`, versão       |
| Construção                | Docker Desktop local    | GitHub Actions                  |
| Armazenamento             | Apenas na máquina       | GitHub Container Registry       |
| Uso principal             | Desenvolvimento e teste | Integração e implantação        |
| Compartilhamento          | Não automático          | Disponível para outras máquinas |
| Rastreabilidade           | ID local da imagem      | Tag SHA e labels do commit      |


