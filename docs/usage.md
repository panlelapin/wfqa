# WorkFlowy Quick Add

Ouvre les préférences (roue dentée) et colle la clé API de ton compte WorkFlowy. Tu peux déjà saisir du texte sans clé ni réseau.

Saisis une entrée, ou plusieurs en les séparant par une ligne contenant uniquement `-`. **Ajouter** (`Ctrl+Entrée` sur Linux) enregistre le lot sur l’appareil et ferme la fenêtre. **Cancel** et `Échap` abandonnent le brouillon. Relance l’application pour afficher une nouvelle fenêtre de saisie.

La destination est l’Inbox intégrée, puis l’année, le mois, le jour et la minute de validation : `Inbox/2025/11/25/1437`. Les entrées de la même minute s’ajoutent dans leur ordre de saisie.

Tant que le processus peut s’exécuter, il réessaie après une coupure réseau. Android peut suspendre ou arrêter une application en arrière-plan ; au prochain lancement, elle reprend la file persistante. Si la clé est refusée, corrige-la dans les préférences.

Une entrée n’est retirée qu’après confirmation de WorkFlowy. Si le serveur crée l’item mais que sa réponse se perd, ou si le processus s’arrête entre la confirmation et son inscription sur disque, une reprise peut créer un doublon. Tant que le processus reste actif, une confirmation reçue n’entraîne pas de nouvel envoi en cas d’échec de l’écriture locale.

Sur Linux, **Ajouter** et **Cancel** masquent la fenêtre et laissent l’application active. Pour quitter complètement l’application, utilise la croix de la fenêtre ou `Alt+F4` ; les entrées en attente seront reprises au lancement suivant.

## Développement

Avec Flutter stable, depuis la racine :

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d linux  # sur un hôte Linux
flutter build apk --debug
```

### Distribution Linux AMD64

Depuis un hôte Linux x86-64, exécuter `bash tool/package-linux-amd64.sh`. Ce script compile en mode release AOT et vérifie avec `readelf` que le lanceur, le code applicatif (`libapp.so`), le moteur Flutter et les bibliothèques embarquées sont des ELF 64 bits x86-64. L’archive obtenue est `build/dist/wf-quick-add-linux-amd64.tar.gz`. Extraire l’archive dans un dossier dédié et y lancer `./wf_quick_add` en laissant `lib/` et `data/` à côté de l’exécutable. Aucun SDK Dart ou Flutter n’est nécessaire pour l’utiliser.

Pour compiler sur Linux, installer les outils de compilation Flutter/GTK, `binutils` et les en-têtes de `libsecret` (sur Debian/Ubuntu : `libsecret-1-dev`). Pour exécuter le bundle construit sur Ubuntu 24.04, utiliser un environnement compatible avec GTK 3, `libsecret` et une session graphique fournissant un service Secret Service. Pour Android, utiliser le SDK Android et le JDK compatibles avec le projet Gradle.

## Essai avec un compte de test

1. Couper le réseau. Saisir `A`, puis `B` à la ligne, puis une ligne `-`, puis `C`. Valider.
2. Rétablir le réseau pendant que l’application tourne. Vérifier **deux** enfants sous la minute de saisie : `A B` puis `C`.
3. Refaire l’essai en arrêtant le processus hors ligne après validation. Relancer l’application en ligne et vérifier la reprise.
4. Avec **Cancel**, vérifier que la saisie abandonnée n’apparaît jamais dans WorkFlowy.
