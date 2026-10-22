#!/usr/bin/env python3
"""positive:/negative:/--- 形式のプロンプト一覧を SQLite (FTS5) に取り込む。

使い方:
    python build_db.py <input.txt> [output.db]

- 'positive: ' で始まる行だけを採用し、完全一致の重複は初出だけ残す
- prompts        : 本体テーブル (id, prompt, nwords)
- prompts_fts    : FTS5 全文索引 (porter ステミング付き。clown で clowns も当たる)
- 既存の DB があれば作り直す
"""
import os
import sqlite3
import sys
import time

PREFIX = "positive: "


def iter_prompts(path):
    seen = set()
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            if not line.startswith(PREFIX):
                continue
            p = line[len(PREFIX):].strip()
            if not p or p in seen:
                continue
            seen.add(p)
            yield p


def build(src, dst):
    if os.path.exists(dst):
        os.remove(dst)
    con = sqlite3.connect(dst)
    con.executescript(
        """
        PRAGMA journal_mode = OFF;
        PRAGMA synchronous = OFF;
        CREATE TABLE prompts (
            id      INTEGER PRIMARY KEY,
            prompt  TEXT NOT NULL UNIQUE,
            nwords  INTEGER NOT NULL
        );
        CREATE VIRTUAL TABLE prompts_fts USING fts5(
            prompt,
            content = 'prompts',
            content_rowid = 'id',
            tokenize = 'porter unicode61',
            prefix = '2 3 4'
        );
        """
    )
    t0 = time.time()
    rows = ((p, len(p.split())) for p in iter_prompts(src))
    con.executemany("INSERT INTO prompts(prompt, nwords) VALUES (?, ?)", rows)
    con.execute("INSERT INTO prompts_fts(prompts_fts) VALUES ('rebuild')")
    con.execute("INSERT INTO prompts_fts(prompts_fts) VALUES ('optimize')")
    n = con.execute("SELECT count(*) FROM prompts").fetchone()[0]
    con.commit()
    con.execute("VACUUM")
    con.close()
    size = os.path.getsize(dst) / 1e6
    print(f"{n} prompts -> {dst} ({size:.1f} MB) in {time.time() - t0:.1f}s")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    src = sys.argv[1]
    dst = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "prompts.db")
    build(src, dst)
