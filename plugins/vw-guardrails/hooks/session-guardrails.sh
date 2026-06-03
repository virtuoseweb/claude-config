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

### Discipline d'orchestration & qualite (condense des rules fondamentales — ABSENTES du ~/.claude en cloud)
- **Delegation/decomposition** : decompose en sous-taches + sous-agents ; l'orchestrateur reste leger (≤ 3 LoC applicatif), les workers executent. Focused < 200 LoC → Task subagent ; mission longue → \`claude --bg\` ; debate/cross-layer → agent teams ; grande echelle (audit/migration) → workflow.
- **Preuve avant « valide »** : tsc/astro check + build OK + (preuve VISUELLE GF-1 si rendu, OU preuve FONCTIONNELLE si backend) + persistence verifiee. Toute sortie worker = hypothese jusqu'a verif independante. Donne la preuve (output/screenshot), pas l'assertion.
- **Pas de report passif** : si N actions parallelisables sans collision → agir, ne pas demander « lequel d'abord » ni renvoyer a « plus tard ». Validation seulement pour paiement/destructif/install/externe/securite.
- **Source avant affirmation negative** : grep + \`fichier:ligne\` avant « X n'existe pas / ne marche pas ».
- **Plan** : toute tache ≥ 3 etapes → plan + checkpoints \`[ ]\` coches avec preuve (3 niveaux 🟢/🟡/🔴).
- **Branches isolees** : 1 scope = 1 branche \`feat/<scope>\`, jamais \`git add -A\` global ; merge sur main uniquement apres preuve GF-1.
- ⚠️ **En cloud, PAS de Playwright/MCP perso sauf \`.mcp.json\` repo** : si la preuve VISUELLE est requise et qu'aucun MCP n'est dispo, lancer Playwright via \`npx\` (chromium pre-installe) OU faire le sweep visuel en LOCAL.

### Ressources vw-guardrails dispo en cloud (le ~/.claude global etant absent)
- **VW Cloud Playbook** (rules dev/qualite/orchestration condensees, cloud-adaptees) : \`\${CLAUDE_PLUGIN_ROOT}/reference/vw-cloud-playbook.md\` — lis-le quand tu hesites sur la discipline (orchestration, preuve, plan, build, design system, autonomie).
- **Routage situationnel auto** : a chaque prompt, le hook \`rules-router.sh\` injecte les hints des rules pertinentes selon tes mots-cles (equivalent cloud du rules-enforcer global).
- **Agents a invoquer** (tool \`Agent\`) : \`visual-proof-reviewer\` (preuve visuelle/fonctionnelle), \`code-reviewer\` (qualite/securite), \`code-explorer\` (cartographie archi en lecture seule). Delegue-leur au lieu de tout faire en mono-bloc.

➡️ **Lire le \`CLAUDE.md\` du repo EN PREMIER** (+ \`docs/\` de reprise s'il existe). En cloud, c'est ton contrat principal."
else
  # LOCAL : les GF vivent dans le CLAUDE.md du repo (source portable) + le ~/.claude global S'IL est present.
  # On ne PRESUME pas la presence du global (un collaborateur tiers ne l'a pas) → on pointe le contrat du repo.
  CTX="## 🛡️ vw-guardrails actif (💻 LOCAL) — repo \`$REPO\` (\`$BRANCH\`, \`$LAST\`)
Garde-fous GF-1..GF-6 : voir la section « Garde-fous » du **CLAUDE.md du repo** (source portable, presente meme sans config globale), completee par le ~/.claude global s'il est present. Reviewer preuve : agent \`visual-proof-reviewer\`. Commande : \`/vw-guardrails:guardrails\`. Lire le CLAUDE.md du repo EN PREMIER."
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
