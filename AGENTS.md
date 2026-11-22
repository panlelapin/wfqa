# Consignes pour l’application de saisie rapide WorkFlowy

Développe une application Flutter de saisie rapide pour Android et Linux, avec une seule base de code. Utilise la même logique de saisie, de stockage et d’envoi sur les deux plateformes. Si une opération dépend du système, détecte la plateforme à l’exécution dans l’application.

Livre la version Linux en code machine natif **AMD64 (x86-64)** : compile le Dart en AOT avec `flutter build linux --release --target-platform=linux-x64`. Distribue le bundle Linux complet (exécutable ELF, bibliothèques et données), utilisable sans SDK Flutter ni Dart sur la machine cible.

## Saisie et validation

- À l’ouverture, affiche un champ multiligne entièrement vide, sans texte indicatif. Sur Android, affiche immédiatement le clavier.
- Sur Android et Linux, la touche `Entrée` insère un retour à la ligne sans valider la saisie. Le bouton **Ajouter** valide toutes les entrées du champ et les enregistre dans la file locale. Sur Linux, `Ctrl+Entrée` déclenche la même action que le bouton.
- Le bouton **Cancel** et la touche `Échap` ferment la fenêtre sans enregistrer la saisie en cours.
- Seule une ligne contenant exactement `-` sépare deux entrées. Le séparateur ne fait pas partie du texte envoyé. Un tiret dans une phrase reste du texte.
- Conserve les retours à la ligne ordinaires au sein de la même entrée. Ignore les lignes vides ou composées uniquement d’espaces. Un séparateur en début ou en fin de saisie, ou plusieurs séparateurs consécutifs, ne créent aucune entrée vide.
- À la validation, ajoute chaque entrée non vide à une file d’attente persistante avec son texte complet et son horodatage local. Utilise les bibliothèques standard de Dart pour ce stockage, sans dépendance externe.
- Après **Ajouter**, ferme la fenêtre dès que toutes les entrées de la saisie ont été enregistrées dans la file locale, sans attendre de réponse de WorkFlowy. Si l’écriture locale échoue, laisse la fenêtre ouverte et conserve le texte pour permettre une nouvelle tentative.

## Classement fixe dans WorkFlowy

Utilise le chemin `Inbox/AAAA/MM/JJ/HHmm` à partir de la racine de WorkFlowy. Calcule-le d’après la date et l’heure **de saisie**, même si l’envoi a lieu un autre jour. Utilise le format 24 heures, sans séparateur entre les heures et les minutes (`0905`, `1437`).

Réutilise les nœuds du chemin qui existent déjà et crée ceux qui manquent. Sous le nœud `HHmm`, crée un enfant par entrée, dans l’ordre de saisie. Envoie le texte complet de chaque entrée dans le titre, avec ses retours à la ligne simples. Laisse WorkFlowy les convertir en espaces. Le chemin et le format des noms sont fixes.

Exemple de saisie le 25 novembre 2025 à 14 h 37 :

```text
Appeler Léa
Lui parler du devis
-
Acheter du pain
```

Résultat : le nœud `1437` contient exactement deux enfants. Les deux lignes de la première entrée forment un seul titre dans WorkFlowy.

```text
Inbox
└── 2025
    └── 11
        └── 25
            └── 1437
                ├── Appeler Léa Lui parler du devis
                └── Acheter du pain
```

## Envoi vers WorkFlowy

- Les préférences ont deux sections. **Envois en attente** affiche le nombre d’entrées persistées dont l’envoi reste à confirmer, y compris après redémarrage.
- Dans la première section, **Clé API WorkFlowy**, **Check** teste la clé masquée avec une requête de lecture authentifiée. Une réponse valide affiche une croix verte près du champ et active **Save**, placé à côté de **Check**. Toute modification annule cette validation. Seul **Save** écrit la clé vérifiée dans le stockage sécurisé de l’appareil. Pour les requêtes, utilise l’en-tête `Authorization: Bearer <clé API>`. Une clé absente ou refusée empêche l’envoi, mais pas l’enregistrement local.
- Utilise la cible intégrée `inbox` comme point de départ du classement. Pour conserver l’ordre de saisie sous `HHmm`, crée les items dans cet ordre avec `position: "bottom"`. Voir la [référence officielle de l’API](https://workflowy.com/api-reference/) ; le code du client en ligne de commande `wf` peut aussi servir de référence.
- Au lancement, reprends les entrées encore en attente. Après chaque validation, déclenche leur envoi en arrière-plan via l’API WorkFlowy, sans bloquer la saisie. Tant que l’application est en cours d’exécution et que la file contient des entrées, vérifie la connectivité et reprends automatiquement l’envoi dès que WorkFlowy redevient accessible, sans attendre une nouvelle saisie. Si l’application est arrêtée entre-temps, conserve les entrées pour le prochain lancement.
- Retire une entrée de la file uniquement lorsque WorkFlowy a confirmé la création de l’item correspondant. Si seules certaines entrées ont été envoyées, conserve les autres. Si le service est inaccessible, réessaie tant que l’application est ouverte.
- La file locale sert uniquement à l’envoi de l’application vers WorkFlowy. N’implémente pas de synchronisation bidirectionnelle.
