#!/bin/bash

# Caminho para o arquivo packages.txt
packages_file="packages.txt"

# Arquivo temporário para armazenar o conteúdo modificado
temp_file=$(mktemp)

# Loop para ler cada linha do arquivo packages.txt
while IFS= read -r package || [ -n "$package" ]; do
  # Verifica se a linha é um comentário ou está vazia
  if [[ -z "$package" || "$package" == \#* ]]; then
    echo "$package" >> "$temp_file"
  else
    # Verifica se o pacote está disponível no repositório
    if apt-cache show "$package" > /dev/null 2>&1; then
      echo "$package" >> "$temp_file"
    else
      echo "# Pacote '$package' não está disponível." >> "$temp_file"
    fi
  fi
done < "$packages_file"

# Sobrescreve o arquivo original com o conteúdo modificado
mv "$temp_file" "$packages_file"

# Exibe o conteúdo do arquivo original completo após a modificação
cat "$packages_file"
