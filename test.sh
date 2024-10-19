#!/bin/bash

# Recebe as variáveis passadas como argumentos
CLIENT_ID=$1
CLIENT_SECRET=$2
INPUT_DATA=$3  # Novo argumento para o input_data

# Executa o curl e captura a resposta
response=$(curl --request POST \
  --url https://idm.stackspot.com/zup/oidc/oauth/token \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data client_id=$CLIENT_ID \
  --data grant_type=client_credentials \
  --data client_secret=$CLIENT_SECRET)

# Exibe a resposta completa para depuração
echo "Resposta do primeiro curl (token): $response"

# Extrai o access_token da resposta usando grep e sed
access_token=$(echo $response | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"\([^"]*\)"/\1/')

# Verifica se o access_token foi extraído corretamente
if [ -z "$access_token" ]; then
  echo "Erro: access_token não encontrado!"
  exit 1
fi

echo "Access Token: $access_token"

# Executa o segundo curl usando o access_token e o input_data parametrizado
id=$(curl --request POST \
  --url 'https://genai-code-buddy-api.stackspot.com/v1/quick-commands/create-execution/testremote' \
  --header "Authorization: Bearer $access_token" \
  --header 'Content-Type: application/json' \
  --data "{\"input_data\": \"$INPUT_DATA\"}")

# Exibe a resposta completa do segundo curl para depuração
echo "Resposta completa do segundo curl: $id"

# Extrai o ID da resposta (removendo as aspas)
id=$(echo $id | grep -o '"execution_id":"[^"]*"' | sed 's/"execution_id":"\([^"]*\)"/\1/')
echo "ID retornado pelo segundo curl: $id"

# Adiciona uma latência de 10 segundos antes de executar o terceiro curl
echo "Aguardando 10 segundos antes de executar o terceiro curl..."
sleep 10

# Executa o terceiro curl usando o ID
result=$(curl --request GET \
  --url "https://genai-code-buddy-api.stackspot.com/v1/quick-commands/callback/$id" \
  --header "Authorization: Bearer $access_token")

# Exibe a resposta do terceiro curl
echo "Resposta do terceiro curl: $result"

# Extrai o campo 'answer' da resposta usando grep e sed
answer=$(echo $result)

# Exibe o valor do campo 'answer'
echo "Campo 'answer': $answer"