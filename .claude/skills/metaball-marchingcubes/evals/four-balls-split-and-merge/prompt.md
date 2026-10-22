---
tags: [metaball-marchingcubes]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

three.js の MarchingCubes で、4 つの球が正方形に並んで回りながら、周期的に中央へ寄って 1 塊になり、また 4 つに分かれるアニメーションを作りたい。isolation は 60、subtract は 12 のまま。球の strength と軌道半径 (場の単位) と mesh の scale を決めて、理由つきで HTML (metaball4.html) を書いて。
