# Fiscaliza Político

Aplicativo em Flutter que consolida dados públicos de deputados e senadores em um ranking gamificado.

## Deploy Automático na Netlify

O projeto está configurado para deploy automático na Netlify usando CI/CD.

O arquivo `netlify.toml` especifica que o script `scripts/build.sh` deve ser executado, o qual:
1. Instala as dependências Node.js
2. Roda os scripts de coleta (`fetch-data.js`, `fetch-senadores.js`)
3. Instala o Flutter e compila para a Web

## Segurança e Chaves de API

O script precisaria acessar APIs como o Portal da Transparência, que exigem uma chave (API Key).

**NUNCA adicione chaves de API diretamente no código!**

### Como configurar para Desenvolvimento Local
1. Crie um arquivo `.env` na raiz do projeto
2. Adicione sua chave lá: `TRANSPARENCIA_API_KEY=sua_chave_aqui`
3. O arquivo `.env` já está no `.gitignore` e não será enviado para o GitHub.

### Como configurar na Netlify
1. No painel da Netlify, vá em **Site configuration > Environment variables**
2. Adicione uma variável com:
   - Key: `TRANSPARENCIA_API_KEY`
   - Value: `sua_chave_aqui`
3. O script de build lerá essa variável com segurança sem expô-la no código.
