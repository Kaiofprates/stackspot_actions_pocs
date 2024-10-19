#!/bin/bash

# Recebe as variáveis passadas como argumentos
CLIENT_ID=$1
CLIENT_SECRET=$2
INPUT_DATA=$3  # Novo argumento para o input_data

# Função para exibir mensagem de erro e encerrar o script
erro_e_sair() {
  echo "$1"
  exit 1
}

# Executa o curl e captura a resposta para obter o access_token
access_token=$(curl --silent --request POST \
  --url https://idm.stackspot.com/zup/oidc/oauth/token \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data client_id=$CLIENT_ID \
  --data grant_type=client_credentials \
  --data client_secret=$CLIENT_SECRET | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"\([^"]*\)"/\1/')

# Verifica se o access_token foi extraído corretamente
[ -z "$access_token" ] && erro_e_sair "Erro: access_token não encontrado!"

# Executa o segundo curl usando o access_token e o input_data parametrizado
id=$(curl --silent --request POST \
  --url 'https://genai-code-buddy-api.stackspot.com/v1/quick-commands/create-execution/testremote' \
  --header "Authorization: Bearer $access_token" \
  --header 'Content-Type: application/json' \
  --data "{\"input_data\": \"$INPUT_DATA\"}" | sed 's/"//g')

# Verifica se o ID foi extraído corretamente
[ -z "$id" ] && erro_e_sair "Erro: ID não encontrado na resposta!"

# Aguardando 10 segundos antes de iniciar as tentativas de obter a resposta
sleep 10

# Função de retry para obter o campo 'answer'
obter_resposta() {
  for i in {1..5}; do
    echo "Tentativa $i de 5 para obter o campo 'answer'..."
    
    result=$(curl --silent --request GET \
      --url "https://genai-code-buddy-api.stackspot.com/v1/quick-commands/callback/$id" \
      --header "Authorization: Bearer $access_token")

    answer=$(echo "$result" | grep -o '"answer":"[^"]*' | sed 's/"answer":"//')

    if [ -n "$answer" ]; then
      echo "$answer"
      return 0
    fi

    echo "Resposta não encontrada, aguardando 10 segundos antes de tentar novamente..."
    sleep 10
  done

  erro_e_sair "Erro: Campo 'answer' não encontrado após 5 tentativas!"
}

# Chama a função para obter a resposta com retry
obter_resposta
