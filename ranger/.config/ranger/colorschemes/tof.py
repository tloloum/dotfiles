# Colorscheme perso : rend la colonne ACTIVE bien distincte du parent.
#
# On hérite du colorscheme "default" de ranger et on ne réécrit que la
# ligne sous le curseur. La clé est `context.main_column` : elle vaut True
# uniquement dans la colonne centrale (celle où tu navigues). On lui donne
# un fond plein bien visible ; la colonne parent garde un simple "reverse"
# discret. Impossible de confondre les deux.
from __future__ import absolute_import, division, print_function

from ranger.colorschemes.default import Default
from ranger.gui.color import (
    black, blue, cyan, white, default, reverse, bold, normal, default_colors,
)


class Tof(Default):
    # Couleur de la barre de progression (téléchargements/copies).
    progress_bar_color = cyan

    def use(self, context):
        # On part de tout ce que fait le thème par défaut (couleurs des
        # dossiers, exécutables, liens, etc.), puis on surcharge.
        fg, bg, attr = Default.use(self, context)

        if context.in_browser and context.selected:
            if context.main_column:
                # Colonne active : fond bleu plein, texte noir, gras.
                # -> saute aux yeux, on sait TOUJOURS où on est.
                fg, bg, attr = black, blue, bold
            else:
                # Colonne parent : highlight discret (inversion simple).
                attr = reverse

        # Rend les séparateurs de colonnes un peu plus lisibles.
        if context.border:
            fg = blue

        return fg, bg, attr
