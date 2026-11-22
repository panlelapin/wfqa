# Plan de développement — WorkFlowy Quick Add

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Objectif :** saisir du texte sur Android ou Linux, fermer la fenêtre dès que la saisie est sauvegardée et envoyer les entrées vers WorkFlowy sans intervention dès que possible.

**Architecture :** une interface Flutter appelle une file persistante commune en Dart. Un seul processus d’envoi logique consomme cette file ; son cycle de vie est celui de l’application, pas celui de la fenêtre de saisie. Isoler les adaptations Android et Linux derrière une interface pour le répertoire privé et la fermeture de la fenêtre.

**Technologies :** Flutter, Dart (`dart:io`, `dart:convert`, `HttpClient`), API WorkFlowy v1. Aucune dépendance externe pour la file. Pour la clé API uniquement, utiliser le stockage de secrets de la plateforme via `flutter_secure_storage`.

**Spécification :** [AGENTS.md](../../../AGENTS.md). **Point de départ :** le dossier contient les consignes, sans projet Flutter ni dépôt Git. Flutter et Dart ne sont pas dans le `PATH` de la machine de rédaction.

## Contraintes communes

- Une seule base de code. Conserver le texte et la date locale de validation même si l’envoi a lieu le lendemain.
- Seule la ligne exacte `-` sépare les entrées. Un retour à la ligne ordinaire reste dans le titre envoyé ; WorkFlowy le convertit en espace.
- `Ajouter` valide tout le lot localement ; `Cancel` et `Échap` abandonnent la saisie courante. `Ctrl+Entrée` valide sur Linux.
- Chemin fixe `Inbox/AAAA/MM/JJ/HHmm`. Envoi à sens unique, dans l’ordre. Ne retirer une entrée qu’après confirmation de création.

## Points à vérifier en priorité

| Situation | Résultat attendu | Étape |
|---|---|---|
| Texte collé avec fins de ligne Windows et séparateurs successifs | Pas d’item vide ; ordre et contenu conservés | 1 |
| Échec d’une écriture locale ou redémarrage juste après validation | Aucun lot partiellement validé ; les lots confirmés sont récupérables | 2 |
| Envoi le lendemain, chemin déjà partiellement présent | Classement à la minute de saisie, sans recréer les parents existants | 3 |
| Réseau coupé, clé refusée ou envoi partiellement confirmé | Saisie toujours disponible ; reprise des seules entrées encore en attente | 4 |
| Fermeture de la fenêtre avec des entrées en attente | Fermeture immédiate après écriture ; reprise sans rouvrir le formulaire tant que l’app tourne | 5 |

### 1. Créer le projet et définir une entrée

**Fichiers :** `pubspec.yaml`, `lib/capture.dart`, `test/capture_test.dart`, cibles générées `android/` et `linux/`.

- [ ] Vérifier `flutter doctor -v`, puis créer le projet dans le dossier existant avec `flutter create --platforms=android,linux --project-name wf_quick_add .`. Vérifier que les documents du projet sont conservés.
- [ ] Écrire le test de `List<String> parseCapture(String input)` : `A\r\nB\r\n-\r\nC` donne `['A\nB', 'C']` ; `-\n \n-\n` donne `[]` ; `rendez-vous` et `- texte` restent du texte. Exécuter `flutter test test/capture_test.dart` avant puis après implémentation.
- [ ] Normaliser les fins de ligne, comparer la ligne au séparateur **avant** tout nettoyage, ignorer les lignes blanches sans modifier les lignes de texte. Définir `PendingEntry` avec identifiant local, texte et segments de date locale calculés à la validation. Un lot utilise le même instant pour toutes ses entrées.

### 2. Rendre la validation indépendante du réseau

**Fichiers :** `lib/storage/outbox.dart`, `lib/platform/app_host.dart`, `test/outbox_test.dart`. Adaptateurs : `android/app/src/main/kotlin/…/MainActivity.kt` (chemin du package généré), `linux/runner/my_application.cc`.

- [ ] Définir `Outbox.enqueueBatch(List<PendingEntry>)`, `Outbox.pending()` et `Outbox.acknowledge(String id)` comme opérations asynchrones et sérialisées. Injecter le répertoire de stockage pour faire les tests dans un dossier temporaire.
- [ ] Tester la réouverture de la file après ajout de `A, B`, puis après confirmation de `A` : il reste `B`. Simuler un échec avant remplacement du fichier : la version précédente reste lisible et l’ajout échoue pour le lot entier.
- [ ] Implémenter une file JSON versionnée pour ce faible volume : écrire l’état complet dans un fichier temporaire du même répertoire, vider les tampons puis renommer avant de confirmer. Sérialiser ajout et acquittement pour ne perdre aucune modification concurrente. Ne pas remplacer silencieusement un fichier illisible par une file vide.
- [ ] Utiliser le dossier privé `filesDir` sur Android via un canal Flutter ; sur Linux, utiliser `$XDG_DATA_HOME/wf_quick_add`, avec repli vers `~/.local/share/wf_quick_add`. Vérifier avec `flutter test test/outbox_test.dart`.

### 3. Écrire le client WorkFlowy et le classement

**Fichiers :** `lib/workflowy/client.dart`, `lib/workflowy/destination.dart`, `test/workflowy_test.dart`.

- [ ] Tester le client contre un serveur HTTP local : pour le 25 novembre 2025 à 09:05, partir de `inbox`, réutiliser `2025/11`, créer les parents manquants `25/0905`, puis créer l’entrée. Vérifier que `A\nB` est envoyé dans un seul `name`, avec `position: "bottom"`, sans note.
- [ ] Implémenter la lecture des enfants (`GET /api/v1/nodes?parent_id=…`) et la création (`POST /api/v1/nodes`, résultat `item_id`). Envoyer la clé dans `Authorization: Bearer …`. Chercher chaque parent uniquement parmi les enfants du parent courant. Exposer `sendEntry(PendingEntry entry)` ; ne considérer la création comme confirmée qu’après réponse valide.
- [ ] Vérifier que `401`, `429` et une réponse de création sans `item_id` ne sont pas traités comme des succès. Lancer `flutter test test/workflowy_test.dart`. Référence : [API WorkFlowy](https://workflowy.com/api-reference/).

### 4. Orchestrer les envois et les reprises

**Fichiers :** `lib/sync/outbox_sender.dart`, `lib/settings/api_key_store.dart`, `test/outbox_sender_test.dart`.

- [ ] Avec une horloge et un client simulés, tester : démarrage hors ligne avec `A, B` ; succès de `A` puis échec de `B` ; retour du réseau sans nouvelle saisie. Vérifier que `B` est finalement envoyé et que `A` n’est pas renvoyé. Déclencher deux réveils simultanés et vérifier qu’un seul envoi démarre.
- [ ] Réveiller l’expéditeur au lancement, après validation locale, au retour de l’app au premier plan et après changement de clé. Si des entrées restent en attente après un échec réseau, programmer un nouvel essai avec un délai croissant plafonné ; respecter `Retry-After` si fourni. Ne pas entretenir de temporisation quand la file est vide. En cas de clé absente ou refusée, conserver les entrées et reprendre après correction.
- [ ] Stocker la clé séparément de la file, dans le stockage de secrets. Vérifier que l’enregistrement d’un lot fonctionne même sans clé. Lancer `flutter test test/outbox_sender_test.dart`.
- [ ] Distinguer dans la documentation de livraison un échec confirmé d’une réponse perdue : si WorkFlowy crée un item mais que sa réponse n’arrive pas, réessayer peut produire un doublon. Ne pas dédupliquer par titre : deux saisies identiques peuvent être intentionnelles.

### 5. Relier la fenêtre à la file et valider sur les deux cibles

**Fichiers :** `lib/main.dart`, `lib/ui/capture_window.dart`, `lib/ui/settings.dart`, adaptateurs de l’étape 2, `test/capture_window_test.dart`.

- [ ] Tester avec une écriture locale contrôlée : **Ajouter** ne ferme rien avant confirmation ; un succès ferme la fenêtre même si le réseau est indisponible ; un échec laisse le texte en place. **Cancel** et `Échap` n’écrivent rien. Sur Linux, `Entrée` insère un saut de ligne et `Ctrl+Entrée` valide une seule fois. Désactiver la double validation pendant l’écriture.
- [ ] Construire le champ multiligne avec focus initial, les boutons et l’accès aux préférences. Brancher le même gestionnaire de validation sur le bouton et le raccourci. Fermer la **fenêtre de saisie** sans arrêter l’expéditeur. Sur Linux, permettre de rouvrir la fenêtre en relançant l’app sans créer deux consommateurs ; sur Android, quitter la vue de saisie et reprendre la file si le système suspend puis relance le processus.
- [ ] Lancer `flutter analyze` puis `flutter test`. Sur une machine Linux, vérifier `flutter build linux` ; avec le SDK Android, vérifier `flutter build apk --debug`. Le build Linux nécessite un hôte Linux et les bibliothèques natives du stockage de secrets.
- [ ] Sur chaque cible, avec un compte WorkFlowy de test : couper le réseau, saisir l’exemple de `AGENTS.md`, valider, puis rétablir le réseau pendant que l’app tourne. Vérifier les deux titres, leur ordre et leur emplacement. Refaire l’essai en arrêtant l’app hors ligne : l’envoi doit reprendre au prochain lancement. Consigner les essais réellement effectués.
