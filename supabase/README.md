# Serveur Supabase de Sawki English

Ce dossier contient tout ce qui tourne côté serveur :

| Élément | Rôle |
| --- | --- |
| `migrations/20261027000000_securite_profils.sql` | Règles d'accès (RLS) : chacun ne lit et ne modifie que son profil. Reprise des anciens profils par email vérifié. Compteur d'usage de l'IA. |
| `functions/gemini` | Intermédiaire vers l'API Gemini (tuteur et voix). La clé Gemini reste sur le serveur ; limite quotidienne par utilisateur. |
| `functions/delete-account` | Suppression définitive du compte (profil, usage IA, compte Auth), exigée par Google Play. |

## Déploiement (une seule fois, dans cet ordre)

Prérequis : [Supabase CLI](https://supabase.com/docs/guides/cli) installé, puis `supabase login` et `supabase link --project-ref bkptrqfcnbnlodzyvrjs`.

1. **Sauvegarder la table actuelle** : Dashboard › Table Editor › `user_profiles` › Export to CSV.
2. **Appliquer le script SQL** : `supabase db push`, ou copier le contenu du fichier de migration dans Dashboard › SQL Editor et l'exécuter. Il supprime les anciennes règles d'accès de `user_profiles` : à partir de là, les versions de l'app antérieures à cette mise à jour ne peuvent plus synchroniser.
3. **Activer les connexions** dans Dashboard › Authentication › Sign In / Providers :
   - « Allow anonymous sign-ins » : activé.
   - Email : activé, « Confirm email » activé.
4. **Afficher le code dans l'email** : Authentication › Emails › Templates. Dans « Magic Link » et « Confirm signup », ajouter le code, par exemple :
   `<p>Votre code Sawki English : <strong>{{ .Token }}</strong></p>`
   Pour la mise en production, configurer un SMTP personnalisé (Authentication › SMTP), l'envoi par défaut de Supabase étant très limité.
5. **Enregistrer la clé Gemini comme secret** (jamais dans l'app) :
   `supabase secrets set GEMINI_API_KEY=votre_cle`
6. **Déployer les fonctions** :
   `supabase functions deploy gemini` puis `supabase functions deploy delete-account`
7. **Changer la clé Gemini** : l'ancienne clé a pu être extraite des APK déjà distribués. Créer une nouvelle clé dans Google AI Studio, la mettre en secret (étape 5) et supprimer l'ancienne. Fixer aussi un plafond de dépenses dans Google Cloud.

## Réglages facultatifs (secrets de la fonction `gemini`)

| Secret | Par défaut | Rôle |
| --- | --- | --- |
| `CHAT_DAILY_LIMIT` | 30 | Messages au tuteur par jour (gratuit) |
| `CHAT_DAILY_LIMIT_PREMIUM` | 200 | Messages par jour (Premium) |
| `TTS_DAILY_LIMIT` | 100 | Phrases lues par la voix IA par jour (gratuit) |
| `TTS_DAILY_LIMIT_PREMIUM` | 400 | Idem (Premium) |
| `GLOBAL_CHAT_DAILY_LIMIT` | 0 (désactivé) | Plafond de messages par jour, tous utilisateurs confondus |
| `GLOBAL_TTS_DAILY_LIMIT` | 0 (désactivé) | Idem pour la voix |
| `GEMINI_CHAT_MODELS` | `gemini-3.6-flash,gemini-flash-latest` | Modèles essayés dans l'ordre |
| `GEMINI_TTS_MODEL` | `gemini-2.5-flash-preview-tts` | Modèle de voix |
| `GEMINI_TTS_VOICE` | `Aoede` | Voix |

Chaque appareil reçoit une session anonyme ; quelqu'un qui en créerait beaucoup pourrait multiplier sa limite quotidienne. Garde-fous : la limite de création de sessions anonymes de Supabase (Authentication › Rate Limits, à garder basse), le plafond global ci-dessus et le plafond de dépenses Google Cloud. Activer aussi le CAPTCHA de Supabase Auth si des abus apparaissent.

Le statut Premium (`is_premium`) ne peut être modifié que depuis le serveur (Dashboard ou clé service_role), jamais par l'application.

## Vérifier après déploiement

- Dashboard › Advisors › Security : aucune alerte « RLS disabled » sur `user_profiles` ni `ai_usage`.
- Dans l'app : envoyer un message au tuteur (réponse Gemini), associer son email avec le code reçu, puis « Supprimer mon compte » sur un compte de test.
