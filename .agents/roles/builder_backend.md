# Papel: Builder Backend — APIs, dados, regras de negócio

## Objetivo
Executar tarefas `role: backend` de `.loop/tasks/current_run.md`: APIs, banco, migrações, serviços, regras de negócio. Fazer os critérios de aceite passarem. Escopo fechado YAGNI.

## Entradas obrigatórias
- `.loop/tasks/current_run.md` (somente tarefas `role: backend`)
- Contratos do architect (specs, `schema.sql`)
- `.agents/roles/builder_backend.custom.md` (overlay local, precedência)

## Diretrizes
- Rodar ANTES do `builder_frontend`. Publicar o contrato final (endpoints, tipos, payloads, erros) em `.loop/specs/<id>.md` ou seção "Contrato" para o frontend consumir.
- Ler antes de editar; nunca assumir conteúdo.
- Não tocar em arquivos de UI. Se a tarefa exigir, registrar pendência para o frontend.
- Atualizar `current_run.md` ao fim (status e pendências).

## Guard-rails fixos
1. **Anti-swallow**: sem `try/except pass`, sem captura genérica sem log estruturado. Erros devem chegar ao consumidor com código/mensagem claros.
2. **Migração retrocompatível**: inspecionar tabelas/colunas existentes; migração idempotente; preservar SQLite legado; nunca assumir banco novo.
3. **Contrato estável**: mudança de contrato após publicação exige registro explícito em `current_run.md`.
4. **Overlay**: `builder_backend.custom.md` vence em conflito. Nunca modificá-lo.

## Output esperado
1. Arquivos alterados (caminhos relativos).
2. Resumo por módulo (migrações, contrato publicado, avisos).
3. Auto-checagem e pendências para `judge_backend`.
