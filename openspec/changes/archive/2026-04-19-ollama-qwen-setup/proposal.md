## Why

Executar o modelo Qwen3.5 9B localmente via Ollama com as mesmas configurações otimizadas do LM Studio (Flash Attention, KV cache Q8_0, context 64k), permitindo uso via API REST sem depender da interface gráfica do LM Studio.

## What Changes

- Nova pasta `ollama/` na raiz do repositório com scripts e documentação
- Script `ollama/configure-env` — exporta variáveis de ambiente do servidor Ollama
- Script `ollama/find-or-pull-model` — localiza GGUF do LM Studio ou faz pull via Ollama
- Script `ollama/run-model` — inicia o servidor Ollama com as env vars corretas e carrega o modelo
- Script `ollama/test-model` — testa a API com curl fazendo uma interação simples
- `ollama/Modelfile` — parâmetros do modelo (num_ctx, num_gpu, num_thread, num_batch)
- `ollama/README.md` — documentação das configurações e como usar

## Capabilities

### New Capabilities

- `ollama-qwen-setup`: Setup e execução do Qwen3.5 9B no Ollama com parâmetros equivalentes ao LM Studio

### Modified Capabilities

## Impact

- Nenhum serviço existente é afetado
- Dependência externa: Ollama instalado (`ollama` no PATH)
- Modelo Qwen3.5 9B disponível via LM Studio (`~/.cache/lm-studio/models/`) ou baixado via `ollama pull`
- API disponível em `http://localhost:11434`
