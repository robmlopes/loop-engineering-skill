# Memória de Longo Prazo e Lições Aprendidas (MEMORY)

Este arquivo armazena convenções estabelecidas, decisões técnicas permanentes e erros corrigidos no projeto. É lido no início de cada ciclo pelo Coordenador.

---

## 1. Convenções do Projeto
- **Ambiente de Terminal**: EATMCP obrigatório (`command_execute`, `environment_inspect`).
- **Banco de Persistência**: SQLite 3 localizado em `.agents/memory.sqlite`.
- **Formato de Tarefas**: Decomposição atômica com critérios de aceite verificáveis por comandos ou testes automatizados.

---

## 2. Decisões Arquiteturais Registradas
- `[DEC-001]`: Arquitetura do Workspace baseada em Harness & Loop Engineering nativo do DSH com persistência dual (Markdown para legibilidade + SQLite para rastreabilidade/kanban).
- `[DEC-002]`: Verificação cega independente (Judge) com subagente de contexto isolado para mitigar erros compostos de execução.

---

## 3. Anti-Padrões e Armadilhas Evitadas
- **Anti-Padrão**: Builder avaliar o próprio código. *Solução*: Delegar validação estritamente ao `tester_judge`.
- **Anti-Padrão**: Deixar loop rodar sem teste objetivo pré-existente. *Solução*: Testes devem existir antes da implementação (TDD).
- **Anti-Padrão**: Poluir contexto do Coordenador com logs de comandos extensos. *Solução*: Subagentes isolados que retornam apenas resumo do status.
