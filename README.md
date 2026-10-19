# Loop Engineering Skill

Skill que instala **Harness & Loop Engineering** em qualquer projeto: um ciclo de desenvolvimento com agentes de IA orientado por especificação, TDD e verificação objetiva de parada.

O usuário fala só com o **Coordenador**. Ele delega o trabalho a subagentes especializados (cada um com contexto isolado) e só encerra quando o `tester_judge` aprova.

---

## 1. O que a skill instala

```text
/
├── AGENTS.md                  # Manifesto (bloco LOOP-ENGINEERING gerenciado)
├── .agents/
│   ├── SOUL.md                # Leis do Coordenador
│   ├── MEMORY.md              # Convenções e lições aprendidas
│   ├── schema.sql / memory.sqlite   # Histórico, tarefas e evals (SQLite)
│   └── roles/                 # Papéis dos subagentes (+ *.custom.md opcionais)
└── .loop/
    ├── SCHEDULE.md            # Gatilhos, rotina de despertar, limites
    ├── specs/                 # Especificações (000-template.md)
    ├── design/                # Specs visuais do designer
    ├── tasks/                 # current_run.md
    └── evals/                 # last_eval.md
```

### Papéis

| Papel | Função |
|---|---|
| `scope_analyst` | Refina requisitos e não-objetivos; gera a spec (`ui: true\|false`) |
| `architect` | Contratos, estruturas e migrações |
| `designer` | Direção visual e critérios `VIS-XX` (só se `ui: true`) |
| `planner` | Testes primeiro (TDD) e tarefas com `role:` e `files:` |
| `builder_backend` | APIs, banco, migrações, regras de negócio |
| `builder_frontend` | Interface conforme o design, com todos os estados |
| `builder` | Fallback para scripts, infra e CLI (`role: generic`) |
| `judge_backend` / `judge_frontend` | Relatórios especializados (apenas reportam) |
| `tester_judge` | Integração ponta a ponta e **veredito único** |

### Ciclo

```text
scope_analyst → architect → [designer*] → planner
   → builder_backend → builder_frontend → builder
   → judge_backend / judge_frontend → tester_judge (APROVADO/REPROVADO)
                        *só se a spec tiver ui: true
```

Os builders rodam **sempre em sequência**, sem paralelismo, para evitar conflitos de escrita e de SQLite.

---

## 2. Pré-requisitos

- Um agente compatível com skills e subagentes (por exemplo Claude Code ou DeepSeek Harness/DSH).
- `git` e `python3` (usado para criar o banco SQLite).
- Opcional: `graft`, para mapear a arquitetura de projetos já existentes.

---

## 3. Instalação da skill

Clone o repositório e copie a pasta da skill para o diretório de skills do seu agente.

```bash
git clone git@github.com:robmlopes/loop-engineering-skill.git
cd loop-engineering-skill
```

Escolha o destino conforme o agente:

```bash
# Claude Code
mkdir -p ~/.claude/skills && cp -r skill/loop-engineering ~/.claude/skills/

# DSH / agentes que usam ~/.agents
mkdir -p ~/.agents/skills && cp -r skill/loop-engineering ~/.agents/skills/
```

Confirme que o arquivo existe:

```bash
ls ~/.claude/skills/loop-engineering/SKILL.md
```

Reinicie a sessão do agente para ele carregar a skill.

---

## 4. Usando em um projeto

Abra o agente na raiz do projeto e rode:

```text
/loop-engineering init
```

(ou peça: "inicialize o loop engineering").

A skill vai:

1. **Procurar arquivos de instrução existentes** (veja a seção 5).
2. Se o projeto já tem código, perguntar se você quer uma análise prévia com `graft`.
3. Fazer um questionário: nome e objetivo, stack, comando de testes (critério de parada) e criação do SQLite.
4. Criar a estrutura `.agents/` e `.loop/` e inicializar o banco.

### Fluxo de uma demanda

1. Descreva a funcionalidade ao Coordenador.
2. O `scope_analyst` escreve a spec em `.loop/specs/<id>.md`. Você valida.
3. `architect`, `designer` (se houver UI) e `planner` preparam contratos, design e tarefas.
4. O loop roda: builders por role, judges e `tester_judge`.
5. Se reprovar, as pendências voltam ao builder da especialidade (máximo de 5 rodadas; após 3 falhas com a mesma causa o loop escala para você).
6. Se aprovar, `MEMORY.md` e o SQLite são atualizados.

---

## 5. Projetos que já têm `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`...

A instalação **nunca sobrescreve** instruções existentes. Antes de criar qualquer coisa, a skill procura:

`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `QWEN.md`, `CONVENTIONS.md`, `.cursorrules`, `.windsurfrules`, `.github/copilot-instructions.md`, `.clinerules`.

Para cada arquivo encontrado:

- Faz um **backup** `<arquivo>.bak-loop`.
- Insere ao final um **bloco gerenciado** entre marcadores:
  ```markdown
  <!-- LOOP-ENGINEERING:BEGIN ... -->
  ...
  <!-- LOOP-ENGINEERING:END -->
  ```
- Tudo fora dos marcadores continua seu. Em re-execuções e no `update`, só o conteúdo entre os marcadores é substituído.
- No `AGENTS.md`, o bloco traz o manifesto completo. Nos outros (`CLAUDE.md`, `GEMINI.md`...), entra um bloco curto de ponte que manda o agente seguir o `AGENTS.md`, o `.agents/SOUL.md` e o `.loop/SCHEDULE.md`.
- Se alguma regra sua contradiz o loop, a skill **pergunta a você** antes de decidir. As suas instruções têm precedência.
- Ela não cria arquivos de ferramentas que você não usa.

---

## 6. Personalização (`*.custom.md`)

Regras específicas do projeto ficam em arquivos irmãos dos papéis, por exemplo `.agents/roles/builder_frontend.custom.md`. O Coordenador junta o core com o `.custom.md` ao invocar o subagente. Em caso de conflito, o custom vence. Atualizações nunca tocam nos `*.custom.md`.

---

## 7. Atualização

```text
/loop-engineering update
```

Atualiza os papéis, o `SOUL.md`, o `SCHEDULE.md` e o bloco `LOOP-ENGINEERING` dos arquivos de instrução. Preserva os `*.custom.md`, o `memory.sqlite`, as specs e os evals. Ao final, mostra um relatório do que mudou.

Para atualizar a própria skill: `git pull` neste repositório e copie a pasta `skill/loop-engineering` de novo para o diretório de skills.

---

## 8. Guard-rails

- **Spec-driven e TDD**: nenhum código sem spec e critérios de teste prévios.
- **Parada objetiva**: só o `tester_judge` encerra o loop.
- **Migração retrocompatível**: bancos legados em disco são preservados; migrações idempotentes.
- **Anti-swallow**: proibido `try/except pass` e erros silenciosos, especialmente na UI.
- **Sem paralelismo de subagentes**: um builder por vez.
- **Circuit breakers**: máximo de 5 rodadas de correção e escalação após 3 falhas com a mesma causa.

---

## 9. Versões

Veja as [Releases](https://github.com/robmlopes/loop-engineering-skill/releases).
