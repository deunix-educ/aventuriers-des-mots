# Demande d'inclusion IzzyOnDroid (brouillon du ticket)

À déposer par le propriétaire du dépôt sur https://codeberg.org/IzzyOnDroid/repodata/issues
(compte Codeberg gratuit), après avoir publié la Release (`make release`).
Texte en anglais, langue du suivi. Il mentionne volontairement le développement
assisté par IA : leur politique rejette les applications « vibe-coded », il vaut
mieux le dire et laisser les mainteneurs trancher.

---

**Title:** New app: Les Aventuriers des mots (offline French spelling and grammar game for kids)

**Repository:** https://github.com/deunix-educ/aventuriers-des-mots
**Latest release (APK attached):** https://github.com/deunix-educ/aventuriers-des-mots/releases/latest
(or the tag page, e.g. `v0.9.3`: the release is marked "pre-release" because the educational content is still being reviewed by teachers)

**What it is:** a free educational game (French school years CE1 to CM2, ages 7 to 11)
made with Godot 4: an offline 2D adventure with exercises on spelling, homophones,
verb forms and dictations. No account, no ads, no analytics, no network permission
(`INTERNET` is not requested), all data stays on the device.

**Package name:** `org.deunix.aventuriersdesmots`

**License:** AGPL-3.0-or-later for code and original assets; Atkinson Hyperlegible
font under OFL-1.1; synthetic dictation voice generated offline with Piper
(`fr_FR-siwis-medium`, SIWIS corpus, CC BY 4.0, attribution in `assets/CREDITS.md`).

**APK:** `aventuriers-des-mots-<version>-android-arm64.apk`, arm64-v8a only,
about 28 MB (under your 30 MB limit), signed with the project's own release key,
attached to each GitHub release. Tags are `v<versionName>`.

**Metadata:** Fastlane structure in the repository
(`fastlane/metadata/android/fr-FR/`: title, short and full description, icon,
screenshots, changelogs named by versionCode).

**Proprietary components:** none intended. The app is built with the stock Godot
4.6 Android export template, which contains the small inactive
`com.android.vending.licensing` stub from the Android template; there is no
Google Play Services or Firebase code.

**AI disclosure:** the code and content were written with the help of an AI coding
assistant (Claude Code), under human direction and review: a written specification,
a decision log (`docs/specs/decisions.md`), 214 automated tests, and a content
review process in which all educational content is marked `draft` until teachers
validate it. I am telling you up front because of your policy on AI-generated
apps; I understand if this makes the app ineligible.

Thanks for considering it.

---

## Avant de déposer

- La Release la plus récente porte bien l'APK arm64 ; `make release` vérifie la
  signature de publication et la taille (< 30 Mo).
- Remplacer « 214 tests » et « about 28 MB » par les valeurs de la version publiée.
- Ne rien promettre sur l'acceptation : en cas de refus, voie 2 (dépôt F-Droid
  personnel) dans `docs/distribution/fdroid.md`.
