# Configuration Firefox (thème DownToneUI + Sidebery)

Firefox sous Linux Mint range son profil dans
`~/.config/mozilla/firefox/<aléatoire>.default-release` (pas le `~/.mozilla`
standard). Le nom du profil étant aléatoire, ce dossier **n'est pas géré par
stow** : `install.sh` le déploie via la fonction `deploy_firefox`.

## Contenu

| Fichier          | Destination                                   | Rôle |
|------------------|-----------------------------------------------|------|
| `chrome/`        | `<profil>/chrome/` (lien symbolique)          | userChrome.css / userContent.css + thème DownToneUI |
| `user.js`        | `<profil>/user.js` (lien symbolique)          | prefs `about:config` (dont `toolkit.legacyUserProfileCustomizations.stylesheets`) |
| `policies.json`  | `/etc/firefox/policies/policies.json` (sudo)  | auto-installe l'extension **Sidebery** depuis AMO |
| `sidebery-backup.json` | *(import manuel dans Sidebery)*         | réglages Sidebery (arbre d'onglets, panneaux…) |

## Déploiement automatique

`./install.sh` (ou la fonction seule) :

1. détecte le profil `default-release` via `profiles.ini` ;
2. lie `chrome/` et `user.js` dans le profil ;
3. installe `policies.json` (Sidebery s'installera au 1er lancement de Firefox).

> Firefox doit avoir été lancé **au moins une fois** pour que le profil existe.
> Sinon : lance Firefox, ferme-le, puis relance `./install.sh`.

## Étape manuelle restante : réglages Sidebery

Les réglages de Sidebery vivent en IndexedDB (non versionnables comme des
fichiers). La méthode fiable :

- **Exporter** (machine actuelle) : Sidebery → Réglages → *Help / Aide* →
  *Export settings to file* → enregistrer dans ce dossier sous
  `sidebery-backup.json`, puis committer.
- **Importer** (machine vierge) : après install de Sidebery → Réglages →
  *Help / Aide* → *Import settings from file* → choisir `sidebery-backup.json`.

## Re-synchroniser le dépôt depuis le profil live

Après avoir modifié le thème dans Firefox (si `chrome/` a été copié plutôt que
lié) :

```sh
cp -a ~/.config/mozilla/firefox/*.default-release/chrome/. ~/dotfiles/chrome/chrome/
```
