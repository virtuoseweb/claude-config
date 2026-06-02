# claude-config — config Claude Code partagée VirtuoseWeb

Marketplace de plugin privé. **Source unique de vérité** pour les garde-fous + conventions Claude Code,
**héritée par chaque repo** et **fonctionnelle en cloud** (Claude Code on the web) comme en local.

## Pourquoi un plugin (et pas un symlink / une copie)

En cloud, chaque session = **clone frais du repo** dans une VM Anthropic. Le `~/.claude` global de la
machine n'y est **pas** (doc : `code.claude.com/docs/en/claude-code-on-the-web` → *« only hooks committed
to the repo run »*). Conséquences :

- ❌ **Symlink** vers `~/.claude` = lien mort en cloud (`~/.claude` absent).
- ❌ **Copier la config** dans chaque repo = duplication + dérive.
- ✅ **Plugin déclaré dans `.claude/settings.json`** = *installé au démarrage de session depuis le marketplace*
  (table officielle « What's available in cloud sessions »). Versionné, zéro dérive, un seul point de mise à jour.

## Contenu : plugin `vw-guardrails` (v0.3.0)

Le plugin mire l'**architecture hybride locale** (fondamentales always-on / situationnelles lazy) côté cloud :

| Composant | Rôle |
|---|---|
| `hooks/session-guardrails.sh` (**SessionStart**) | Recharge GF-1 à GF-6 + discipline condensée au boot, détecte la surface (☁️ cloud / 💻 local). En cloud, annonce le playbook + les agents dispo. |
| `hooks/rules-router.sh` (**UserPromptSubmit**) | **Routage situationnel des rules en CLOUD** : mot-clé du prompt → hint actionnable + pointeur playbook (équivalent cloud du `rules-enforcer` global). **Muet en local** (le global gère). |
| `reference/vw-cloud-playbook.md` | **Rules dev/qualité/orchestration condensées + cloud-adaptées** (0 chemin local, 0 Codex). Référence profonde lue à la demande. |
| `agents/visual-proof-reviewer.md` | Reviewer **preuve empirique** (visuelle ET fonctionnelle backend/API/DB). |
| `agents/code-reviewer.md` | Reviewer **qualité/sécurité** (cloud-natif ; feature-dev/pr-review absents en cloud). |
| `agents/code-explorer.md` | **Cartographie d'archi** en lecture seule avant feature/refactor. |
| `commands/guardrails.md` | `/vw-guardrails:guardrails` — recharge les garde-fous à la demande. |

Lean par design (cloud = pas de bloat). Le `~/.claude` global local reste l'arsenal complet (56 rules, ecc, ~124 MCP) ;
ce plugin = le **sous-ensemble portable** qui doit suivre partout. Répartition : **rules + hooks + agents → plugin** (hérités au boot) ; **MCP → `.mcp.json` du repo** (les `mcpServers` de plugin ne sont pas auto-activés — cf README ecc).

## MCP en cloud : via `.mcp.json` du repo (pas le plugin)

En cloud, les serveurs MCP perso (`claude mcp add`, `~/.claude`) ne suivent pas. Pour qu'un repo ait du MCP en cloud,
le déclarer dans **`<repo>/.mcp.json`** (committé). Template recommandé pour un repo web :

```json
{
  "mcpServers": {
    "playwright": { "type": "stdio", "command": "npx", "args": ["-y", "@playwright/mcp@latest"], "env": {} },
    "context7":   { "type": "stdio", "command": "npx", "args": ["-y", "@upstash/context7-mcp@latest"], "env": {} }
  }
}
```

- **playwright** = preuve GF-1 visuelle (screenshot + getComputedStyle) en cloud.
- **context7** = docs lib à jour (Astro/React/Tailwind…). Ajouter d'autres serveurs (Neon, etc.) selon les besoins du repo ; ceux qui exigent une auth/secret nécessitent une variable d'env côté session.

## Installation LOCALE (une fois, sur la machine)

```bash
claude plugin marketplace add virtuoseweb/claude-config
claude plugin install vw-guardrails@virtuoseweb     # ou enable global dans ~/.claude/settings.json
```

## Faire HÉRITER un repo (local + cloud)

Ajouter à `<repo>/.claude/settings.json` :

```json
{
  "extraKnownMarketplaces": {
    "virtuoseweb": { "source": { "source": "github", "repo": "virtuoseweb/claude-config" } }
  },
  "enabledPlugins": { "vw-guardrails@virtuoseweb": true }
}
```

Committer ce `.claude/settings.json` → au prochain démarrage de session **cloud** sur ce repo, Claude Code
installe automatiquement le plugin depuis le marketplace (réseau GitHub requis, dans l'allowlist par défaut).
En **local**, le plugin est déjà installé (étape ci-dessus) ; la déclaration repo garantit la cohérence.

> Garder dans le repo CLAUDE.md les garde-fous **inline** en filet de sécurité (si le réseau cloud bloque
> l'install du plugin, le CLAUDE.md reste lu). Le plugin apporte le hook + l'agent + la commande en plus.

## Mise à jour (sync)

1. Éditer le plugin dans ce repo → **bump `version`** dans `plugins/vw-guardrails/.claude-plugin/plugin.json`.
2. `git commit && git push`.
3. **Cloud** : récupéré au prochain démarrage de session (réinstall depuis le marketplace).
4. **Local** : `claude plugin update vw-guardrails@virtuoseweb` (ou `claude plugin marketplace update virtuoseweb`).

## Validation

```bash
claude plugin validate .                            # marketplace + plugin (version obligatoire ; pas de champ hooks/agents dans plugin.json)
bash plugins/vw-guardrails/hooks/session-guardrails.sh | python3 -m json.tool   # JSON SessionStart valide
# rules-router : muet en local, injecte en cloud (simulation)
printf '{"prompt":"refactor hero + deploy vercel"}' | CLAUDE_CODE_REMOTE_SESSION_ID=x CLAUDE_PLUGIN_ROOT=$PWD/plugins/vw-guardrails bash plugins/vw-guardrails/hooks/rules-router.sh | python3 -m json.tool
```
