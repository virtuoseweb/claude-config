#!/usr/bin/env bash
# vw-guardrails — hook SessionStart PLUGIN (marketplace virtuoseweb/claude-config).
# Recharge les garde-fous VirtuoseWeb au boot, EN CLOUD comme EN LOCAL.
# Pourquoi un plugin : en cloud (Claude Code on the web) le ~/.claude global n'est PAS cloné ;
# seuls le repo + les plugins déclarés dans .claude/settings.json s'installent au démarrage
# (doc : code.claude.com/docs/en/claude-code-on-the-web). Ce hook garantit que les GF-1..GF-6
# sont présents partout, sans dépendre du ~/.claude local.
# Portable : bash + python3 (présents dans le sandbox cloud). Aucun chemin ~/.claude en dur.
set -euo pipefail

# Repo courant (cwd au lancement de la session)
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
LAST="$(git log -1 --pretty='%h %s' 2>/dev/null || echo '?')"
REPO="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")"

if [ -n "${CLAUDE_CODE_REMOTE_SESSION_ID:-}" ]; then
  # CLOUD : le ~/.claude global est ABSENT → on injecte les garde-fous COMPLETS.
  CTX="## 🛡️ Garde-fous VirtuoseWeb rechargés (plugin vw-guardrails — ☁️ CLOUD)

Repo : \`$REPO\` · branche \`$BRANCH\` · dernier commit \`$LAST\`
Surface : CLOUD (VM Anthropic). Le ~/.claude global est ABSENT — seuls le repo CLAUDE.md + ce plugin s'appliquent (pas de rules-enforcer global, pas de MCP perso sauf .mcp.json repo).

- **GF-1 — preuve EMPIRIQUE** : jamais « validé / fini / parfait » sans preuve, dans le meme turn.
  · Visuel (UI/CSS/anim/front) : Playwright screenshot above-fold + \`getComputedStyle\` H1/CTA (opacity≠0, transform neutre) sur la **preview/prod deployee** (Lighthouse ne suffit JAMAIS).
  · Backend/API/DB/job/full-stack : appel reel + assertion sur la reponse (pas juste 200) + etat persiste verifie (write→read DB) + cas limite/erreur + flow E2E (Playwright/computer-use) si full-stack. « ca build / 200 OK » ≠ « ca marche ». Reviewer dedie : agent \`visual-proof-reviewer\`.
- **GF-2 — delegation** : l'orchestrateur ecrit ≤ 3 lignes de code applicatif ; au-dela → worker/sous-agent. Decomposer, ne pas tout faire en mono-bloc.
- **GF-3 — auto-evolution** : apres une correction, capitaliser (rule/doc + validation) dans le meme tour.
- **GF-4 — triangulation** : grep + source \`fichier:ligne\` avant toute affirmation negative (« X n'existe pas »).
- **GF-5 — action directe** : si N actions parallelisables sans collision → agir, ne pas demander « lequel d'abord ». Validation seulement pour : paiement, destructif, install non-demandee, envoi externe, securite.
- **GF-6 — officiel/doc d'abord + invoquer l'arsenal** : lire la doc + leviers supportes avant tout sur-mesure ; invoquer directement skills/commandes/agents (ne pas suggerer a l'humain de taper).

➡️ **Lire le \`CLAUDE.md\` du repo EN PREMIER** (+ \`docs/\` de reprise s'il existe). En cloud, c'est ton contrat principal."
else
  # LOCAL : le ~/.claude global injecte deja GF-1..GF-6 (session-resume-context.sh) → on evite la redondance.
  CTX="## 🛡️ vw-guardrails actif (💻 LOCAL) — repo \`$REPO\` (\`$BRANCH\`, \`$LAST\`)
Garde-fous GF-1..GF-6 fournis par le ~/.claude global. Reviewer preuve : agent \`visual-proof-reviewer\`. Commande : \`/vw-guardrails:guardrails\`. Lire le CLAUDE.md du repo en premier."
fi

export CTX
python3 -c '
import os, json
print(json.dumps({
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": os.environ.get("CTX", "")
  }
}))
'
