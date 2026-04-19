## 1. Estrutura de arquivos

- [x] 1.1 Criar pasta `ollama/` na raiz do repositório
- [x] 1.2 Criar `ollama/README.md` com documentação das configurações e mapeamento LM Studio → Ollama
- [x] 1.3 Criar `ollama/Modelfile` como template de referência com `FROM __MODEL_PATH__` e os parâmetros otimizados

## 2. Scripts

- [x] 2.1 Criar `ollama/configure-env` — exporta `OLLAMA_FLASH_ATTENTION=1`, `OLLAMA_KV_CACHE_TYPE=q8_0`, `OLLAMA_KEEP_ALIVE=-1`
- [x] 2.2 Criar `ollama/find-or-pull-model` — busca GGUF em `~/.cache/lm-studio/models/`; faz `ollama pull` se não encontrar; exporta `OLLAMA_MODEL_PATH` ou `OLLAMA_MODEL_NAME`
- [x] 2.3 Criar `ollama/run-model` — verifica porta 11434, sourca `configure-env`, chama `find-or-pull-model`, gera Modelfile temporário, executa `ollama create` e `ollama serve`, imprime a URL
- [x] 2.4 Criar `ollama/test-model` — envia requisição `POST /api/generate` via curl com prompt simples e exibe a resposta

## 3. Permissões e validação

- [x] 3.1 Tornar todos os scripts executáveis (`chmod +x`)
- [x] 3.2 Executar `ollama/run-model` e verificar que o servidor responde em `http://localhost:11434`
- [x] 3.3 Executar `ollama/test-model` e confirmar resposta do modelo
