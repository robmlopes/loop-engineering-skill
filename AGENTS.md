<!-- LOOP-ENGINEERING:BEGIN (gerenciado por /loop-engineering-init; não edite dentro do bloco) -->
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
6. **Blindagem de Banco e Anti-Degradação Silenciosa**:
   - Migrações retrocompatíveis e idempotentes para bancos legados em disco.
   - Proibição estrita de swallow de exceções (`try...except Exception: pass`) em UI e repositórios.
7. **Padrão de Customização Desacoplada (Overlay `*.custom.md`)**:
   - Regras customizadas de equipes ou projetos vivem em arquivos irmãos `.custom.md`.
   - Arquivos core podem ser atualizados via `/loop-engineering-init update` sem sobrescrever personalizações locais.

---

## 2. Mapa da Estrutura

```text
/
├── AGENTS.md                  # Este manifesto: regras globais e ciclo (Core)
├── AGENTS.custom.md           # [Opcional] Regras mestres específicas do projeto
│
├── .agents/                   # Governança e inteligência dos agentes
│   ├── SOUL.md                # Personalidade, limites éticos e comportamento (Core)
│   ├── SOUL.custom.md         # [Opcional] Limites e ajustes comportamentais locais
│   ├── MEMORY.md              # Memória rápida: lições aprendidas e convenções arquiteturais
│   ├── memory.sqlite          # Banco relacional com histórico de demandas, tarefas e evals
│   ├── schema.sql             # Definição das tabelas do banco SQLite
│   └── roles/                 # Prompts de papéis especializados para subagentes
│       ├── scope_analyst.md   # [Core] Refinamento de requisitos e não-objetivos
│       ├── scope_analyst.custom.md # [Opcional]
│       ├── architect.md       # [Core] Desenho de contratos, estruturas e migrações
│       ├── architect.custom.md     # [Opcional]
│       ├── planner.md         # [Core] Criação de testes primeiro (TDD) e quebra
│       ├── planner.custom.md       # [Opcional]
│       ├── designer.md        # [Core] Direção visual e spec de UI (só se ui: true)
│       ├── designer.custom.md      # [Opcional]
│       ├── builder.md         # [Core] Fallback genérico (scripts, infra, CLI)
│       ├── builder.custom.md       # [Opcional]
│       ├── builder_backend.md # [Core] APIs, banco, migrações, regras de negócio
│       ├── builder_backend.custom.md   # [Opcional]
│       ├── builder_frontend.md # [Core] UI/UX conforme o design
│       ├── builder_frontend.custom.md  # [Opcional]
│       ├── judge_backend.md   # [Core] Relatório especializado de backend
│       ├── judge_backend.custom.md     # [Opcional]
│       ├── judge_frontend.md  # [Core] Relatório especializado de UI
│       ├── judge_frontend.custom.md    # [Opcional]
│       ├── tester_judge.md    # [Core] Juiz final: integração e veredito único
│       └── tester_judge.custom.md  # [Opcional]
│
└── .loop/                     # Operação do ciclo de desenvolvimento
    ├── SCHEDULE.md            # Gatilhos de acionamento, rotina de despertar e limites
    ├── specs/                 # Documentos de especificação formal das demandas
    ├── design/                # Especificações visuais (<id>.md) geradas pelo designer
    ├── tasks/                 # Fila de tarefas atômicas (current_run.md)
    └── evals/                 # Vereditos e relatórios de execução dos testes
```

---

## 3. O Ciclo do Loop e Composição de Prompts

Quando o Coordenador invoca um subagente:
- Carrega o prompt core de `.agents/roles/<role>.md`.
- Se existir `.agents/roles/<role>.custom.md`, concatena suas diretrizes ao final.

```text
[Usuário] ──> [Coordenador]
                   │
                   ├──> 1. Análise: subagent(roles/scope_analyst.md + custom) ──> .loop/specs/XXX.md
                   ├──> 2. Arquitetura: subagent(roles/architect.md + custom)
                   ├──> 2b. Design (só se spec ui: true): subagent(roles/designer.md + custom) ──> .loop/design/XXX.md
                   ├──> 3. TDD & Plano: subagent(roles/planner.md + custom) ───> .loop/tasks/current_run.md + testes
                   │
                   └──> [LOOP DE EXECUÇÃO] (builders SEMPRE em sequência, nunca em paralelo):
                            │
                            ├──> 4a. builder_backend (tarefas role: backend) ──> Código + contrato
                            ├──> 4b. builder_frontend (tarefas role: frontend) ──> UI conforme design
                            ├──> 4c. builder (tarefas role: generic) ──> Scripts/infra/CLI
                            ├──> 5a. judge_backend / 5b. judge_frontend (só os envolvidos) ──> seções do last_eval.md
                            ├──> 5c. tester_judge: integração ponta a ponta + VEREDITO ÚNICO ──> .loop/evals/last_eval.md
                            │        │
                            │        ├── [FALHA] ──> Repassa pendências para Builder (Max N rodadas)
                            │        └── [PASSOU] ──> Atualiza MEMORY.md + memory.sqlite
                            │
                            └──> Reporta entrega ao Usuário
```

---

### Roteamento por `role`
- O `planner` marca cada tarefa em `current_run.md` com `role: backend|frontend|generic`.
- Ordem padrão: backend -> frontend -> generic. Pendências voltam ao builder da mesma especialidade.
- Os judges especializados apenas reportam; somente o `tester_judge` emite APROVADO/REPROVADO.
- Sem paralelismo de subagentes: um builder por vez evita conflitos de escrita e de SQLite.
- Se a spec não tiver `ui: true`, pular `designer` e `judge_frontend`.

---

## 4. Inicialização e Atualização do Workspace

1. **Inicializar banco SQLite**:
   ```bash
   python3 -c "import sqlite3; conn = sqlite3.connect('.agents/memory.sqlite'); f = open('.agents/schema.sql', 'r'); conn.executescript(f.read()); conn.close(); print('DB inicializado')"
   ```
2. **Atualização de Guard-Rails**:
   - Para atualizar a orquestração para a versão mais recente sem perder personalizações, invoque a skill `/loop-engineering-init update`.
<!-- LOOP-ENGINEERING:END -->
