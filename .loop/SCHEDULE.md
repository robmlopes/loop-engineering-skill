# Orquestração do SCHEDULE e Rotinas de Despertar

Este arquivo documenta e governa como o loop de agentes é acionado, como os agentes "acordam" para trabalhar e os limites de segurança para evitar consumo indevido de tokens.

---

## 1. Modos de Despertar (Wake-Up Modes)

### Modo 1: Manual / Interativo (Turn-Based)
- **Gatilho**: O usuário conversa com o Coordenador e solicita uma nova funcionalidade ou correção.
- **Fluxo**:
  1. O Coordenador acorda, consulta `.agents/MEMORY.md` e `.loop/SCHEDULE.md`.
  2. Alinha os pontos iniciais com o usuário.
  3. Dispara o subagente `scope_analyst` para formalizar a especificação em `.loop/specs/<id>.md`.
  4. Aguarda validação do usuário antes de iniciar o loop autônomo.

### Modo 2: Autônomo Guiado por Objetivo (Goal-Based Loop)
- **Gatilho**: Especificação e testes aprovados. Coordenador arma o loop via ferramenta nativa `create_goal` do DSH.
- **Rotina de Cada Rodada (Turn Lifecycle)**:
  1. **Acordar**: Coordenador lê `.loop/tasks/current_run.md` e `.loop/evals/last_eval.md`.
  2. **Verificar Estado**:
     - Existem tarefas com status `PENDING`?
       -> Invoca subagente `builder`.
     - O builder terminou a rodada?
       -> Invoca subagente `tester_judge` (contexto isolado).
     - O veredito do judge foi `APROVADO`?
       -> Atualiza `.agents/MEMORY.md`, persiste no SQLite e chama `update_goal action: complete`. Fim do loop!
     - O veredito foi `REPROVADO`?
       -> Cria sub-tarefas de correção em `current_run.md` e continua para a próxima rodada (até o limite de retentativas).

### Modo 3: Programado / Periódico (Time/Event-Based)
- **Gatilho**: Disparado por cron, script externo ou rotina de CI/CD que injeta uma mensagem na sessão ou executa uma inspeção no workspace.
- **Critério de Ativação**: O agente checa se há demandas pendentes na tabela `demands` com status `PLANNED` ou `IN_PROGRESS` no `.agents/memory.sqlite`.

---

## 2. Limites de Segurança e Proteção (Circuit Breakers)

Para evitar loops infinitos ("queimar tokens sem critério"):
1. **Cap Máximo de Rodadas de Correção**: Por padrão, no máximo **5 ciclos** de Builder <-> Judge por demanda.
2. **Escalação Obrigatória**: Se após 3 tentativas de correção o mesmo teste continuar falhando com a mesma causa raiz, o Coordenador é obrigado a interromper o loop, registrar o bloqueio no SQLite (`status: BLOCKED`) e escalar para o usuário.
3. **Sandbox & Timeouts**: Qualquer comando executado pelos agentes deve rodar com timeout configurado para evitar processos travados.

---

## 3. Matriz de Estados das Demandas

| Estado | Significado | Próxima Ação Permitida |
|---|---|---|
| `DRAFT` | Ideia bruta ou requisitos sendo coletados | Chamar `scope_analyst` |
| `PLANNED` | Specs prontas, arquitetura e testes TDD definidos | Chamar `builder` para iniciar |
| `IN_PROGRESS` | Builder trabalhando nas tarefas atômicas | Rodar auto-checagem local |
| `VALIDATING` | Builder concluiu rodada, aguardando árbitro | Chamar `tester_judge` |
| `DONE` | Judge aprovou 100% dos testes | Atualizar memória e reportar ao usuário |
| `BLOCKED` | Erro repetitivo ou ambiguidade insolúvel | Chamar humano para intervenção |
