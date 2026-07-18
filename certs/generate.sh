#!/bin/bash

source .env

export MSYS_NO_PATHCONV=1

# Define a pasta raiz de saída de forma organizada
BASE_DIR="."

# Limpa gerações antigas com segurança dentro da estrutura de pastas
if [ -d "$BASE_DIR" ]; then
    echo "Limpando certificados antigos..."
    find "$BASE_DIR" -type f \( -name "*.csr" -o -name "*.srl" -o -name "*.p12" -o -name "*.crt" -o -name "*.key" \) -delete
fi

# Estrutura a pasta global da CA
CA_DIR="$BASE_DIR/ca"
mkdir -p "$CA_DIR"

CA_CRT="$CA_DIR/ca.crt"
CA_KEY="$CA_DIR/ca.key"
CA_TRUSTSTORE="$CA_DIR/ca-truststore.p12"


# Gerar a chave da CA e o certificado raiz
echo "Gerando Autoridade Certificadora (CA)..."
openssl genrsa -out "$CA_KEY" 2048
openssl req -x509 -new -nodes -key "$CA_KEY" -sha256 -days 1024 -out "$CA_CRT" -subj "/C=BR/ST=SaoPaulo/L=SaoPaulo/O=Kervin/OU=IT/CN=meu-historico-saude-ca"

# --- TRUSTSTORE (Salva na pasta global da CA para os serviços usarem) ---
keytool -importcert -trustcacerts -file "$CA_CRT" -keystore "$CA_TRUSTSTORE" -storepass "${PASSWORD}" -noprompt

# Lista de serviços atualizada[cite: 7]
SERVICOS=("kong" "patient-document" "nextcloud" "keycloak" "med-text-analytics-processor")

# Loop para processar cada item da lista[cite: 7]
for item in "${SERVICOS[@]}"; do
    echo "--------------------------------------------------"
    echo "Processando certificado para: $item"
    echo "--------------------------------------------------"

    # O arquivo de configuração SAN continua na raiz do seu projeto
    CONFIG_CNF="san_${item}.cnf"

    # Validação: verifica se o arquivo .cnf existe[cite: 7]
    if [ ! -f "$CONFIG_CNF" ]; then
        echo "Erro: O arquivo de configuração '$CONFIG_CNF' não foi encontrado!"
        echo "Pulando '$item'..."
        continue
    fi

    # Cria a pasta exclusiva para o serviço atual
    TARGET_DIR="$BASE_DIR/$item"
    mkdir -p "$TARGET_DIR"

    # Copia CA para pasta de cada um
    cp $CA_TRUSTSTORE "$TARGET_DIR/ca-truststore.p12"
    cp $CA_CRT "$TARGET_DIR/ca.crt"

    # 1. Gerar a chave privada dentro da pasta do serviço
    echo "[1/4] Gerando chave privada ($TARGET_DIR/${item}.key)..."
    openssl genrsa -out "$TARGET_DIR/${item}.key" 2048

    # 2. Criar o pedido (CSR) usando o arquivo de configuração SAN
    echo "[2/4] Criando CSR ($TARGET_DIR/${item}.csr)..."
    openssl req -new -key "$TARGET_DIR/${item}.key" -out "$TARGET_DIR/${item}.csr" -config "$CONFIG_CNF"

    # 3. Assinar o certificado com a CA
    echo "[3/4] Assinando o certificado ($TARGET_DIR/${item}.crt)..."
    openssl x509 -req \
        -in "$TARGET_DIR/${item}.csr" \
        -CA "$CA_CRT" \
        -CAkey "$CA_KEY" \
        -CAcreateserial \
        -out "$TARGET_DIR/${item}.crt" \
        -days 365 \
        -sha256 \
        -extfile "$CONFIG_CNF" \
        -extensions v3_req

    # 4. Gerar o arquivo PKCS12 (.p12) dentro da pasta do serviço
    echo "[4/4] Empacotando em PKCS12 ($TARGET_DIR/${item}.p12)..."
    openssl pkcs12 -export \
        -in "$TARGET_DIR/${item}.crt" \
        -out "$TARGET_DIR/${item}.p12" \
        -certfile "$CA_CRT" \
        -inkey "$TARGET_DIR/${item}.key" \
        -name "Certificado ${item}" \
        -passout pass:"${PASSWORD}"

    echo "Sucesso! Arquivos para '$item' gerados em: $TARGET_DIR"
done

echo "--------------------------------------------------"
echo "Processo finalizado!"