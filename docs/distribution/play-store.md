# Publier sur Google Play (Android et Chromebooks)

Un seul référencement sert les téléphones, les tablettes et les Chromebooks
(Play Store de ChromeOS). Ce guide sépare ce que fait le dépôt de ce que seul
le propriétaire du compte peut faire. Les règles de Google évoluent : vérifier
chaque point dans la Play Console avant l'envoi.

## Ce que fournit le dépôt

- `make export-play` produit `build/play/aventuriers_des_mots.aab`
  (App Bundle, arm64 + x86_64, cible Android 16 / API 36, minimum Android 7),
  signé avec la clé de publication du projet.
- `make android-template` installe le modèle Gradle (appelé automatiquement ;
  `android/` n'est pas versionné). La première exportation télécharge les
  dépendances Gradle (accès réseau du poste de développement, jamais du jeu).
- Le numéro de version Play (`version/code`) est dérivé de `config/version`
  par `tools/package.sh` : `0.9.3` donne `903`. Il doit **augmenter** à chaque
  envoi : lancer `make package` (ou ajuster le preset « Android Play ») après
  avoir incrémenté `config/version`.
- ChromeOS : l'activité est redimensionnable, en paysage ; aucune fonction
  tactile n'est exigée (clavier et souris fonctionnent).

## Ce que doit faire le propriétaire du compte

1. **Compte développeur** (frais uniques) sur play.google.com/console. Selon le
   type de compte, Google peut exiger un **test fermé** avec un nombre minimal
   de testeurs pendant une durée minimale avant la production : à vérifier à
   l'inscription.
2. **Créer l'application** : nom « Les Aventuriers des mots », langue par
   défaut français, application gratuite, sans publicité.
3. **Signature par Google Play** : à l'envoi du premier bundle, activer Play App
   Signing. La clé du dépôt (`release.keystore`) devient la **clé d'envoi** ;
   Google conserve la clé de signature des appareils. Garder malgré tout une
   copie de sauvegarde de `release.keystore` et de `release.env` hors de la
   machine (une clé d'envoi perdue demande une procédure de réinitialisation
   auprès de Google).
4. **Fiche du magasin** : description courte et longue en français, icône
   512 × 512, image de présentation 1024 × 500, captures d'écran **de téléphone
   et de tablette/ChromeOS en paysage** (1152 × 648 convient). La commande
   `make screenshot` en produit.
5. **Public cible et contenu** : le jeu s'adresse à des enfants (7–11 ans) :
   déclarer le public « enfants » active les règles « Conçu pour les familles »
   (pas de publicité ciblée, pas de collecte de données personnelles, etc.).
   Remplir le questionnaire de classification du contenu.
6. **Sécurité des données** : déclarer « aucune donnée collectée ni partagée »
   (le jeu n'a aucun accès réseau : `permissions/internet=false`, sauvegardes
   locales uniquement). Cohérent avec l'invariant « aucun accès réseau ».
7. **Politique de confidentialité** : une page publique est exigée ; elle peut
   être courte (voir le modèle ci-dessous) et hébergée sur le dépôt (GitHub
   Pages ou fichier `PRIVACY.md` lien direct).
8. **Chromebooks** : dans « Appareils », vérifier que les Chromebooks sont
   pris en charge (aucune fonction matérielle exclusive n'est requise).
9. **Envoi** : créer une version en test interne ou fermé, y téléverser le
   `.aab`, tester sur appareil, puis passer en production.

## Contenu pédagogique et honnêteté de la fiche

Tant que les enseignants n'ont pas validé le contenu (`review_status: draft`),
privilégier un **test fermé** ou interne et le dire dans la description. La
version de production viendra après validation, avec `make release STABLE=1`
pour GitHub.

## Modèle de politique de confidentialité

> Les Aventuriers des mots ne collecte aucune donnée personnelle. Le jeu
> fonctionne entièrement hors ligne : il n'utilise aucune connexion Internet,
> aucun compte, aucune publicité et aucun outil de mesure d'audience. Les
> prénoms ou pseudonymes saisis pour créer un profil et la progression de
> l'enfant restent enregistrés sur l'appareil, dans l'espace de l'application,
> et ne sont jamais transmis. Désinstaller l'application ou supprimer un profil
> (espace adulte) efface ces données. Le code source est public (AGPL-3.0).
> Contact : adresse du dépôt GitHub (page Issues).

## Non vérifié

- Aucun `.aab` n'a été envoyé à la Play Console ni installé via Play ;
  l'installation du bundle (bundletool ou test interne) reste à faire.
- Comportement et ergonomie sur un vrai Chromebook (fenêtre, clavier, souris).
