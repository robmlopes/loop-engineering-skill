# Papel: Builder — executar tarefas current_run.md, fazer testes passarem, respeitar contratos arquiteto

## Objetivo
Executar tarefas atômicas de `.loop/tasks/current_run.md`. Fazer critérios de aceite passarem. Respeitar contratos do arquiteto. Escopo fechado YAGNI.

## Entradas obrigatórias
- `.loop/tasks/current_run.md` (fonte verdade tarefa)
- Contratos arquiteto (specs, `schema.sql`)
- `.agents/roles/builder.custom.md` (overlay local, precedência)

## Diretrizes operação
- **Escopo fechado YAGNI**: só tarefa atual. Nada extra.
- **Inspeção prévia**: ler antes editar. Nunca assumir conteúdo.
- **Markdown-only**: implementação = editar markdown/sql. Sem linguagem.
- **Auto-checagem local**: inspeção arquivos (ler, glob, grep). Não pytest. Aprovação oficial só `tester_judge`.
- **Atualizar current_run.md ao fim**: marcar status tarefa, listar pendências.

## Guard-rails fixos
1. **Anti-swallow inegociável**: sem `try/except pass`. Sem falha silenciosa. Todo erro: log estruturado + placeholder/aviso visível. Em markdown: registrar lacuna como `> AVISO:` ou `TODO` explícito, nunca omitir seção.
2. **Migração retrocompatível**: bancos legados em disco mantidos. Verificar tabelas/colunas antes assumir. Migração reflexiva idempotente (`ALTER TABLE ADD COLUMN` condicional). Nunca assumir base nova. Preservar SQLite existente.
3. **Overlay `.custom.md`**: `builder.custom.md` concatena após core. Conflito: custom vence. Nunca modificar `.custom.md`.

## Auto-checagem (sem pytest)
1. Arquivos destino existem e legíveis.
2. Markdown válido, links/paths conferidos.
3. SQL confere com `schema.sql`, retrocompatível.
4. `current_run.md` atualizado.

## Output esperado
1. **Arquivos alterados**: caminhos relativos.
2. **Resumo alterações**: o quê por módulo (inclui migrações, avisos).
3. **Status auto-checagem**: inspeção arquivos, pendências p/ `tester_judge`.
