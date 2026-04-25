# seguranca/ — Segurança

## O que vive aqui

- Índice consolidado de issues (`index.md`)
- Issues individuais linkadas em `../security-issues/SEC-NNN.md`

## Issue pontual vs change estrutural

| Situação | Use |
|---|---|
| Bug/misconfiguration em script ou config existente | Issue em `../security-issues/SEC-NNN.md` |
| Hardening que altera arquitetura ou processo | Change em `../well-architected-framework/security/changes/` |
| Fix que fecha uma issue existente | Change com referência ao SEC-NNN no `proposal.md` |

## Abrir uma nova issue de segurança

1. Criar `../security-issues/sec-NNN.md` com: severidade, vetor de ataque, status
2. Adicionar entrada em `index.md`
3. Se o fix requer uma change estrutural, criar em
   `../well-architected-framework/security/changes/<nome>/`

## Fechar uma issue

1. Atualizar `status` em `../security-issues/SEC-NNN.md` → `Resolvido`
2. Atualizar linha na tabela em `index.md`
3. Se havia uma change associada, arquivá-la (ver playbook abaixo)

## Propor uma change de segurança

1. Verificar `../well-architected-framework/security/changes/` — pode já existir
2. Criar `../well-architected-framework/security/changes/<nome-kebab-case>/`
   com `proposal.md` e `tasks.md`
3. Referenciar o SEC-NNN relacionado no `proposal.md`

## Playbook de fechamento de change

1. Atualizar status das issues resolvidas em `../security-issues/` e `index.md`
2. `mv ../well-architected-framework/security/changes/<nome> .../archive/YYYY-MM-<nome>`
3. Change cancelada: sufixo `-cancelled`; nota em `proposal.md`

## Critérios de severidade

| Severidade | Critério |
|---|---|
| Alto | Comprometimento direto sem condições adicionais |
| Médio | Vetor viável com condições adicionais (SSRF, role comprometida) |
| Baixo | Superfície aumentada, mitigada por outras camadas |