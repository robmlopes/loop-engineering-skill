# Manifesto Mestre de Governança e Orquestração (DSH)

Este repositório utiliza **Harness & Loop Engineering** para desenvolvimento autônomo com agentes de IA.

---

## 1. Princípios Inegociáveis

1. **Ponto Único de Contato**: O usuário interage exclusivamente com o **Agente Coordenador** (agente principal da sessão).
2. **Subagentes com Contexto Isolado**: Subagentes são invocados para tarefas fechadas (`subagent`), executam sua função e encerram. Não compartilham contaminação de contexto.
3. **Spec-Driven & TDD**: Nenhuma linha de código de implementação é escrita sem documento de especificação e sem critérios de testes definidos previamente.
4. **Verificação Objetiva de Parada**: Um loop nunca encerra porque o agente "acha que terminou". O encerramento depende exclusivamente da aprovação nos testes pelo `tester_judge`.
5. **Persistência Dual**:
   - Markdown (`.loop/`, `MEMORY.md`) para leitura imediata humana e do Coordenador.
   - SQLite (`.agents/memory.sqlite`) para histórico cronológico, rastreabilidade, kanban e métricas.

---

## 2. Mapa da Estrutura

```text
/
├── AGENTS.md                  # Este manifesto: regras globais e ciclo
│
├── .agents/                   # Governança e inteligência dos agentes
│   ├── SOUL.md                # Personalidade, limites éticos e comportamento
│   ├── MEMORY.md              # Memória rápida: lições aprendidas e convenções arquiteturais
│   ├── memory.sqlite          # Banco relacional com histórico de demandas, tarefas e evals
│   ├── schema.sql             # Definição das tabelas do banco SQLite
│   └── roles/                 # Prompts de papéis especializados para subagentes
│       ├── scope_analyst.md   # Refinamento de requisitos e não-objetivos
│       ├── architect.md       # Desenho de contratos, estruturas e dependências
│       ├── planner.md         # Criação de testes primeiro (TDD) e quebra de tarefas
│       ├── builder.md         # Implementação técnica e correção de falhas
│       └── tester_judge.md    # Validação com contexto zerado e emissão de veredito
│
└── .loop/                     # Operação do ciclo de desenvolvimento
    ├── SCHEDULE.md            # Gatilhos de acionamento, rotina de despertar e limites
    ├── specs/                 # Documentos de especificação formal das demandas
    ├── tasks/                 # Fila de tarefas atômicas (current_run.md)
    └── evals/                 # Vereditos e relatórios de execução dos testes
```

---

## 3. O Ciclo do Loop

```text
[Usuário] ──> [Coordenador]
                   │
                   ├──> 1. Análise: subagent(roles/scope_analyst.md) ──> .loop/specs/XXX.md
                   ├──> 2. Arquitetura: subagent(roles/architect.md)
                   ├──> 3. TDD & Plano: subagent(roles/planner.md) ───> .loop/tasks/current_run.md + testes
                   │
                   └──> [LOOP DE EXECUÇÃO]:
                            │
                            ├──> 4. Builder: subagent(roles/builder.md) ──> Código
                            ├──> 5. Judge: subagent(roles/tester_judge.md) ──> .loop/evals/last_eval.md
                            │        │
                            │        ├── [FALHA] ──> Repassa pendências para Builder (Max N rodadas)
                            │        └── [PASSOU] ──> Atualiza MEMORY.md + memory.sqlite
                            │
                            └──> Reporta entrega ao Usuário
```

---

## 4. Inicialização em Novo Workspace

Para preparar um novo workspace que acabou de clonar esta base:
1. Inicializar banco SQLite:
   ```bash
   sqlite3 .agents/memory.sqlite < .agents/schema.sql
   ```
2. Ler `.agents/SOUL.md` e `.agents/MEMORY.md`.
3. Ler `.loop/SCHEDULE.md` para entender como acordar o ciclo para a demanda desejada.
