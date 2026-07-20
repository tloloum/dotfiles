# LSP — cours complet

> Rédigé pour Neovim 0.12. L'API a beaucoup changé en 0.11 : la plupart des
> tutos en ligne (et l'ancienne config supprimée) utilisent l'ancienne façon
> de faire. Référence locale : `:h lsp`, `:h vim.lsp.config`, `:h lsp-attach`.

---

## 1. Le problème que LSP résout

Avant LSP, chaque éditeur devait implémenter le support de chaque langage.
Avec M éditeurs et N langages, ça fait **M × N** intégrations à écrire et
maintenir. Vim avait ses plugins Python, Emacs les siens, VSCode les siens —
tous réécrivant la même analyse sémantique.

Microsoft a publié le **Language Server Protocol** en 2016 pour casser ça :
on définit un protocole standard entre l'éditeur et un programme externe qui
connaît le langage. On passe à **M + N** : chaque éditeur implémente le
protocole une fois, chaque langage écrit un serveur une fois.

```
                    AVANT                          APRÈS

   vim ──┬── plugin-python            vim ────┐
         ├── plugin-rust              emacs ──┼── protocole LSP ──┬── pyright
         └── plugin-go                vscode ─┘                   ├── rust-analyzer
   emacs ┬── plugin-python                                        └── gopls
         ├── ...
```

**Conséquence importante** : un serveur LSP est un **programme séparé**, pas
un plugin Neovim. `rust-analyzer`, `pyright`, `lua-language-server` sont des
binaires que tu peux lancer à la main dans un terminal. Neovim ne fait que
dialoguer avec eux.

---

## 2. Architecture : client, serveur, JSON-RPC

- Le **serveur** est un processus lancé par Neovim (typiquement via `stdio`).
- Le **client** est Neovim.
- Ils s'échangent des messages **JSON-RPC 2.0**, avec un en-tête façon HTTP :

```
Content-Length: 128\r\n
\r\n
{"jsonrpc":"2.0","id":1,"method":"textDocument/definition","params":{...}}
```

Trois types de messages :

| Type | Sens | Réponse attendue ? | Exemple |
|---|---|---|---|
| **Request** | client → serveur (ou l'inverse) | oui | `textDocument/definition` |
| **Response** | réponse à une request | — | le résultat ou une erreur |
| **Notification** | soit → soit | non | `textDocument/didChange` |

Un serveur par **projet** et par **langage** : ouvrir deux projets Rust lance
deux `rust-analyzer`. C'est pour ça que la détection de la racine du projet
(`root_markers`) compte autant — elle décide du regroupement des buffers.

### Voir le trafic en vrai

```vim
:lua vim.lsp.set_log_level('debug')
:lua vim.cmd('edit ' .. vim.lsp.get_log_path())
```

Fais-le une fois. Voir les JSON passer démystifie complètement le truc.

---

## 3. Cycle de vie d'une session

```
1. Neovim lance le binaire        →  cmd = { 'rust-analyzer' }
2. → initialize (request)            client: "voilà ce que je sais faire"
3. ← InitializeResult                serveur: "voilà ce que je sais faire"
4. → initialized (notification)      poignée de main terminée
5. → textDocument/didOpen            "voici le contenu du fichier"
6. ↔ requests/notifications          la session utile
     → textDocument/didChange        à chaque frappe
     ← textDocument/publishDiagnostics   le serveur pousse les erreurs
     → textDocument/hover             tu appuies sur K
     → textDocument/definition        tu appuies sur gd
7. → shutdown puis exit              à la fermeture
```

Deux choses non évidentes :

- **Le serveur a sa propre copie du fichier.** Neovim lui envoie chaque
  modification via `didChange`. Le serveur ne relit jamais le disque pour le
  buffer courant. C'est pourquoi tu as des diagnostics sur du code non
  sauvegardé — et pourquoi un serveur désynchronisé donne des résultats
  absurdes (`:LspRestart`, ou plutôt `:checkhealth vim.lsp`).
- **Les diagnostics sont poussés, pas demandés.** Tu ne demandes jamais « quelles
  sont les erreurs ». Le serveur les envoie quand il veut, en asynchrone. D'où
  le petit délai avant qu'elles apparaissent.

---

## 4. Les capabilities : la négociation

À l'étape `initialize`, les deux camps annoncent ce qu'ils supportent.

- **client capabilities** : « je sais afficher du markdown dans le hover, je
  supporte les snippets dans la complétion, les tokens sémantiques multi-lignes… »
- **server capabilities** : « je fournis hover, definition, rename, mais pas
  d'inlay hints ».

Ça a une conséquence pratique directe : **tous les serveurs ne font pas tout**.
D'où le pattern recommandé de tester avant de créer un keymap :

```lua
if client:supports_method('textDocument/inlayHint') then
  vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
end
```

C'est aussi la raison d'être historique de `cmp-nvim-lsp` : il augmentait les
capabilities annoncées par Neovim pour dire « je supporte la complétion riche
de nvim-cmp ». Avec la complétion native de 0.11+, ce n'est plus nécessaire.

---

## 5. Ce que LSP fait — et ne fait pas

**LSP fournit** (les principales méthodes) :

| Méthode | Usage |
|---|---|
| `textDocument/hover` | doc au survol (`K`) |
| `textDocument/definition` | aller à la définition |
| `textDocument/references` | trouver les usages |
| `textDocument/implementation` | implémentations d'une interface |
| `textDocument/rename` | renommage sémantique (tous les fichiers) |
| `textDocument/codeAction` | corrections rapides, refactos |
| `textDocument/completion` | complétion |
| `textDocument/signatureHelp` | signature de la fonction en cours d'appel |
| `textDocument/formatting` | formatage |
| `textDocument/publishDiagnostics` | erreurs et warnings |
| `textDocument/inlayHint` | types inférés affichés en gris |
| `textDocument/documentSymbol` | plan du fichier |
| `textDocument/semanticTokens` | coloration sémantique fine |

**LSP ne fait pas** — et c'est important pour ne pas empiler les outils :

- **La coloration syntaxique de base** → c'est **Treesitter**. LSP ne fait que
  l'ajouter par-dessus via les semantic tokens (distinguer une variable d'un
  paramètre, par ex.).
- **L'indentation, les text objects, le folding** → Treesitter.
- **Le linting non-LSP** (eslint standalone, shellcheck…) → il faut soit un
  serveur qui l'englobe, soit un plugin type `nvim-lint`.
- **Le formatage par un outil externe** (prettier, stylua, black) → beaucoup de
  serveurs n'exposent pas ces formateurs. D'où `conform.nvim` (que tu as gardé).
- **Le git, les snippets, la recherche de fichiers** → sans rapport.

> Retiens la ligne de partage : **Treesitter comprend la structure d'un fichier,
> LSP comprend le sens d'un projet.** Treesitter est synchrone et local ;
> LSP est asynchrone et voit tout le projet, ses imports et ses dépendances.

---

## 6. L'API Neovim moderne (0.11+)

C'est ici que tout ce que tu liras en ligne risque d'être périmé.

### Les deux fonctions à connaître

```lua
vim.lsp.config('nom', { ... })  -- DÉFINIR ou ÉTENDRE une configuration
vim.lsp.enable('nom')           -- ACTIVER : lance le serveur quand ça matche
```

`vim.lsp.config` ne lance rien. Elle remplit une table de configuration.
`vim.lsp.enable` pose l'autocommande qui démarrera le serveur au bon moment.

### Les champs d'une configuration

```lua
vim.lsp.config('lua_ls', {
  cmd = { 'lua-language-server' },       -- comment lancer le binaire
  filetypes = { 'lua' },                 -- quand l'activer
  root_markers = { '.luarc.json', '.git' }, -- comment trouver la racine du projet
  settings = {                           -- config spécifique au serveur
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
    },
  },
})

vim.lsp.enable('lua_ls')
```

- `cmd` — le binaire doit être dans ton `$PATH`. S'il n'y est pas, rien ne se
  lance et c'est l'erreur numéro un des débutants.
- `filetypes` — Neovim n'active le serveur que pour ces types de fichiers.
- `root_markers` — remonte l'arborescence jusqu'à trouver un de ces fichiers.
  Cette racine devient le workspace. Priorité par imbrication :
  `{ { '.luarc.json', '.luarc.jsonc' }, '.git' }` cherche d'abord les deux
  premiers (même priorité), et ne retombe sur `.git` que s'ils sont absents.
- `settings` — **pas standardisé par LSP**. Chaque serveur a son propre schéma,
  à lire dans sa doc à lui. C'est le bloc `Lua = {...}` / `["rust-analyzer"] = {...}`
  que tu recopies sans comprendre : il vient de la doc du serveur, pas de Neovim.

### D'où viennent les configurations : les fichiers `lsp/*.lua`

Neovim charge automatiquement tout fichier `lsp/<nom>.lua` trouvé sur le
`runtimepath`. Le fichier retourne simplement une table :

```lua
-- ~/.config/nvim/lsp/lua_ls.lua
return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.git' },
}
```

Puis dans `init.lua` : `vim.lsp.enable('lua_ls')`.

**C'est tout ce que `nvim-lspconfig` est devenu aujourd'hui** : un dépôt de
fichiers `lsp/*.lua` avec les `cmd`/`filetypes`/`root_markers` corrects pour
~300 serveurs. Ce n'est plus un framework, juste des données. Tu peux
parfaitement t'en passer et écrire tes 4 ou 5 fichiers à la main — c'est
d'ailleurs très formateur.

### L'ordre de fusion (important)

Quand plusieurs sources configurent le même serveur, elles fusionnent dans cet
ordre, **la dernière gagnant** :

1. `vim.lsp.config('*', {...})` — les réglages communs à tous les serveurs
2. Les fichiers `lsp/<nom>.lua` du `runtimepath` (donc ceux de nvim-lspconfig)
3. `vim.lsp.config('<nom>', {...})` dans ton `init.lua`
4. Le reste

Ça te donne le pattern propre : laisse nvim-lspconfig fournir les `cmd` et
`root_markers`, et n'écris toi-même que le `settings` qui t'intéresse.

---

## 7. `LspAttach` : le bon endroit pour tes réglages

Ne mets **jamais** tes keymaps LSP au niveau global : ils doivent exister
uniquement dans les buffers où un serveur est effectivement attaché.

```lua
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('my.lsp', {}),
  callback = function(ev)
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
    local opts = { buffer = ev.buf }

    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)

    -- toujours tester avant d'utiliser une feature optionnelle
    if client:supports_method('textDocument/inlayHint') then
      vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
    end
  end,
})
```

`ev.buf` est le buffer, `ev.data.client_id` le serveur qui vient de s'attacher.
Note que `LspAttach` se déclenche **une fois par serveur** : deux serveurs sur
le même buffer (par ex. `ruff` + `pyright` en Python) le déclenchent deux fois.

---

## 8. Les keymaps par défaut de Neovim 0.11+

Neovim définit déjà ces raccourcis. **Tu n'as pas besoin de les recréer** —
c'est la moitié de l'ancien `lspconfig.lua` qui devient inutile :

| Touche | Action |
|---|---|
| `K` | `vim.lsp.buf.hover()` |
| `grn` | `vim.lsp.buf.rename()` |
| `gra` | `vim.lsp.buf.code_action()` (normal + visuel) |
| `grr` | `vim.lsp.buf.references()` |
| `gri` | `vim.lsp.buf.implementation()` |
| `grt` | `vim.lsp.buf.type_definition()` |
| `gO` | `vim.lsp.buf.document_symbol()` |
| `CTRL-S` (insertion) | `vim.lsp.buf.signature_help()` |

Le préfixe `gr` est volontaire : il libère l'espace pour tes propres mappings
et reste cohérent. `gd` (definition) n'est pas dans la liste car `CTRL-]`
le fait déjà via `tagfunc`, mais beaucoup de gens le remappent quand même.

---

## 9. Les diagnostics : un système à part

`vim.diagnostic` est **indépendant de LSP**. LSP n'est qu'une source parmi
d'autres (nvim-lint, Treesitter, un plugin maison…). D'où le fait que la config
se fasse via `vim.diagnostic.config()` et pas via le LSP :

```lua
vim.diagnostic.config({
  virtual_text = true,      -- le message à droite de la ligne
  virtual_lines = false,    -- le message sur des lignes dédiées (0.11+, plus lisible)
  underline = true,
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN]  = '',
      [vim.diagnostic.severity.INFO]  = '',
      [vim.diagnostic.severity.HINT]  = '󰌵',
    },
  },
})
```

En 0.12, `virtual_text` et `virtual_lines` sont **désactivés par défaut** :
si tu ne vois aucun message inline, c'est normal, il faut l'activer.

Navigation : `]d` / `[d` (déjà par défaut), `vim.diagnostic.open_float()`,
`vim.diagnostic.setqflist()`.

Une astuce qui vaut le détour — les messages longs sur lignes dédiées, mais
seulement pour la ligne du curseur :

```lua
vim.diagnostic.config({
  virtual_lines = { current_line = true },
  virtual_text = false,
})
```

---

## 10. La complétion

Trois options, par ordre croissant de complexité :

**a) Native (0.11+)** — zéro plugin :

```lua
-- dans le callback LspAttach
if client:supports_method('textDocument/completion') then
  vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
end
```

Sélection avec `CTRL-Y` (convention de `:h ins-completion`, pas `<CR>`).
Sans `autotrigger`, c'est `CTRL-X CTRL-O` à la demande. Simple, sans fioritures,
mais suffisant pour beaucoup de monde et sans aucune dépendance.

**b) `blink.cmp`** — le choix moderne. Rapide, config minimale, sources
intégrées. C'est ce vers quoi la communauté a basculé.

**c) `nvim-cmp`** — ce que tu avais. Très puissant, très configurable, mais
verbeux : il te fallait 8 plugins de sources + LuaSnip + lspkind pour
l'assembler. C'est le gros du fichier qu'on a supprimé.

> Conseil : commence par (a). Tu verras concrètement ce qui te manque, et tu
> choisiras (b) en connaissance de cause plutôt que par copier-coller.

---

## 11. Le formatage

Deux voies, et il faut choisir consciemment :

- **Via LSP** : `vim.lsp.buf.format()`. Marche si le serveur expose
  `textDocument/formatting`. `gopls` et `rust_analyzer` le font très bien.
  Beaucoup d'autres non, ou mal.
- **Via un outil externe** : `conform.nvim` lance directement `prettier`,
  `stylua`, `black`, `ruff format`. Plus prévisible, et c'est le même binaire
  que ta CI utilisera.

C'est exactement pourquoi tu as gardé `conform.lua` : son `lsp_format = "fallback"`
signifie « utilise l'outil externe si j'en ai un pour ce filetype, sinon
demande au LSP ». Bon compromis, rien à changer.

---

## 12. Mason : à quoi ça sert vraiment

Mason **n'a rien à voir avec LSP**. C'est un gestionnaire de paquets qui
télécharge des binaires (serveurs LSP, linters, formateurs, debuggers) dans
`~/.local/share/nvim/mason/bin` et ajoute ce dossier à ton `$PATH` Neovim.

C'est tout. Son intérêt : ne pas dépendre de `apt` / `brew` / `npm -g`.

Ses inconvénients, à peser :
- une couche d'indirection de plus quand un truc ne marche pas ;
- des binaires dupliqués si tu as déjà `rust-analyzer` via `rustup` ;
- `mason-lspconfig` ajoutait de la magie d'auto-activation qui masque
  complètement le mécanisme `vim.lsp.enable` que tu essaies d'apprendre.

**Pour apprendre, installe tes serveurs à la main** (`rustup component add
rust-analyzer`, `pacman -S lua-language-server`, `pip install python-lsp-server`).
Tu verras `cmd` échouer, tu comprendras le `$PATH`, et tu sauras ce que Mason
te fera gagner quand tu l'ajouteras — ou pas.

---

## 13. Débogage

| Commande | Usage |
|---|---|
| `:checkhealth vim.lsp` | **le premier réflexe** : serveurs attachés, config, racine détectée |
| `:LspInfo` | vue résumée (fournie par nvim-lspconfig) |
| `:LspLog` / `vim.lsp.get_log_path()` | le journal brut des échanges |
| `:lua =vim.lsp.get_clients()` | les clients actifs, en Lua |
| `:lua =vim.lsp.config.lua_ls` | la config **fusionnée** effective |
| `:lua vim.lsp.set_log_level('debug')` | voir tous les messages JSON-RPC |

**Checklist quand un serveur ne démarre pas**, dans l'ordre :

1. Le binaire existe-t-il ? `:!which lua-language-server` — c'est la cause n°1.
2. As-tu appelé `vim.lsp.enable('nom')` ?
3. Le `filetype` du buffer correspond-il ? `:set filetype?`
4. Une racine a-t-elle été trouvée ? Un `root_markers` qui ne matche jamais
   empêche le démarrage. Ouvre le fichier depuis un vrai dépôt git.
5. `:checkhealth vim.lsp` pour le reste.

---

## 14. Plan de reconstruction suggéré

Une étape à la fois, en testant à chaque fois :

1. **Un seul serveur, à la main.** Installe `lua-language-server`, écris
   `lsp/lua_ls.lua`, ajoute `vim.lsp.enable('lua_ls')`. Vérifie que `K` marche
   sur une fonction `vim.*`. Tu as un LSP fonctionnel en ~10 lignes, sans
   aucun plugin.
2. **`LspAttach`** avec deux ou trois keymaps à toi (`gd` par exemple) — et
   constate que `grn`, `gra`, `grr` marchent déjà sans rien écrire.
3. **`vim.diagnostic.config()`** — active `virtual_text`, choisis tes signes.
4. **La complétion native**, une ligne dans `LspAttach`. Vis avec quelques
   jours avant de décider si tu veux `blink.cmp`.
5. **Ajoute tes langages** un par un (rust, python…), en lisant la doc de
   chaque serveur pour le bloc `settings`.
6. **Alors seulement** envisage `nvim-lspconfig` (pour ne plus écrire les
   `cmd`/`root_markers`) et `mason` (pour ne plus installer à la main). Tu
   sauras exactement ce qu'ils t'apportent.

---

## Récapitulatif en une page

- Un serveur LSP est **un programme externe**, pas un plugin.
- Ils communiquent en **JSON-RPC** sur stdio.
- Le serveur maintient **sa propre copie** du buffer ; les diagnostics sont
  **poussés** par le serveur, jamais demandés.
- `vim.lsp.config()` **définit**, `vim.lsp.enable()` **active**.
- Les fichiers `lsp/<nom>.lua` du runtimepath sont chargés automatiquement ;
  `nvim-lspconfig` n'est plus qu'une collection de ces fichiers.
- Ordre de fusion : `'*'` → `lsp/*.lua` → ton `vim.lsp.config('nom', …)`.
- `LspAttach` est le seul bon endroit pour les keymaps et features par buffer ;
  teste `client:supports_method()` avant.
- Neovim 0.11+ fournit déjà `K`, `grn`, `gra`, `grr`, `gri`, `grt`, `gO`.
- `vim.diagnostic` est **indépendant** de LSP.
- **Treesitter = structure du fichier. LSP = sens du projet.**
- Mason ne fait qu'**installer des binaires** et étendre le `$PATH`.
