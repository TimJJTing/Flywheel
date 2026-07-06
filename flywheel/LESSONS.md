# Lessons — append-only. Format: YYYY-MM-DD | task | tier path | cause | rule to update (if any)
2026-07-06 | v0.1 pre-release audit | coordinator→auditor | dogfooding conflict: payload state/STATUS/config doubled as install templates, shipping flywheel's own data + unresolvable hashes into fresh targets | INSTALL now sources owned files from defaults/
2026-07-06 | E2E verification | engineer→verifier | check.sh hash loop dropped unterminated final line (read EOF) — last commit hash silently unchecked | check.sh read guard added
