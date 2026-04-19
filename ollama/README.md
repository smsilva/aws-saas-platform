# Ollama — Qwen3.5 9B

Executa o modelo Qwen3.5 9B no Ollama com as mesmas configurações otimizadas do LM Studio.

## Mapeamento LM Studio → Ollama

| LM Studio (GUI) | Ollama | Valor |
|---|---|---|
| Context Length | `num_ctx` (Modelfile) | 64000 |
| GPU Offload | `num_gpu` (Modelfile) | 32 |
| CPU Thread Pool Size | `num_thread` (Modelfile) | 6 |
| Evaluation Batch Size | `num_batch` (Modelfile) | 512 |
| Flash Attention | `OLLAMA_FLASH_ATTENTION` (env) | 1 |
| K/V Cache Quantization Q8\_0 | `OLLAMA_KV_CACHE_TYPE` (env) | q8_0 |
| Keep Model in Memory | `OLLAMA_KEEP_ALIVE` (env) | -1 |

## Uso rápido

```bash
# 1. Iniciar servidor + carregar modelo
./ollama/run-model

# 2. Testar
./ollama/test-model
```

API disponível em: `http://localhost:11434`

## Scripts

| Script | O que faz |
|---|---|
| `configure-env` | Exporta variáveis de ambiente do servidor (source este arquivo) |
| `find-or-pull-model` | Localiza GGUF do LM Studio ou baixa via `ollama pull` |
| `run-model` | Orquestra tudo: env vars, modelo, servidor |
| `test-model` | Envia requisição de teste via curl |

## Detalhes técnicos

**Flash Attention e KV cache** são configurações do servidor Ollama, não do modelo.
Devem estar definidas antes de `ollama serve`.

**KV Cache Q8\_0** aplica-se ao cache de atenção (K e V tensors), não aos pesos do modelo.
A quantização dos pesos é determinada pelo arquivo GGUF (ex: Q4\_K\_M, Q8\_0).

**GGUF local**: O `find-or-pull-model` busca em `~/.cache/lm-studio/models/` por arquivos
com "qwen" no nome. Se encontrado, usa o arquivo existente (evita download ~5 GB).

## Sobrescrever o nome do modelo

```bash
OLLAMA_MODEL_NAME=qwen2.5:9b ./ollama/run-model
```
