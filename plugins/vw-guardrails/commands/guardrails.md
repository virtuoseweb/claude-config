---
description: Affiche et recharge les garde-fous VirtuoseWeb (GF-1 à GF-6) + la checklist de preuve empirique.
---

Recharge et applique les garde-fous VirtuoseWeb pour la suite de la session. Énonce-les brièvement puis confirme que tu les respectes :

- **GF-1 — preuve EMPIRIQUE** avant « validé/fini/parfait ». Visuel : Playwright screenshot above-fold + `getComputedStyle` H1/CTA (opacity≠0, transform neutre) sur la preview/prod déployée. Backend/API/DB/full-stack : appel réel + assertion réponse (pas juste 200) + write→read DB vérifié + cas limite + flow E2E (Playwright/computer-use). « ça build / 200 OK » ≠ preuve. Reviewer : agent `visual-proof-reviewer`.
- **GF-2** — orchestrateur ≤ 3 lignes de code applicatif ; au-delà → worker/sous-agent.
- **GF-3** — capitaliser après chaque correction (même tour).
- **GF-4** — triangulation (grep + source) avant toute affirmation négative.
- **GF-5** — action directe si parallélisable ; validation seulement pour paiement/destructif/install/externe/sécurité.
- **GF-6** — officiel/doc d'abord + invoquer l'arsenal (pas suggérer à l'humain de taper une commande).

Puis lis le `CLAUDE.md` du repo courant (et son `docs/` de reprise s'il existe) avant d'agir.
