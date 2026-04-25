# Ollama — Qwen3.5 9B

Runs the Qwen3.5 9B model on Ollama with the same optimized settings as LM Studio.

## LM Studio → Ollama Mapping

| LM Studio (GUI) | Ollama | Value |
|---|---|---|
| Context Length | `num_ctx` (Modelfile) | 64000 |
| GPU Offload | `num_gpu` (Modelfile) | 32 |
| CPU Thread Pool Size | `num_thread` (Modelfile) | 6 |
| Evaluation Batch Size | `num_batch` (Modelfile) | 512 |
| Flash Attention | `OLLAMA_FLASH_ATTENTION` (env) | 1 |
| K/V Cache Quantization Q8\_0 | `OLLAMA_KV_CACHE_TYPE` (env) | q8_0 |
| Keep Model in Memory | `OLLAMA_KEEP_ALIVE` (env) | -1 |

## Quick Usage

```bash
# 1. Start server + load model
./ollama/run-model

# 2. Test
./ollama/test-model
```

API available at: `http://localhost:11434`

## Scripts

| Script | What it does |
|---|---|
| `configure-env` | Exports server environment variables (source this file) |
| `find-or-pull-model` | Locates LM Studio GGUF or downloads via `ollama pull` |
| `run-model` | Orchestrates everything: env vars, model, server |
| `test-model` | Sends a test request via curl |

## Technical Details

**Flash Attention and KV cache** are Ollama server settings, not model settings.
Must be set before `ollama serve`.

**KV Cache Q8\_0** applies to the attention cache (K and V tensors), not to model weights.
Weight quantization is determined by the GGUF file (e.g., Q4\_K\_M, Q8\_0).

**Local GGUF**: `find-or-pull-model` searches `~/.cache/lm-studio/models/` for files
with "qwen" in the name. If found, uses the existing file (avoids ~5 GB download).

## Override Model Name

```bash
OLLAMA_MODEL_NAME=qwen2.5:9b ./ollama/run-model
```
