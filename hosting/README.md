# Becap Universal Link Hosting Pack

Ce dossier contient tout le nécessaire pour héberger la page `/join` et le fichier `apple-app-site-association` sur Firebase Hosting.

## Contenu
- `firebase.json` – configuration Firebase Hosting avec les en-têtes et les réécritures pour `/join`.
- `public/.well-known/apple-app-site-association` – configuration Universal Links (remplace `YOUR_TEAM_ID` par ton Team ID Apple réel avant déploiement).
- `public/join.html` – landing de fallback avec métadonnées Open Graph et redirection vers l'app.
- `public/og/` – dossier contenant un README précisant où déposer le visuel 1200×630 utilisé par WhatsApp / iMessage.

## Déploiement rapide
1. Vérifie/édite `apple-app-site-association` pour y mettre ton Team ID.
2. Ajoute ton image `becap-share-epic.jpg` (1200×630) dans `public/og/` avant déploiement.
3. Mets à jour l'URL App Store dans `join.html` dès que l'app est publiée.
4. Ajuste au besoin l'ordre des domaines dans `BECUniversalLinkHosts` (Info.plist) pour que le premier corresponde au domaine dont le certificat TLS est actif.
5. Depuis ce dossier, lance `firebase deploy --only hosting`.

## Dépannage : "aucune connexion sécurisée"

- Vérifie que le domaine (`becap.app`, `www.becap.app`, etc.) est bien connecté à ton site Firebase Hosting et que le certificat TLS est indiqué comme **Actif** dans la console Firebase. Juste après l'ajout d'un domaine, le certificat peut prendre jusqu'à une heure pour être provisionné.
- Si l'apex `becap.app` est encore en attente de certificat, place temporairement `www.becap.app` (ou ton sous-domaine valide) en premier dans le tableau `BECUniversalLinkHosts` du `Info.plist`. Le message de partage inclura automatiquement un lien de secours vers le domaine suivant de la liste.
- Une fois le certificat du domaine principal actif, replace-le en tête de `BECUniversalLinkHosts` pour que les Universal Links pointent dessus.
