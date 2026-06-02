# VW Cloud Playbook — discipline de travail VirtuoseWeb (référence profonde)

> **Rôle** : version cloud-adaptée et condensée des rules `~/.claude` de Simon. En **cloud** (Claude Code on the web) le `~/.claude` global n'est PAS cloné — ce fichier (embarqué dans le plugin `vw-guardrails`) est la **source de référence** des principes de travail. Le hook `rules-router.sh` (UserPromptSubmit) pointe vers les sections pertinentes selon les mots-clés du prompt.
>
> ⚠️ **Adaptation cloud** : pas de Codex CLI, pas de `~/.claude/...`, pas de binaire local `claude`. La délégation passe par les primitives **natives in-session** : Task subagents, agent teams, workflows. Les principes (preuve, plan, qualité, autonomie) sont identiques au local.

---

## §1 — Orchestration & délégation (rules 01/23/41/45/52/53/57 condensées)

**Posture par défaut** : l'orchestrateur **réfléchit et assemble**, il n'exécute pas le mécanique. Décompose AGRESSIVEMENT toute demande ≥ 2 phases en sous-tâches, chacune routée vers le **modèle + effort minimum suffisant**.

**GF-2 (délégation)** : l'orchestrateur écrit **≤ 3 lignes de code applicatif** (`.ts/.tsx/.astro/.css/.sql/...`). Au-delà → déléguer. La méta-config (docs, config) reste directe.

**Primitives natives (choisir selon la SITUATION)** :

| Situation | Primitive |
| --- | --- |
| Focused < 200 LoC (audit, scan, explore, mini-fix, review) | **Task subagent** (`Agent` tool) — retour summary, coût bas |
| Comm inter-agents / debate / cross-layer / hypothèses concurrentes | **Agent teams** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, mailbox, task list partagée) |
| Grande échelle : audit codebase-wide, migration 100+ fichiers, recherche vérifiée-croisée, plan multi-angles | **Workflow** (tool `Workflow` / mot « workflow » dans le prompt) |
| Méta-config / ≤ 3 LoC applicatif | orchestrateur **direct** |

**Effort minimum suffisant (token economy)** : Opus `low|medium|high|xhigh|max` (défaut high) · Sonnet `low|medium|high|max` (pas de xhigh) · Haiku aucun. Ne PAS défaut Opus/high sur du trivial. Le tier suit le **raisonnement résiduel du worker**, pas le domaine : brief verrouillé (décisions déjà prises) = exécution = Sonnet ; brief ouvert (choix archi à faire) = Opus.

**Anti-pattern** : Opus fait tout en mono-bloc. Si la session dérive ainsi → re-décomposer.

---

## §2 — Preuve EMPIRIQUE avant « validé / fini / parfait » (GF-1 ; rules 03/09/13/17/33)

Jamais écrire « validé / fini / parfait / prêt » sans preuve **dans le même turn**. « Ça build / 200 OK » ≠ « ça marche ».

**Piste VISUELLE** (UI, CSS, animations, refactor front, perf) :
1. **Playwright screenshot above-fold** sur la **preview/prod déployée** (pas localhost).
2. **`getComputedStyle()`** sur H1 + CTA → `opacity ≠ 0`, `transform` neutre, `visibility ≠ hidden`.
3. `revealedCount === total` s'il y a un système data-reveal. 0 erreur console.
4. Lighthouse 100/100 ne suffit **JAMAIS** (le score reste vert même si 80 % du contenu est invisible).

**Piste FONCTIONNELLE** (backend, API, DB, job, CLI) :
1. **Appel réel** + **assertion sur la réponse** (pas juste le status 200).
2. **État persisté vérifié** : round-trip write→read (DB/fichier).
3. **Cas limite / erreur** testé (pas de 500 silencieux).

**Full-stack** = les deux + un **flow E2E** prouvé (UI→API→DB→écran) via Playwright.

**Worker output = hypothèse** jusqu'à vérification indépendante par l'orchestrateur. Donner la **preuve** (output, screenshot, SHA), pas l'assertion. Reviewer dédié : agent `visual-proof-reviewer`.

Définition de « validé » : `astro check`/`tsc --noEmit` ✅ + `build` ✅ + preuve visuelle (si UI) ✅ + persistence vérifiée (si backend) ✅.

---

## §3 — Plan & checkpoints (rules 04/16/19)

Toute tâche **≥ 3 étapes** / refactor / debug complexe / décision archi → **plan d'abord** (Explore → Plan → Implement → Commit).

- Checkpoints `[ ]` explicites, cochés `[x]` **avec preuve**.
- 3 niveaux de certitude : 🟢 vérifié / 🟡 probable / 🔴 incertain (ne PAS cocher 🔴).
- **Fix-before-advance** : perfection écran par écran ; ne pas empiler des features sur une base non validée.
- Auto-score post-tâche (4 lignes) : rules identifiées → appliquées → gap → correction.

---

## §4 — Qualité & source avant affirmation (GF-4 ; rules 08/12/14)

- **GF-4** : avant toute affirmation négative (« X n'existe pas / n'est pas documenté / ne marche pas ») → `grep`/`Grep` + source précise **`fichier:ligne`**. Jamais « je n'ai pas trouvé » sans montrer la commande.
- Détecter les contradictions entre CLAUDE.md / docs / handoff avant d'agir.
- Outils spécialisés (rule 02) : `Read`/`Grep`/`Glob` (pas Bash pour ça), Playwright (UI), context7 (docs lib), `gh` (GitHub). Ne pas demander « veux-tu que j'utilise X » — l'utiliser.

---

## §5 — Build & déploiement (rule 40 + branches isolées)

- **`build` (ou `astro check` + build) AVANT tout push** sur un projet SSG/SSR. `astro check` 0 errors ≠ build prod OK → toujours lancer le build complet.
- **1 scope = 1 branche `feat/<scope>`**, jamais `git add -A` global. Commit par phase.
- **Merge sur `main` UNIQUEMENT après preuve GF-1 sur une preview** (Vercel). **Auto-merge = OFF.** `main` sert la prod.
- Push (repo privé, helper gh) : `git -c credential.helper= -c credential.helper='!gh auth git-credential' push origin <branche>`.

---

## §6 — Design system : composition, pas création (rule 28)

Sur un design system / une bibliothèque de composants **figé post-V1** : on **catalogue et compose l'existant**. **0 nouveau token CSS**, 0 atome hors registry, 0 modif des templates/pages live sans tâche dédiée. Toute section/variante nouvelle = composition des primitives existantes. Synchroniser TOUS les touchpoints d'un type (schéma + demo + registry + composant) sinon build cassé.

---

## §7 — Autonomie & action directe (GF-5 ; rule 30)

- Si **N actions productives parallélisables** (sans collision fichiers) → **agir** en parallèle, ne PAS demander « tu veux lequel d'abord ».
- Ne jamais reporter à « plus tard / prochaine session » ce qui est faisable maintenant sans blocker absolu.
- Validation conversationnelle **uniquement** pour : paiement > 1 €, action destructive, install non-demandée, envoi externe, modif sécurité. Tout le reste : agir, monitorer, rapporter.

---

## §8 — Officiel/doc d'abord + invoquer l'arsenal (GF-6 ; rules 54/55)

- Pour configurer/réparer quoi que ce soit : **lire la doc officielle** + utiliser les leviers supportés (settings.json, config.json, frontmatter) AVANT tout sur-mesure. Patch/hack maison = dernier recours, avec preuve que l'officiel ne couvre pas.
- Quand un skill/commande/agent est pertinent → **l'invoquer directement** (tools `Skill`/`SlashCommand`/`Agent`), jamais suggérer à l'humain de le taper.
