#!/bin/bash

# Recebe as variáveis passadas como argumentos
CLIENT_ID=$1
CLIENT_SECRET=$2
INPUT_DATA=$3  # Novo argumento para o input_data

# Executa o curl e captura a resposta para obter o access_token
access_token=$(curl --silent --request POST \
  --url https://idm.stackspot.com/zup/oidc/oauth/token \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data client_id=$CLIENT_ID \
  --data grant_type=client_credentials \
  --data client_secret=$CLIENT_SECRET | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"\([^"]*\)"/\1/')

# Verifica se o access_token foi extraído corretamente
if [ -z "$access_token" ]; then
  echo "Erro: access_token não encontrado!"
  exit 1
fi

# Executa o segundo curl usando o access_token e o input_data parametrizado
id=$(curl --silent --request POST \
  --url 'https://genai-code-buddy-api.stackspot.com/v1/quick-commands/create-execution/testremote' \
  --header "Authorization: Bearer $access_token" \
  --header 'Content-Type: application/json' \
  --data "{\"input_data\": \"$INPUT_DATA\"}" | sed 's/"//g')

# Verifica se o ID foi extraído corretamente
if [ -z "$id" ]; then
  echo "Erro: ID não encontrado na resposta!"
  exit 1
fi

# Aguardando 10 segundos antes de executar o terceiro curl
sleep 30

# Executa o terceiro curl usando o ID
result=$(curl --silent --request GET \
  --url "https://genai-code-buddy-api.stackspot.com/v1/quick-commands/callback/$id" \
  --header "Authorization: Bearer $access_token")

# Extrai o campo 'answer' da resposta
answer=$(echo $result | grep -o '"answer":"[^"]*' | sed 's/"answer":"//')

# Exibe o valor do campo 'answer', ou erro se não for encontrado
if [ -z "$answer" ]; then
  echo "Erro: Campo 'answer' não encontrado na resposta!"
  exit 1
fi

echo "$answer"
