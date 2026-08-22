"""migrate_knowledge_chunks.py

Adds new RAG columns to the existing knowledge_chunks table in SQLite.
Run once: uv run python scripts/migrate_knowledge_chunks.py
"""
import sqlite3
import os
import sys

DB_PATH = os.path.join(os.path.dirname(__file__), "..", "schemora_dev.db")

NEW_COLUMNS = [
    ("section",           "TEXT"),
    ("scheme_name",       "TEXT"),
    ("jurisdiction",      "TEXT"),
    ("state",             "TEXT"),
    ("category",          "TEXT"),
    ("source_id",         "TEXT"),
    ("official_info_url", "TEXT"),
    ("official_app_url",  "TEXT"),
    ("last_verified_at",  "TEXT"),
    ("scheme_version",    "TEXT"),
    ("is_indexed",        "INTEGER NOT NULL DEFAULT 0"),
]

def migrate():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.execute("PRAGMA table_info(knowledge_chunks)")
    existing_cols = {row[1] for row in cur.fetchall()}
    print(f"Existing columns: {sorted(existing_cols)}")

    added = []
    for col_name, col_type in NEW_COLUMNS:
        if col_name not in existing_cols:
            sql = f"ALTER TABLE knowledge_chunks ADD COLUMN {col_name} {col_type}"
            conn.execute(sql)
            added.append(col_name)
            print(f"  [OK] Added column: {col_name} ({col_type})")
        else:
            print(f"  - Skipped (exists): {col_name}")

    conn.commit()
    conn.close()
    print(f"\nMigration complete. Added {len(added)} column(s): {added}")

if __name__ == "__main__":
    migrate()
