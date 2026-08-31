"""Schemora Database Diagnostic Script."""
import sqlite3
import json
import sys
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "..", "schemora_dev.db")
db_path = os.path.abspath(DB_PATH)

print(f"\n{'='*60}")
print("SCHEMORA DATABASE DIAGNOSTIC")
print(f"{'='*60}")
print(f"DB Path: {db_path}")
print(f"DB Exists: {os.path.exists(db_path)}")
print(f"DB Size: {os.path.getsize(db_path) if os.path.exists(db_path) else 'N/A'} bytes")

if not os.path.exists(db_path):
    print("ERROR: Database file not found!")
    sys.exit(1)

conn = sqlite3.connect(db_path)
cur = conn.cursor()

# List tables
cur.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
tables = [r[0] for r in cur.fetchall()]
print(f"\nTABLES FOUND: {tables}")

# Schemes table
if 'schemes' in tables:
    cur.execute("SELECT COUNT(*) FROM schemes")
    print(f"\nSCHEMES TABLE: {cur.fetchone()[0]} records")
    cur.execute("SELECT id, title, is_published FROM schemes LIMIT 5")
    for row in cur.fetchall():
        print(f"  - {row[0][:30]} | published={row[2]}")

# Knowledge documents
if 'knowledge_documents' in tables:
    cur.execute("SELECT COUNT(*) FROM knowledge_documents")
    doc_count = cur.fetchone()[0]
    print(f"\nKNOWLEDGE DOCUMENTS: {doc_count}")
else:
    print("\nERROR: knowledge_documents table MISSING!")

# Knowledge chunks
if 'knowledge_chunks' in tables:
    cur.execute("SELECT COUNT(*) FROM knowledge_chunks")
    total = cur.fetchone()[0]
    print(f"\nKNOWLEDGE CHUNKS: {total} total")

    cur.execute("SELECT COUNT(*) FROM knowledge_chunks WHERE is_indexed=1")
    semantic = cur.fetchone()[0]
    print(f"  Semantic (Gemini embedded): {semantic}")
    print(f"  TF-IDF fallback: {total - semantic}")

    cur.execute("SELECT COUNT(DISTINCT scheme_id) FROM knowledge_chunks WHERE scheme_id IS NOT NULL")
    distinct = cur.fetchone()[0]
    print(f"  Distinct schemes indexed: {distinct}")

    cur.execute("SELECT COUNT(*) FROM knowledge_chunks WHERE embedding_json IS NULL OR embedding_json = '{}'")
    null_emb = cur.fetchone()[0]
    print(f"  Null/empty embeddings: {null_emb}")

    # Sample embedding analysis
    print("\n--- SAMPLE CHUNKS ---")
    cur.execute("SELECT id, scheme_name, section, embedding_json FROM knowledge_chunks LIMIT 8")
    for row in cur.fetchall():
        emb_json = row[3]
        if emb_json:
            try:
                emb = json.loads(emb_json)
                if isinstance(emb, list):
                    emb_info = f"DENSE list[{len(emb)}]"
                elif isinstance(emb, dict):
                    emb_info = f"TF-IDF dict({len(emb)} terms)"
                else:
                    emb_info = f"UNKNOWN type={type(emb)}"
            except Exception as e:
                emb_info = f"JSON_ERROR: {e}"
        else:
            emb_info = "NULL"
        print(f"  [{row[2]:12}] {str(row[1] or '')[:35]:35} | emb={emb_info}")

    # Scheme breakdown
    print("\n--- SCHEME CHUNK COUNTS ---")
    cur.execute("""
        SELECT scheme_name, COUNT(*) as cnt, 
               SUM(CASE WHEN is_indexed=1 THEN 1 ELSE 0 END) as semantic
        FROM knowledge_chunks 
        WHERE scheme_name IS NOT NULL 
        GROUP BY scheme_name 
        ORDER BY cnt DESC
        LIMIT 20
    """)
    for row in cur.fetchall():
        print(f"  {str(row[0])[:50]:50} | chunks={row[1]} | semantic={row[2]}")

    # Sections coverage
    print("\n--- SECTION COVERAGE ---")
    cur.execute("""
        SELECT section, COUNT(*) as cnt
        FROM knowledge_chunks
        GROUP BY section
        ORDER BY cnt DESC
    """)
    for row in cur.fetchall():
        print(f"  section={row[0]:15} | count={row[1]}")

else:
    print("\nERROR: knowledge_chunks table MISSING!")

conn.close()
print(f"\n{'='*60}")
print("DIAGNOSTIC COMPLETE")
print(f"{'='*60}")
