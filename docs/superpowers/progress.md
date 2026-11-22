# SDD ledger — plan: docs/superpowers/plans/2026-11-22-wf-quick-add.md

- [x] 1. Saisie : tests CRLF, séparateur exact, textes identiques et minute locale.
- [x] 2. Stockage : tests de réouverture, concurrence, remplacement impossible et file illisible.
- [x] 3. API : serveur HTTP local, chemins partiels, ordre et refus de confirmation invalide.
- [x] 4. Reprise : tests de deux réveils, coupure partielle et changement de clé.
- [x] 5. Fenêtre : tests de sauvegarde avant fermeture, double validation, échec disque et raccourcis. Analyse Flutter sans diagnostic, 13 tests réussis avant revue.

Ruling: travail dans le dossier fourni, sans branche ni scripts de suivi Git : ce projet n'est pas un dépôt. Le suivi se fait dans ce fichier.

Interfaces : 1→2 lot horodaté ; 1→3 segments locaux ; 2+3→4 file et envoi confirmé ; 1+2+4→5 sauvegarde puis réveil asynchrone. Pas de conflit détecté.

Revue indépendante : deux défauts reproduits par des tests puis corrigés. Un échec disque après confirmation ne renvoie plus le même item tant que le processus vit ; un ancien 401 ne bloque plus une nouvelle clé. Après corrections : 15 tests réussis, analyse sans diagnostic.

Ruling: en GTK, les actions de saisie masquent la fenêtre ; la croix native permet de quitter complètement l’app. Les entrées persistées reprennent alors à la prochaine ouverture. Parcours documenté, test de masquage/réouverture ajouté au workflow Linux.

Android : APK debug compilé avec les corrections, installé sur un émulateur isolé ; deux entrées validées hors ligne, fenêtre fermée, file retrouvée après arrêt forcé, annulation sans modification vérifiée. Aucun compte WorkFlowy réel utilisé.

Cible Linux précisée : release AOT `linux-x64`, contrôle ELF du lanceur et des bibliothèques puis archivage du bundle complet.
