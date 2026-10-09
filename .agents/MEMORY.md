# Memória de Longo Prazo e Lições Aprendidas (MEMORY)

Este arquivo armazena convenções estabelecidas, decisões técnicas permanentes e erros corrigidos no projeto. É lido no início de cada ciclo pelo Coordenador.

---

## 1. Convenções do Projeto
- **Ambiente de Terminal**: EATMCP obrigatório (`command_execute`, `environment_inspect`).
- **Banco de Persistência**: SQLite 3 localizado em `.agents/memory.sqlite`.
- **Formato de Tarefas**: Decomposição atômica com critérios de aceite verificáveis por comandos ou testes automatizados.
- **Customização Desacoplada**: Personalizações locais de papéis residem em arquivos irmãos `*.custom.md`.

---

## 2. Decisões Arquiteturais Registradas
- `[DEC-001]`: Arquitetura do Workspace baseada em Harness & Loop Engineering nativo do DSH com persistência dual (Markdown para legibilidade + SQLite para rastreabilidade/kanban).
- `[DEC-002]`: Verificação cega independente (Judge) com subagente de contexto isolado para mitigar erros compostos de execução.
- `[DEC-003]`: Padrão Overlay para Customização (`*.custom.md`) para permitir atualizações automáticas de governança via `/loop-engineering-init update` sem sobrescrever regras específicas locais.
- `[DEC-004]`: Blindagem Obrigatória de Migração de Dados: repositórios e DDLs devem aplicar migrações retrocompatíveis e idempotentes sobre bases existentes em disco.

---

## 3. Anti-Padrões e Armadilhas Evitadas
- **Anti-Padrão**: Builder avaliar o próprio código. *Solução*: Delegar validação estritamente ao `tester_judge`.
- **Anti-Padrão**: Deixar loop rodar sem teste objetivo pré-existente. *Solução*: Testes devem existir antes da implementação (TDD).
- **Anti-Padrão**: Poluir contexto do Coordenador com logs de comandos extensos. *Solução*: Subagentes isolados que retornam apenas resumo do status.
- **Anti-Padrão**: Alterar schema de banco assumindo base virgem em `:memory:`. *Incidente*: SPEC-005 quebrou `srd.db` existente por falta de colunas `amount` e `cost_basis_usd`. *Solução*: Arquiteto, Planner e Builder obrigados a testar migração sobre schema legado.
- **Anti-Padrão**: Tratar erro com `try...except Exception: pass` engolindo falhas de dados e ocultando componentes visuais em UI/repositórios. *Incidente*: Banner da UI sumiu silenciosamente após erro de SQL. *Solução*: Proibir swallow de erro. Repositório lança ou faz log estruturado; UI exibe aviso/placeholder claro.
