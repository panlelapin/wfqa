# Discussions WFQA

`discussions.tar.gz.age` contient un instantané des échanges OpenCode du projet (discussion principale et revue). Le texte des messages utilisateur et des réponses est conservé, sans les appels d’outils ni les données internes du modèle. L’archive contient un JSON par session et un manifeste SHA-256.

Le destinataire est la [clé publique du coffre BlackBG](https://github.com/panlelapin/blackbg/blob/dc199009f6a5b3db40b1d932cc07534b44d6cb32/clefs/paire/publique.txt). Pour lire le manifeste depuis la racine de WFQA (Bash ou Zsh), utiliser la phrase secrète de ce coffre :

```sh
(
  set -eo pipefail
  curl -fsSL https://raw.githubusercontent.com/panlelapin/blackbg/dc199009f6a5b3db40b1d932cc07534b44d6cb32/clefs/paire/paire.tar.gz.age |
    age -d | tar -xzOf - privee.txt |
    age -d -i - clefs/discussions.tar.gz.age | tar -xzOf - manifest.json
)
```

Pour lire une discussion, remplacer `manifest.json` dans la dernière commande par le chemin `sessions/….json` indiqué dans le manifeste.
