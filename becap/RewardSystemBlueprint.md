# Becap – Système de récompenses étendu

Ce blueprint ajoute des mécaniques de récompenses addictives tout en restant compatibles avec l'app Becap (calendrier, défis photos, jokers, médailles).

## 1. Coffres journaliers évolutifs
- **Déclencheur :** ouverture de l'app + maintien du streak.
- **Récompenses possibles :** joker quotidien, stickers, tickets chance, boost de likes, thèmes premium, skin calendrier épique, super like.
- **Progression :** paliers de streak (1, 7, 21 jours) déverrouillant des coffres plus généreux.

## 2. Roue hebdomadaire
- **Déclencheur :** un spin le dimanche soir.
- **Récompenses :** joker, palette premium, boost de visibilité d'1h, super like, skin calendrier.
- **Rareté :** pondérée par un poids de probabilité (voir `RewardService`).

## 3. Système d'XP et niveaux
- **Sources d'XP :** +10 (photo), +5 (commentaire), +50 (défi complété), +100 (invitation), +20/jour pour streak > 7 jours.
- **Usage :** progression de niveau, affichage dans le profil, déblocage de cosmétiques (thèmes, bordures, emojis premium).

## 4. Récompenses saisonnières (30 jours)
- **Tiers proposés :** 50 pts (sticker saison), 150 pts (bordure épique), 300 pts (super joker saisonnier).
- **Déclencheurs :** publication, validation quotidienne, likes reçus, défis réussis.
- **Feedback :** animation d'unlock + badge saison.

## 5. Collection de stickers
- **Obtention :** actions importantes (défi validé, saison terminée, longue série).
- **Usage :** profil, photos, chat de groupe.
- **Boucle de rétention :** collection complète = badge rare.

## Implémentation technique (aperçu)
- `Models/RewardModels.swift` : modèles pour les récompenses, coffres, roue hebdomadaire, XP et tiers saisonniers.
- `Services/RewardService` : configuration par défaut, sélection aléatoire pondérée et calcul des récompenses (coffre quotidien, roue, XP, saison).
- **Stockage :** les modèles sont `Codable` pour s'intégrer à Firestore si nécessaire.
