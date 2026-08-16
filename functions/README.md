# Déploiement de `scoreChallengePhoto`

Toutes les commandes Firebase doivent être lancées depuis la racine du dépôt
(le dossier qui contient `firebase.json`).

```bash
cd /Users/adammabrouki/becap
git pull
nvm use 22

# Supprime les dépendances d'une ancienne configuration locale.
rm -rf functions/node_modules functions/package-lock.json
npm install --prefix functions
npm run check --prefix functions

firebase use honeypote-becap
firebase functions:secrets:set OPENAI_API_KEY
firebase deploy --only functions:scoreChallengePhoto
```

Le check doit afficher
`scoreChallengePhoto est correctement exportée.`. Le déploiement doit afficher
une opération de création ou de mise à jour pour
`scoreChallengePhoto(us-central1)`. Un message qui indique seulement que les
sources ont été uploadées ne confirme pas le déploiement de cette fonction.

Pour vérifier l'URL sans envoyer de photo :

```bash
curl -i https://us-central1-honeypote-becap.cloudfunctions.net/scoreChallengePhoto
```

Une fonction déployée renvoie immédiatement `405 Method Not Allowed` à cette
requête GET. Une réponse `404` indique que la fonction n'existe pas à cette URL.
