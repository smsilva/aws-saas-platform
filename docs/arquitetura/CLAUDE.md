# arquitetura/ — Documentação de Arquitetura

## O que vive aqui

- Topologia e fluxo de tráfego (`index.md`, `fluxo-trafego.md`)
- Specs formais de componentes (`*-spec.md`) — formato BDD com cláusulas SHALL
- Links para `../decisoes-tecnicas.md` e `../fluxo-autenticacao-multitenant.md`

## Como propor uma change

1. Criar `arquitetura/changes/<nome-kebab-case>/proposal.md` e `tasks.md`
2. Verificar `changes/` antes — evitar duplicação
3. Verificar `changes/archive/` para entender decisões anteriores

## ADR vs change

| Situação | Use |
|---|---|
| Decisão de design tomada, precisa ser registrada | Entrada em `../decisoes-tecnicas.md` |
| Mudança na arquitetura que requer implementação | Change em `changes/` |
| Alteração em topologia, routing ou fluxo de tráfego | Change em `changes/` |
| Atualização de diagrama por mudança já executada | Edit direto (sem change) |

## Playbook de fechamento de change

1. Mover conhecimento permanente para:
   - `index.md` ou `fluxo-trafego.md` (topologia/routing)
   - `../decisoes-tecnicas.md` (decisão de design)
   - `*-spec.md` correspondente (requisito formal)
2. `mv changes/<nome> changes/archive/YYYY-MM-<nome>`
3. Change cancelada: mover para archive com sufixo `-cancelled`; adicionar nota
   em `proposal.md` explicando o motivo

## Specs formais (`*-spec.md`)

Contêm requisitos BDD (cláusulas SHALL + cenários). São mais precisos que a
documentação narrativa. Ao alterar arquitetura, atualizar o spec correspondente.