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

## Contenu : plugin `vw-guardrails`

| Composant | Rôle |
|---|---|
| `hooks/hooks.json` + `hooks/session-guardrails.sh` | Hook **SessionStart** : recharge GF-1 à GF-6 au boot, détecte la surface (cloud vs local). Portable bash+python3. |
| `agents/visual-proof-reviewer.md` | Reviewer adversarial **preuve empirique** (visuelle ET fonctionnelle backend/API/DB). |
| `commands/guardrails.md` | `/vw-guardrails:guardrails` — réaffiche/recharge les garde-fous à la demande. |

Lean par design (cloud = pas de bloat). Le `~/.claude` global local reste l'arsenal complet (56 rules, ecc, MCP) ;
ce plugin = le **sous-ensemble portable** qui doit suivre partout.

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
claude plugin validate ./plugins/vw-guardrails     # schéma OK (version obligatoire ; pas de champ hooks/agents dans plugin.json)
bash plugins/vw-guardrails/hooks/session-guardrails.sh | python3 -m json.tool   # JSON SessionStart valide
```
