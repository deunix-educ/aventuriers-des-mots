#!/usr/bin/env python3
"""Genere le support imprimable d'installation Android (HTML et PDF).

Usage : generate_flyer.py   (via `make generate-flyer`)
Ecrit docs/distribution/support-imprimable.html (autonome : QR en SVG integre)
et le PDF correspondant si Chromium est disponible.
"""

import io
import shutil
import subprocess
import sys
from pathlib import Path

import qrcode
import qrcode.image.svg

REPO_URL = "https://deunix-educ.github.io/aventuriers-des-mots/fdroid/repo"
FINGERPRINT = (
    "87:29:A2:08:FA:21:58:00:A0:44:9B:C7:2C:77:7B:F5:"
    "89:CE:83:0C:7F:C3:5D:3B:C6:73:54:5B:B4:8A:A9:05"
)
OUT_DIR = Path(__file__).resolve().parent.parent / "docs" / "distribution"

PAGE = """<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<title>Les Aventuriers des mots - installer sur Android</title>
<style>
  @page {{ size: A4; margin: 14mm; }}
  body {{ font-family: "Atkinson Hyperlegible", "Helvetica Neue", Arial, sans-serif;
         color: #1f2937; max-width: 180mm; margin: 0 auto; }}
  h1 {{ font-size: 28pt; margin: 0 0 4mm; color: #2f6f3e; }}
  .sub {{ font-size: 14pt; margin: 0 0 8mm; }}
  .qr {{ float: right; width: 62mm; margin: 0 0 6mm 8mm; text-align: center;
         font-size: 10pt; }}
  .qr svg {{ width: 62mm; height: 62mm; }}
  ol {{ font-size: 14pt; line-height: 1.5; padding-left: 8mm; }}
  li {{ margin-bottom: 3mm; }}
  .addr {{ font-family: monospace; font-size: 12pt; word-break: break-all;
           background: #f3f4f6; padding: 2mm 3mm; border-radius: 2mm; }}
  .box {{ clear: both; border: 0.5mm solid #2f6f3e; border-radius: 3mm;
          padding: 4mm 5mm; margin-top: 6mm; font-size: 11pt; }}
  .fpr {{ font-family: monospace; font-size: 8.5pt; word-break: break-all; }}
  .small {{ font-size: 9.5pt; color: #4b5563; margin-top: 6mm; }}
</style>
</head>
<body>
<h1>Les Aventuriers des mots</h1>
<p class="sub">Jeu de français du CE1 au CM2 (7-11 ans) pour tablette ou
téléphone Android. Gratuit, sans publicité, sans connexion Internet.</p>

<div class="qr">{qr}<br>Scanner depuis F-Droid</div>

<h2>Installer en 4 étapes</h2>
<ol>
  <li>Installer l'application <strong>F-Droid</strong> (site f-droid.org).</li>
  <li>Dans F-Droid : <strong>Réglages</strong> &gt; <strong>Dépôts</strong> &gt;
      bouton <strong>+</strong>, puis scanner le QR code ci-contre
      ou saisir l'adresse :<br><span class="addr">{url}</span></li>
  <li>Contrôler que l'empreinte affichée est identique à celle
      du cadre ci-dessous, puis valider.</li>
  <li>Chercher <strong>« Les Aventuriers des mots »</strong> et installer.
      Les mises à jour arrivent ensuite par F-Droid.</li>
</ol>

<div class="box">
  <strong>Empreinte du dépôt (SHA-256)</strong>
  <div class="fpr">{fpr}</div>
</div>

<p class="small">Version préliminaire : le contenu pédagogique est en cours de
relecture par des enseignants et les voix des dictées sont provisoires.
Logiciel libre (AGPL-3.0) : code source sur
github.com/deunix-educ/aventuriers-des-mots. Les profils et la progression
restent sur l'appareil. Un adulte peut les consulter et les sauvegarder dans
l'espace adulte (Réglages).</p>
</body>
</html>
"""


def qr_svg(text: str) -> str:
    image = qrcode.make(text, image_factory=qrcode.image.svg.SvgPathImage, box_size=10)
    buffer = io.BytesIO()
    image.save(buffer)
    svg = buffer.getvalue().decode("utf-8")
    return svg[svg.index("<svg") :]


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    html_path = OUT_DIR / "support-imprimable.html"
    html_path.write_text(
        PAGE.format(qr=qr_svg(REPO_URL), url=REPO_URL, fpr=FINGERPRINT), encoding="utf-8"
    )
    print(f"écrit : {html_path}")
    browser = shutil.which("chromium") or shutil.which("google-chrome")
    if browser is None:
        print("Chromium absent : PDF non généré (imprimer le HTML depuis un navigateur).")
        return 0
    pdf_path = OUT_DIR / "support-imprimable.pdf"
    subprocess.run(
        [
            browser,
            "--headless=new",
            "--no-sandbox",
            "--disable-gpu",
            "--no-pdf-header-footer",
            f"--print-to-pdf={pdf_path}",
            html_path.as_uri(),
        ],
        check=True,
        capture_output=True,
    )
    print(f"écrit : {pdf_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
