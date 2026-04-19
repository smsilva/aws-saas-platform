## Context

O LM Studio permite configurar parâmetros avançados de inferência (Flash Attention, KV cache quantization, context length) via GUI. O Ollama expõe os mesmos parâmetros via Modelfile (parâmetros de runtime) e variáveis de ambiente do servidor. O modelo Qwen3.5 9B é armazenado como GGUF em `~/.cache/lm-studio/models/` — o mesmo formato que o Ollama aceita via `FROM /path`.

## Goals / Non-Goals

**Goals:**
- Replicar as configurações do LM Studio no Ollama com scripts idempotentes
- Detectar automaticamente o GGUF existente antes de baixar novamente
- Expor a API REST do Ollama em `http://localhost:11434`
- Fornecer script de teste com curl para validar a integração

**Non-Goals:**
- Gerenciar múltiplos modelos ou versões
- Substituir o LM Studio como ferramenta de desenvolvimento
- Integração com os serviços do lab EKS

## Decisions

**GGUF local vs. pull do Ollama registry**
Preferir o GGUF já baixado pelo LM Studio para evitar download duplicado (~5 GB). O script `find-or-pull-model` busca em `~/.cache/lm-studio/models/` por arquivos `*.gguf` com "qwen" no nome; se não encontrar, executa `ollama pull qwen2.5:7b` (equivalente disponível no registry público).

**Modelfile com FROM dinâmico**
O `run-model` gera o Modelfile em runtime apontando para o caminho real do GGUF (ou para o nome do modelo do registry), mantendo o `ollama/Modelfile` como template de referência com `FROM __MODEL_PATH__`.

**Flash Attention e KV cache via env vars**
`OLLAMA_FLASH_ATTENTION` e `OLLAMA_KV_CACHE_TYPE` são configurações do servidor, não do modelo — devem ser exportadas antes de `ollama serve`. O `configure-env` os exporta; o `run-model` o importa via `source`.

**Scripts sem extensão, idempotentes**
Seguindo as convenções do repositório: executáveis sem `.sh`, opções long-form, `|| true` em operações destrutivas.

## Risks / Trade-offs

- [Nome do modelo no registry pode divergir do GGUF local] → Script informa o nome exato encontrado e permite override via variável `OLLAMA_MODEL_NAME`
- [ollama serve já rodando na porta 11434] → Script verifica com `curl -s localhost:11434` antes de tentar iniciar; exibe instrução para encerrar processo existente se necessário
- [GGUF do LM Studio pode ser Q4 enquanto esperamos Q8] → Documentado no README; a quantização do arquivo GGUF é fixa — KV cache Q8_0 é independente e aplica-se ao cache de atenção, não aos pesos
