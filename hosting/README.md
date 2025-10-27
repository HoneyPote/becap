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
4. Depuis ce dossier, lance `firebase deploy --only hosting`.
