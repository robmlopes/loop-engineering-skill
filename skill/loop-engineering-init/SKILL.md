---
name: loop-engineering-init
description: "Inicializa ou atualiza estrutura completa de Harness & Loop Engineering em qualquer workspace (novo ou existente). Configura governança (.agents/, SOUL, MEMORY, SQLite, papéis) e ciclo (.loop/, SCHEDULE, specs, tasks, evals). Suporta análise com graft em projetos existentes e modo update/audit para sincronizar guard-rails preservando customizações locais (*.custom.md)."
risk: low
source: user
date_added: "2026-10-10"
---

# Loop Engineering Init — Inicialização e Atualização de Workspace

Esta skill transforma qualquer pasta em um workspace governado por **Harness & Loop Engineering**, instalando e mantendo a estrutura de orquestração de agentes nativa do DSH.

---

## 1. Modos de Operação

- **Modo Inicialização** (`/loop-engineering-init` ou "inicialize o loop engineering"): instala a governança completa do zero.
- **Modo Atualização / Auditoria** (`/loop-engineering-init update` ou `/loop-engineering-init audit` ou "atualize os agentes deste projeto"): audita e atualiza os arquivos core da governança com as regras e guard-rails mais recentes, preservando estritamente arquivos customizados (`*.custom.md`), dados do SQLite e histórico de loops.

---

## 2. Guard-Rails Técnicos Globais (Core)

Todos os papéis e ciclos devem respeitar:

1. **Blindagem de Migração de Banco**:
   - Nenhuma alteração de schema/DDL pode assumir banco novo ou em memória (`:memory:`).
   - Scripts de inicialização (`init_db`) e repositórios devem inspecionar colunas e tabelas existentes e aplicar migrações retrocompatíveis e idempotentes (`ALTER TABLE ADD COLUMN IF NOT EXISTS` ou validação reflexiva) para bases já em disco.
2. **Proibição Estrita de Falhas Silenciosas (Anti-Swallow)**:
   - Proibido `try...except Exception: pass` ou captura genérica sem log estruturado (`logger.error(...)`).
   - Erros de banco ou infraestrutura nunca devem ocultar componentes de interface (UI/CLI/API). Na ocorrência de erro, exibir alerta ou estado degradado explícito para o usuário final.
3. **Validação e Auditoria Pós-Build**:
   - O `tester_judge` deve testar a migração sobre bases legadas com dados reais e checar a integridade de componentes de tela/layout para certificar que nenhum recurso existente sumiu indevidamente.
4. **Padrão de Customização Overlay (`*.custom.md`)**:
   - Customizações específicas de projetos ou equipes não devem ser escritas nos arquivos core.
   - Regras específicas devem ser colocadas em arquivos irmãos com extensão `.custom.md` (ex: `.agents/roles/builder.custom.md`, `.agents/AGENTS.custom.md`).
   - O Coordenador sempre concatena o core correspondente com o `.custom.md` ao invocar um subagente.
   - Atualizações core NUNCA modificam nem removem arquivos `*.custom.md`.
5. **Execução em Lote e Anti-Ping-Pong (Batching Mandatório)**:
   - Proibido roundtrips sequenciais de inspeção (`read` arquivo por arquivo em turnos isolados).
   - Emita leituras em lote (`parallel tool calls` no mesmo turno) para arquivos conhecidos.
   - Para varredura ampla (>3 arquivos), use um único comando/script de terminal que filtre e entregue apenas as linhas necessárias.
   - Planeje ações para resolver o objetivo com o menor número possível de voltas à LLM.

6. **Especialização por Role (sem paralelismo)**:
   - O `planner` marca tarefas com `role: backend|frontend|generic` e `files:`. Ordem: backend -> frontend -> generic, sempre em sequência.
   - `designer` roda após o `architect` apenas se a spec tiver `ui: true`; gera `.loop/design/<id>.md` com critérios `VIS-XX`.
   - `judge_backend`/`judge_frontend` apenas reportam; só o `tester_judge` emite o veredito único, após passada de integração.

---

## 3. Fluxo de Inicialização (Novo Workspace)

Quando acionada sem o parâmetro `update`:

### Etapa 0: Detecção de Arquivos de Instrução Existentes (Merge Não Destrutivo)

ANTES de criar qualquer arquivo, procure instruções de agentes já existentes na raiz do workspace:
`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `QWEN.md`, `CONVENTIONS.md`, `.cursorrules`, `.windsurfrules`, `.github/copilot-instructions.md`, `.clinerules`.

**Regra de ouro: NUNCA sobrescrever nem apagar o conteúdo existente.** A skill só ADICIONA capacidades.

1. **Backup**: antes de editar, copie cada arquivo encontrado para `<arquivo>.bak-loop` (ex.: `CLAUDE.md.bak-loop`), se ainda não existir.
2. **Bloco gerenciado**: o conteúdo da skill é inserido entre marcadores, ao FINAL do arquivo:
   ```markdown
   <!-- LOOP-ENGINEERING:BEGIN (gerenciado por /loop-engineering-init; não edite dentro do bloco) -->
   ... manifesto do loop (princípios, mapa, ciclo, roteamento por role) ...
   <!-- LOOP-ENGINEERING:END -->
   ```
   - Se o bloco já existir (re-execução/`update`), substitua SOMENTE o conteúdo entre os marcadores.
   - Tudo fora dos marcadores é do usuário e permanece intacto.
3. **Qual arquivo recebe o bloco**:
   - `AGENTS.md` existe: insira o bloco nele.
   - `AGENTS.md` não existe: crie `AGENTS.md` com o manifesto completo (dentro dos marcadores).
   - Para cada outro arquivo encontrado (`CLAUDE.md`, `GEMINI.md`, etc.): insira um bloco curto de ponte, também entre marcadores, dizendo: "Este projeto usa Harness & Loop Engineering. Leia e siga `AGENTS.md` (bloco LOOP-ENGINEERING), `.agents/SOUL.md` e `.loop/SCHEDULE.md`."
   - Nenhum arquivo é criado para ferramentas que o projeto não usa (não crie `GEMINI.md` se não existir, a menos que o usuário peça).
4. **Conflitos**: se regras existentes contradisserem o loop (ex.: "nunca use subagentes"), NÃO resolva sozinho. Liste os conflitos e pergunte ao usuário via `ask_user_question`. Instruções do usuário/projeto têm precedência sobre o bloco.
5. **Relatório**: informe quais arquivos foram detectados, quais receberam bloco, onde ficaram os backups e eventuais conflitos.

### Etapa 1: Inspeção do Workspace Atual
1. Verifique se o diretório atual já possui arquivos com `glob *`.
2. **Se o diretório estiver VAZIO**:
   - É um projeto novo. Siga direto para o questionário de configuração inicial (Etapa 2).
3. **Se o diretório JÁ POSSUIR arquivos de código**:
   - Pergunte ao usuário se deseja executar uma análise prévia com `graft` para mapear a arquitetura antes de gerar a governança.
   - Se autorizado, execute:
     ```bash
     /home/robson/.npm-global/bin/graft build .
     /home/robson/.npm-global/bin/graft map .
     ```
   - Utilize a saída do graft para pré-preencher a memória técnica (`.agents/MEMORY.md`).

### Etapa 2: Questionário de Alinhamento Inicial
Use `ask_user_question` para obter:
1. **Nome e Objetivo do Projeto**: Qual o objetivo central e contexto de negócio.
2. **Stack Técnica e Frameworks**: Ex: Node.js/TypeScript, Python, Go, Rust, etc.
3. **Comando Padrão de Testes**: Comando exato para rodar a suíte (ex: `npm test`, `pytest`, etc.) que servirá de critério de parada (TDD).
4. **Preferência de Persistência**: Confirmar criação do `.agents/memory.sqlite`.

### Etapa 3: Criação da Estrutura de Arquivos
Crie a estrutura completa utilizando as ferramentas de arquivo nativas:

```text
/
├── AGENTS.md                  # Manifesto mestre (se já existir: apenas bloco LOOP-ENGINEERING é inserido)
├── AGENTS.custom.md           # [Opcional] Regras mestres específicas do projeto
│
├── .agents/                   # Governança e inteligência dos agentes
│   ├── SOUL.md                # Personalidade e leis inegociáveis do Coordenador (Core)
│   ├── SOUL.custom.md         # [Opcional] Ajustes comportamentais locais
│   ├── MEMORY.md              # Convenções técnicas, aprendizados e stack coletada
│   ├── schema.sql             # DDL relacional (demands, tasks, evals, decisions, events)
│   ├── memory.sqlite          # Banco SQLite inicializado via python3 sqlite3
│   └── roles/                 # Subagentes especializados (Core)
│       ├── scope_analyst.md
│       ├── scope_analyst.custom.md   # [Opcional]
│       ├── architect.md
│       ├── architect.custom.md       # [Opcional]
│       ├── planner.md
│       ├── planner.custom.md         # [Opcional]
│       ├── designer.md               # Só acionado se spec ui: true
│       ├── designer.custom.md        # [Opcional]
│       ├── builder.md                # Fallback genérico (role: generic)
│       ├── builder.custom.md         # [Opcional]
│       ├── builder_backend.md        # role: backend
│       ├── builder_backend.custom.md # [Opcional]
│       ├── builder_frontend.md       # role: frontend
│       ├── builder_frontend.custom.md # [Opcional]
│       ├── judge_backend.md          # Relatório de backend (não decide)
│       ├── judge_backend.custom.md   # [Opcional]
│       ├── judge_frontend.md         # Relatório de UI (não decide)
│       ├── judge_frontend.custom.md  # [Opcional]
│       ├── tester_judge.md
│       └── tester_judge.custom.md    # [Opcional]
│
└── .loop/                     # Ciclo de vida operacional
    ├── SCHEDULE.md            # Gatilhos de despertar e limites de ciclos
    ├── specs/                 # Especificações de demandas (000-template.md)
    ├── design/                # Specs visuais (<id>.md) do designer
    ├── tasks/                 # Fila de execução da rodada (current_run.md)
    └── evals/                 # Veredito e relatórios de testes (last_eval.md)
```

### Etapa 4: Inicialização do SQLite
Execute script Python inline para garantir a criação do banco:
```bash
python3 -c "import sqlite3; conn = sqlite3.connect('.agents/memory.sqlite'); f = open('.agents/schema.sql', 'r'); conn.executescript(f.read()); conn.close(); print('DB inicializado')"
```

---

## 4. Fluxo de Atualização / Auditoria (`update`)

Quando acionada para atualização (`/loop-engineering-init update` ou após melhorias globais):

1. **Auditoria de Existência**:
   - Verifica presença de `AGENTS.md` e pasta `.agents/`. Se ausentes, orienta rodar a inicialização completa.
2. **Atualização Segura de Arquivos Core**:
   - Em `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` e demais arquivos de instrução: atualiza SOMENTE o conteúdo entre `<!-- LOOP-ENGINEERING:BEGIN -->` e `<!-- LOOP-ENGINEERING:END -->`. Se o arquivo existir sem marcadores, aplique a Etapa 0 (insere o bloco ao final, com backup). Nunca sobrescreva o arquivo inteiro.
   - Sobrescreve/atualiza apenas os demais arquivos padrão da orquestração:
     - `.agents/SOUL.md`
     - `.agents/roles/architect.md`
     - `.agents/roles/planner.md`
     - `.agents/roles/builder.md`
     - `.agents/roles/tester_judge.md`
     - `.agents/roles/scope_analyst.md`
     - `.agents/roles/designer.md`
     - `.agents/roles/builder_backend.md`
     - `.agents/roles/builder_frontend.md`
     - `.agents/roles/judge_backend.md`
     - `.agents/roles/judge_frontend.md`
     - Criar `.loop/design/` se ausente; adicionar `ui: false` ao template de spec e `role:`/`files:` ao `current_run.md`; atualizar `.loop/SCHEDULE.md` para o roteamento por role.
3. **Preservação Absoluta de Customizações**:
   - Todos os arquivos `*.custom.md` são mantidos intactos.
   - O banco `.agents/memory.sqlite` NUNCA é reinicializado nem modificado na atualização.
   - As especificações em `.loop/specs/` e histórico em `.loop/evals/` permanecem inalterados.
   - Em `.agents/MEMORY.md`, novas lições aprendidas são inseridas sob nova seção sem apagar anotações do projeto.
4. **Relatório de Atualização**:
   - Reporta ao usuário quais arquivos core foram atualizados, quais guard-rails foram incorporados e confirma a preservação dos overlays customizados.
