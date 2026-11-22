ceci est une app en flutter pour android et linux
meme codebase
c'ezst dans l'app elle meme que les test sont evebtuellemenrt efferctués pour savoir si l'app tourne dans linux ou dans android
tu as acces en ligne à toutes les docs de workflowy. et tu peux t'inspirer du code de l'outil cli wf, pour workflowy. 

c'est une app qui utilise l'apiu de workflowy pour ajputer une enttrée de type quick ibnput?
Dcon les prefs c'est de donnert le token ou le compte pour acceder à workflowy, de pouvoir indiquer le chemon dans lequel ajouter les entré&es.
et de personnaliser le nom des items. par défaaut q c'est le format qa-20251125 dans "Inbox" à la raine de workflowy

dans l'interface d'input, un retour à la a la ligne es un nouveai item dans workflowy. le system d'input ne permet pas de laisser une ligne vide.

app trs simmle. ouvre une fenetre, demande a ce qu'on tape, ajoute l'input à une mini base de données locale (fournie par dart, pas de dépendance) de telle sorte que toute ecriture est toujours siccessful puisque cé ecrit déns une basze locae; ensuie, tan que l'app est lancée, quiad une écriture est vlidére, un processus en arriere plan v scanner si il y a une conncecgin vers workflowye et si oiu il va tenter de vider la queue contenu dans la base locale. si ca fonctionne, on enelebde la queue. pas de synchor a deux sens our une mderde dansl e genre. la sgbd est juse un cache pour qu'il ne aille pas attendre que nous soyons en ligne pour valider l(input
