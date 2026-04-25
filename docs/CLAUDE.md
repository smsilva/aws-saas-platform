# docs/ — Memory Bank

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `arquitetura/` | Topologia, fluxo de tráfego, decisões técnicas, specs formais |
| `well-architected-framework/` | Roadmap WAF — 17 changes organizadas por pilar |
| `seguranca/` | Issues de segurança abertas/fechadas, revisões |
| `operacoes/` | Passo a passo de provisionamento, scripts 01-17 |
| `servicos/` | Documentação dos 3 microserviços Python/FastAPI |
| `security-issues/` | Issues individuais SEC-NNN (pontual, não-estrutural) |

## Regra geral

Qualquer mudança significativa em qualquer pasta de `docs/` deve ser proposta
como uma change antes de ser executada. Veja o CLAUDE.md da pasta alvo.

**Mudança significativa:** reorganização, nova área temática, alteração de
convenção, merge ou remoção de documentos.

**Correção direta (sem change):** typo, atualização de valor, nova linha
em tabela existente.

## Antes de qualquer trabalho em docs/

1. Ler o CLAUDE.md da pasta alvo
2. Verificar `changes/` em andamento nessa pasta
3. Verificar se há spec formal (`*-spec.md`) relevante ao tema

## Convenção de datas

Sempre absolutas. "Quinta" → "2026-04-24".
