# wfqa

Application Flutter pour Android et Linux. **Ajouter** sauvegarde la saisie sur l’appareil avant de fermer la fenêtre. L’application envoie ensuite les entrées vers `Inbox/AAAA/MM/JJ/HHmm` quand WorkFlowy est accessible.

Une ligne contenant exactement `-` sépare deux entrées. `Ctrl+Entrée` valide sur Linux ; **Cancel** ou `Échap` abandonnent la saisie.

Voir le [guide d’utilisation et de compilation](docs/usage.md) et la [spécification](AGENTS.md).

**Android :** [ajouter le dépôt F-Droid « Pan le lapin »](https://panlelapin.github.io/fdroid-repo/fdroid/repo/?fingerprint=363DEB527CD0C41ABBC30359005EE6F2A5A6869716D32CF42CEED66DCC3A7A7A), puis rechercher **wfqa**. Dans le lanceur Android, l’application apparaît sous le nom **WFQA**.

Cette version utilise `com.github.panlelapin.wfqa`. Si tu avais installé l’ancien paquet, laisse-le envoyer ses entrées en attente avant de le désinstaller. Configure la clé API dans la nouvelle installation.
