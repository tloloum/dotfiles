// user.js — préférences Firefox versionnées.
// Firefox lit ce fichier à CHAQUE démarrage et l'applique à prefs.js.
// Déposé dans le profil par install.sh (deploy_firefox).

// ── INDISPENSABLE : autorise le chargement de userChrome.css / userContent.css.
// Sans ça, tout le thème DownToneUI est ignoré.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// ── Rendu attendu par le thème ───────────────────────────────────────────────
// Densité compacte (le thème est pensé pour l'UI compacte).
user_pref("browser.compactmode.show", true);
user_pref("browser.uidensity", 1);          // 0=normal 1=compact 2=touch
                                             // (corrige l'ancienne clé malformée
                                             //  "browser.uidensity = 1")
// Thème sombre pour la barre d'outils et le contenu.
user_pref("browser.theme.toolbar-theme", 0); // 0=dark 1=light 2=system
user_pref("browser.theme.content-theme", 0);

// Icônes SVG thémables via context-fill (utile aux userChrome avancés).
user_pref("svg.context-properties.content.enabled", true);

// ── Sidebery : on masque la sidebar native de Firefox (Sidebery la remplace).
user_pref("sidebar.visibility", "hide-sidebar");

// ── Confort ──────────────────────────────────────────────────────────────────
// Ne pas afficher l'avertissement about:config.
user_pref("browser.aboutConfig.showWarning", false);
