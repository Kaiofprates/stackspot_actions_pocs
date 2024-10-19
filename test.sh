#!/bin/bash

# Função para obter o access_token
get_access_token() {
  local client_id=$1
  local client_secret=$2
  response=$(curl --silent --request POST \
    --url https://idm.stackspot.com/zup/oidc/oauth/token \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --data client_id=$client_id \
    --data grant_type=client_credentials \
    --data client_secret=$client_secret)
  
  access_token=$(echo $response | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"\([^"]*\)"/\1/')
  
  if [ -z "$access_token" ]; then
    echo "Erro: access_token não encontrado!"
    exit 1
  fi
  
  echo "$access_token"
}

# Função para criar a execução e obter o ID
create_execution() {
  local access_token=$1
  local input_data=$2
  response=$(curl --silent --request POST \
    --url 'https://genai-code-buddy-api.stackspot.com/v1/quick-commands/create-execution/testremote' \
    --header "Authorization: Bearer $access_token" \
    --header 'Content-Type: application/json' \
    --data "{\"input_data\": \"$input_data\"}")
  
  execution_id=$(echo $response | grep -o '"execution_id":"[^"]*"' | sed 's/"execution_id":"\([^"]*\)"/\1/')
  
  if [ -z "$execution_id" ]; then
    echo "Erro: execution_id não encontrado!"
    exit 1
  fi
  
  echo "$execution_id"
}

# Função para verificar o status da execução
check_execution_status() {
  local access_token=$1
  local execution_id=$2
  response=$(curl --silent --request GET \
    --url "https://genai-code-buddy-api.stackspot.com/v1/quick-commands/callback/$execution_id" \
    --header "Authorization: Bearer $access_token")
  
  echo "$response"
}

# Função principal para orquestrar o fluxo
main() {
  local client_id=$1
  local client_secret=$2
  local input_data=$3

  # Obter o access_token
  access_token=$(get_access_token "$client_id" "$client_secret")
  echo "Access Token obtido com sucesso."

  # Criar a execução e obter o ID
  execution_id=$(create_execution "$access_token" "$input_data")
  echo "Execução criada com ID: $execution_id"

  # Tentar verificar o status até 3 vezes
  local max_attempts=3
  local attempt=1
  local result

  while [ $attempt -le $max_attempts ]; do
    echo "Tentativa $attempt de $max_attempts. Aguardando 10 segundos antes de verificar o status..."
    sleep 10

    # Verificar o status da execução
    result=$(check_execution_status "$access_token" "$execution_id")

    # Verifica se o campo 'answer' está presente na resposta
    echo "$result"
    
    if echo "$result" | grep -q '"answer"'; then
      answer=$(echo "$result" | grep -o '"answer":"[^"]*"' | sed 's/"answer":"\([^"]*\)"/\1/')
      echo "Execução concluída. Resposta: $answer"
      exit 0
    else
      echo "Execução ainda em andamento ou falhou."
    fi

    attempt=$((attempt + 1))
  done

  echo "Execução não foi concluída após $max_attempts tentativas."
}

# Chama a função principal com os argumentos passados
main "$@"