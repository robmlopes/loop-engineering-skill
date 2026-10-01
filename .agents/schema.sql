-- Schema do Banco de Dados de Memória e Rastreamento do Loop
-- Arquivo: .agents/memory.sqlite

CREATE TABLE IF NOT EXISTS demands (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    spec_file TEXT NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('DRAFT', 'PLANNED', 'IN_PROGRESS', 'VALIDATING', 'DONE', 'BLOCKED')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tasks (
    id TEXT PRIMARY KEY,
    demand_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    assigned_role TEXT NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('PENDING', 'IN_PROGRESS', 'BLOCKED', 'DONE')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(demand_id) REFERENCES demands(id)
);

CREATE TABLE IF NOT EXISTS eval_runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    demand_id TEXT NOT NULL,
    run_number INTEGER NOT NULL,
    passed INTEGER NOT NULL CHECK(passed IN (0, 1)),
    test_summary TEXT NOT NULL,
    failure_details TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(demand_id) REFERENCES demands(id)
);

CREATE TABLE IF NOT EXISTS decisions_log (
    id TEXT PRIMARY KEY,
    demand_id TEXT,
    decision TEXT NOT NULL,
    reason TEXT NOT NULL,
    impact TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(demand_id) REFERENCES demands(id)
);

CREATE TABLE IF NOT EXISTS loop_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    demand_id TEXT,
    trigger_type TEXT NOT NULL, -- 'HUMAN', 'GOAL_SCHEDULE', 'EVAL_FAIL', 'COMPLETION'
    source_role TEXT NOT NULL,
    event_type TEXT NOT NULL,
    payload TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(demand_id) REFERENCES demands(id)
);

-- Triggers para atualização automática de updated_at
CREATE TRIGGER IF NOT EXISTS trg_demands_updated_at
AFTER UPDATE ON demands
FOR EACH ROW
BEGIN
    UPDATE demands SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

CREATE TRIGGER IF NOT EXISTS trg_tasks_updated_at
AFTER UPDATE ON tasks
FOR EACH ROW
BEGIN
    UPDATE tasks SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;
