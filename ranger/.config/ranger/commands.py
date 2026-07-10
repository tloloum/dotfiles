# Commandes personnalisées, chargées automatiquement par ranger.
from __future__ import absolute_import, division, print_function
import os
from ranger.api.commands import Command


class fzf_select(Command):
    """
    :fzf_select

    Descend récursivement dans le dossier courant via fzf, puis :
      - si on choisit un dossier -> on s'y déplace ;
      - si on choisit un fichier -> on place le curseur dessus.
    Mappé sur <C-f> dans rc.conf.
    """
    def execute(self):
        import subprocess
        # -type d,f : on liste dossiers ET fichiers ; -mindepth 1 : pas le "." courant.
        command = "find -L . -mindepth 1 -printf '%y %p\\n' 2>/dev/null | " \
                  "sed 's|^d |📁 |;s|^f |   |' | fzf --ansi | sed 's|^....||'"
        fzf = self.fm.execute_command(command, universal_newlines=True,
                                      stdout=subprocess.PIPE)
        stdout, _ = fzf.communicate()
        if fzf.returncode == 0:                       # 0 = un choix a été validé
            selected = os.path.abspath(stdout.strip())
            if os.path.isdir(selected):
                self.fm.cd(selected)                  # dossier -> on entre dedans
            else:
                self.fm.select_file(selected)         # fichier -> curseur dessus
