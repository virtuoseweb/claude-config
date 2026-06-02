#!/usr/bin/env bash
# vw-guardrails — hook UserPromptSubmit : routage situationnel des rules EN CLOUD.
# Mire l'architecture hybride locale (rules-enforcer.sh) : sur mot-clé du prompt,
# injecte un hint actionnable + un pointeur vers la section du VW Cloud Playbook.
#
# CLOUD-GATED : ne s'active QUE en cloud (CLAUDE_CODE_REMOTE_SESSION_ID présent).
# En local, le ~/.claude/hooks/rules-enforcer.sh global fait déjà ce travail → on reste muet
# pour éviter la double injection (GF : 1 implémentation par besoin).
#
# Portable : bash + python3. Lit le prompt sur stdin (JSON UserPromptSubmit).
set -uo pipefail

# En LOCAL : ne rien faire (le global s'en charge).
if [ -z "${CLAUDE_CODE_REMOTE_SESSION_ID:-}" ]; then
  exit 0
fi

# Lit le prompt depuis stdin (JSON : { "prompt": "..." }).
PROMPT="$(python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    print((d.get("prompt") or d.get("user_prompt") or "").lower())
except Exception:
    print("")
' 2>/dev/null || echo "")"

[ -z "$PROMPT" ] && exit 0

PB="${CLAUDE_PLUGIN_ROOT:-<plugin>}/reference/vw-cloud-playbook.md"
HINTS=""
add() { HINTS="${HINTS}
- $1"; }
match() { echo "$PROMPT" | grep -qE "$1"; }

# --- Mapping mot-clé → hint actionnable (blocs if = set -e safe) ---
if match 'refactor|css|animation|anim|style|hero|section|composant|component|layout|tailwind|design|front'; then
  add "**Rendu visuel** → GF-1 piste VISUELLE avant « validé » : Playwright screenshot above-fold (preview déployée) + \`getComputedStyle()\` H1/CTA (opacity≠0). Lighthouse ne suffit pas. Playbook §2."
fi
if match '\bapi\b|endpoint|backend|\bdb\b|database|migration|\bsql\b|server|job|cron|webhook'; then
  add "**Backend/API/DB** → GF-1 piste FONCTIONNELLE : appel réel + assertion réponse (pas juste 200) + write→read DB vérifié + cas limite. Playbook §2."
fi
if match 'build|deploy|déploi|deploie|vercel|\bpush\b|merge|prod|release'; then
  add "**Build/Deploy** → build complet AVANT push (astro check ≠ build OK) ; 1 scope = 1 branche \`feat/<scope>\` ; merge main UNIQUEMENT après GF-1 sur preview ; auto-merge OFF. Playbook §5."
fi
if match '\btest\b|playwright|\be2e\b|vérif|verif|valider|validation|\bqa\b'; then
  add "**Test/validation** → preuve empirique, pas assertion. Worker output = hypothèse jusqu'à vérif indépendante. Playbook §2."
fi
if match 'review|\baudit\b|relire|relis|code review'; then
  add "**Review** → invoquer DIRECTEMENT un agent : \`visual-proof-reviewer\` (preuve) ou \`code-reviewer\` (qualité/sécurité). Pas de review mono-bloc."
fi
if match 'plan|architecture|archi |refonte|gros refactor|stratégie|strategie|découpe|decoupe'; then
  add "**Plan/archi** → tâche ≥ 3 étapes : plan + checkpoints \`[ ]\` (🟢/🟡/🔴) AVANT d'exécuter. Grande échelle → workflow ou agent teams. Playbook §1 + §3."
fi
if match 'registry|design system|design-system|\bds\b|template|token|catalogue|biblioth'; then
  add "**Design system** → composition, PAS création : 0 nouveau token, synchronise TOUS les touchpoints d'un type (schéma+demo+registry+composant). Playbook §6."
fi
if match 'délégu|delegu|worker|parallèle|parallele|sous.?agent|subagent|orchestr|agent team|workflow'; then
  add "**Orchestration** → décomposer, router au modèle+effort minimum. Focused<200 LoC = Task subagent ; debate/cross-layer = agent teams ; grande échelle = workflow. Orchestrateur ≤ 3 LoC applicatif. Playbook §1."
fi
if match "n'existe pas|nexiste pas|pas documenté|pas documente|introuvable|ne marche pas|marche pas"; then
  add "**Affirmation négative** → GF-4 : \`grep\`/\`Grep\` + source \`fichier:ligne\` AVANT d'affirmer. Playbook §4."
fi

[ -z "$HINTS" ] && exit 0

CTX="## 🧭 vw-guardrails — rules situationnelles (☁️ CLOUD, déclenchées par mots-clés)
${HINTS}

➡️ Référence complète : \`${PB}\` (embarquée dans le plugin)."

export CTX
python3 -c '
import os, json
print(json.dumps({
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": os.environ.get("CTX", "")
  }
}))
'
