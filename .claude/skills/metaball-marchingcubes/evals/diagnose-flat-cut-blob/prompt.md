---
tags: [metaball-marchingcubes]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

three.js の MarchingCubes (resolution 48, isolation 60) でメタボールを 3 つ回してるんだけど、手前に来た球の側面がスパッと平らに切れて見える。addBall は strength 3.4、subtract 12、球の中心は 0.5 ± 0.32 の範囲で動かしてる。resolution を 64 にしても直らない。原因と直し方を教えて。
