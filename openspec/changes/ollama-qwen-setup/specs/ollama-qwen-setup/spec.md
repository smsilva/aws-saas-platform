## ADDED Requirements

### Requirement: Configuração de variáveis de ambiente do servidor Ollama
O sistema SHALL exportar as variáveis `OLLAMA_FLASH_ATTENTION=1`, `OLLAMA_KV_CACHE_TYPE=q8_0` e `OLLAMA_KEEP_ALIVE=-1` via script `configure-env` que pode ser sourced por outros scripts.

#### Scenario: Source do configure-env exporta variáveis
- **WHEN** o usuário executa `source ollama/configure-env`
- **THEN** as variáveis `OLLAMA_FLASH_ATTENTION`, `OLLAMA_KV_CACHE_TYPE` e `OLLAMA_KEEP_ALIVE` estão disponíveis no shell

### Requirement: Detecção automática do modelo GGUF
O sistema SHALL buscar arquivos `*.gguf` com "qwen" no nome em `~/.cache/lm-studio/models/` antes de fazer download.

#### Scenario: GGUF encontrado no cache do LM Studio
- **WHEN** `find-or-pull-model` é executado e existe um arquivo GGUF com "qwen" em `~/.cache/lm-studio/models/`
- **THEN** o script imprime o caminho do arquivo e exporta `OLLAMA_MODEL_PATH` com esse caminho

#### Scenario: GGUF não encontrado — faz pull do registry
- **WHEN** `find-or-pull-model` é executado e nenhum GGUF é encontrado
- **THEN** o script executa `ollama pull qwen2.5:7b` e exporta `OLLAMA_MODEL_NAME=qwen2.5:7b`

### Requirement: Registro do modelo com parâmetros otimizados
O sistema SHALL criar um modelo no Ollama via Modelfile com `num_ctx 64000`, `num_gpu 32`, `num_thread 6` e `num_batch 512`.

#### Scenario: Modelo registrado com sucesso
- **WHEN** `run-model` é executado após `find-or-pull-model`
- **THEN** `ollama create qwen3.5-9b-custom` completa sem erro e o modelo aparece em `ollama list`

### Requirement: Servidor Ollama iniciado com env vars corretas
O sistema SHALL iniciar `ollama serve` com Flash Attention e KV cache Q8_0 habilitados, verificando antes se a porta 11434 já está em uso.

#### Scenario: Porta livre — servidor inicia normalmente
- **WHEN** `run-model` é executado e nada está escutando na porta 11434
- **THEN** `ollama serve` inicia em background e a API responde em `http://localhost:11434`

#### Scenario: Porta ocupada — script avisa e encerra
- **WHEN** `run-model` detecta que a porta 11434 já está em uso
- **THEN** o script exibe mensagem informando o PID do processo e encerra com código 1

### Requirement: Teste de integração via curl
O sistema SHALL fornecer script `test-model` que envia uma requisição ao endpoint `/api/generate` e exibe a resposta do modelo.

#### Scenario: Requisição bem-sucedida
- **WHEN** `test-model` é executado com Ollama rodando e modelo carregado
- **THEN** o script imprime a resposta do modelo para o prompt de teste e encerra com código 0
