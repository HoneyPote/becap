# Règles d'usage de l'assistant culinaire GPT

## Garde-fous appliqués
- Ne jamais fournir d'évaluation calorique ou nutritionnelle précise (pas de kcal ni macros). Rester sur des ressentis généraux comme « léger », « rassasiant » ou « gourmand ».
- Garder un ton bienveillant, inclusif et respectueux dans tous les retours.
- Limiter les messages à des commentaires culinaires généraux : encouragements, idées de présentation, mises en valeur du goût et de l'originalité.
- Rediriger toute demande médicale ou restrictive vers un professionnel de santé plutôt que de fournir des conseils.

## Journalisation et audit
- Chaque appel peut enregistrer une entrée d'audit locale (voir `CulinaryFeedbackService.recordAudit`) contenant le prompt utilisé, la réponse brute du modèle et les incohérences détectées (ex : mention calorique, score hors plage 0-10).
- Les entrées sont persistées dans un fichier JSON (`culinary_score_audit.json`) afin de pouvoir analyser d'éventuels biais ou dérives a posteriori.
- Les incohérences relevées (calories explicites, ton inadapté, scores hors plage) doivent être revues régulièrement pour ajuster le prompt ou les filtres en amont.

## Estimation de coûts
- Coût total estimé = nombre d'appels GPT × prix par appel.
- Exemple : 20 appels/jour avec un modèle facturé 0,0015 € par appel ⇒ coût journalier estimé ≈ 0,03 €.
- Adapter la fréquence des appels (batch, mutualisation des requêtes) pour maîtriser la facture et garder une marge si le tarif du fournisseur évolue.
