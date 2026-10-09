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
│       ├── builder.md         # [Core] Implementação sem falhas silenciosas
│       ├── builder.custom.md       # [Opcional]
│       ├── tester_judge.md    # [Core] Validação com auditoria de banco e integridade
│       └── tester_judge.custom.md  # [Opcional]
│
└── .loop/                     # Operação do ciclo de desenvolvimento
    ├── SCHEDULE.md            # Gatilhos de acionamento, rotina de despertar e limites
    ├── specs/                 # Documentos de especificação formal das demandas
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
                   ├──> 3. TDD & Plano: subagent(roles/planner.md + custom) ───> .loop/tasks/current_run.md + testes
                   │
                   └──> [LOOP DE EXECUÇÃO]:
                            │
                            ├──> 4. Builder: subagent(roles/builder.md + custom) ──> Código
                            ├──> 5. Judge: subagent(roles/tester_judge.md + custom) ──> .loop/evals/last_eval.md
                            │        │
                            │        ├── [FALHA] ──> Repassa pendências para Builder (Max N rodadas)
                            │        └── [PASSOU] ──> Atualiza MEMORY.md + memory.sqlite
                            │
                            └──> Reporta entrega ao Usuário
```

---

## 4. Inicialização e Atualização do Workspace

1. **Inicializar banco SQLite**:
   ```bash
   python3 -c "import sqlite3; conn = sqlite3.connect('.agents/memory.sqlite'); f = open('.agents/schema.sql', 'r'); conn.executescript(f.read()); conn.close(); print('DB inicializado')"
   ```
2. **Atualização de Guard-Rails**:
   - Para atualizar a orquestração para a versão mais recente sem perder personalizações, invoque a skill `/loop-engineering-init update`.
