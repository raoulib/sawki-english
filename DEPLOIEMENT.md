# Consignes de déploiement de Sawki English (pour l'agent Antigravity)

Ce document s'adresse à l'agent qui déploie Sawki English. Lis-le en entier avant toute commande. Les détails techniques du serveur sont dans [`supabase/README.md`](supabase/README.md).

## Contexte

- Application Flutter (Android d'abord) éditée par Sawki Technologies 2IM.
- Dépôt : `raoulib/sawki-english`. Les corrections de sécurité sont dans deux PR, à fusionner dans l'ordre : #1 (application), puis #2 (serveur Supabase).
- Projet Supabase de production : référence `bkptrqfcnbnlodzyvrjs`.
- Version de Flutter attendue : 3.41.9 (Dart 3.11.5).

## Règles à respecter

1. **Aucun secret dans le code ni dans Git.** La clé Gemini, la clé `service_role` de Supabase, le keystore Android et `android/key.properties` ne doivent jamais être commités, affichés dans un log partagé ou collés dans un fichier du dépôt.
2. **Sauvegarder avant de toucher à la base.** Exporter la table `user_profiles` en CSV avant d'exécuter le script SQL.
3. **Tester avant la production.** Faire d'abord tout le déploiement sur un projet Supabase de test (ou une branche Supabase), puis seulement sur la production.
4. **Demander l'accord de Raoul avant chaque étape marquée ⛔.** Ces étapes sont irréversibles ou visibles des utilisateurs.
5. **Ne rien supprimer** (table, colonne, utilisateur, fonction) en dehors de ce que le script SQL fait déjà.
6. **Ne modifier ni les règles d'accès (RLS), ni le script SQL, ni les fonctions** sans le signaler à Raoul. Si quelque chose échoue, s'arrêter et rapporter l'erreur exacte au lieu de contourner.
7. **Ne jamais passer `is_premium` à vrai** pour un utilisateur sans demande explicite de Raoul.

## Étape 0 : prérequis

- Supabase CLI installé, puis `supabase login`.
- Flutter 3.41.9 : `flutter --version`.
- Accès au keystore de publication Android (fourni par Raoul, jamais commité).
- Une nouvelle clé API Gemini créée par Raoul dans Google AI Studio (l'ancienne a pu fuiter et doit être supprimée).

## Étape 1 : déploiement sur un projet Supabase de test

1. Créer ou choisir un projet de test, puis `supabase link --project-ref <ref_du_projet_de_test>`.
2. Appliquer le script : `supabase db push` (ou exécuter `supabase/migrations/20261027000000_securite_profils.sql` dans le SQL Editor).
3. Dans Authentication › Sign In / Providers : activer « Allow anonymous sign-ins », activer Email avec « Confirm email ».
4. Dans Authentication › Emails › Templates, modèles « Magic Link » et « Confirm signup » : ajouter `<p>Votre code Sawki English : <strong>{{ .Token }}</strong></p>`.
5. Secret : `supabase secrets set GEMINI_API_KEY=<nouvelle_cle>` (taper la clé dans le terminal, ne pas l'écrire dans un fichier).
6. Fonctions : `supabase functions deploy gemini` puis `supabase functions deploy delete-account`.
7. Lancer l'app contre ce projet :
   `flutter run --dart-define=SUPABASE_URL=https://<ref_test>.supabase.co --dart-define=SUPABASE_ANON_KEY=<cle_publique_test>`

## Étape 2 : vérifications sur le projet de test

Chaque point doit être validé avant de passer à la production :

- [ ] Le tuteur Sarah répond (réponse IA, pas le mode hors ligne).
- [ ] La voix IA lit une phrase.
- [ ] « Associer mon email » : un code à 6 chiffres arrive par email et est accepté.
- [ ] « Récupérer mon compte » sur un deuxième appareil (ou après réinstallation) restaure XP et niveau.
- [ ] Un mauvais code est refusé.
- [ ] Après 30 messages dans la journée, le tuteur affiche le message de limite quotidienne.
- [ ] « Supprimer mon compte et mes données » : la ligne disparaît de `user_profiles` et l'utilisateur de Authentication › Users.
- [ ] Advisors › Security : aucune alerte RLS sur `user_profiles` ni `ai_usage`.
- [ ] Requête directe avec la clé publique sans session (`GET /rest/v1/user_profiles`) : aucune ligne renvoyée.

Rapporter à Raoul le résultat de chaque point, avec les erreurs exactes s'il y en a.

## Étape 3 : production

⛔ Demander l'accord de Raoul avant de commencer cette étape.

1. Exporter `user_profiles` en CSV (Table Editor › Export) et conserver le fichier hors du dépôt.
2. `supabase link --project-ref bkptrqfcnbnlodzyvrjs`.
3. Refaire les points 2 à 6 de l'étape 1 sur la production.
4. Configurer un SMTP personnalisé (Authentication › SMTP) : l'envoi d'emails par défaut de Supabase est trop limité pour de vrais utilisateurs.
5. Vérifier que Authentication › Rate Limits garde une limite basse pour la création de sessions anonymes.
6. Supprimer l'ancienne clé Gemini dans Google AI Studio et fixer un plafond de dépenses dans Google Cloud (Raoul le fait si l'agent n'a pas l'accès).

Important : après l'étape 3.3, les anciennes versions de l'app ne peuvent plus synchroniser. La nouvelle version doit être publiée juste après.

## Étape 4 : publication Android

⛔ Demander l'accord de Raoul avant d'envoyer quoi que ce soit sur la Play Console.

1. Augmenter le numéro de version dans `pubspec.yaml` (par exemple `1.0.1+2`).
2. Placer `android/key.properties` et le keystore (fournis par Raoul) sans les commiter. La compilation échoue volontairement s'ils manquent.
3. `flutter build appbundle --release`
4. Avant d'activer les vraies publicités : créer les blocs d'annonces AdMob, renseigner les identifiants dans `lib/core/config/monetization_config.dart` et passer `isTestMode` à `false`. Sinon, laisser le mode test.
5. Dans la Play Console : mettre à jour le formulaire « Sécurité des données » d'après `docs/index.html`, indiquer l'URL de suppression de compte, régler la classification sur un public de 18 ans et plus.
6. Envoyer d'abord sur la piste de test interne, puis en production après validation par Raoul.

## Ce que l'agent doit rapporter à la fin

- Les étapes faites, avec leur résultat (réussite ou erreur exacte).
- La liste de contrôle de l'étape 2 cochée.
- Ce qui reste à faire par Raoul (accès manquants, décisions).
- Aucun secret dans le rapport.
