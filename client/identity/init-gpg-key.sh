#!/usr/bin/env bash
# init-gpg-key.sh
#
# Crea (idempotente) un par GPG ed25519 aislado para el cliente Oasis local.
# Exporta <alias>.pub.asc listo para /profile/edit en la UI.
#
# Uso:
#   bash client/identity/init-gpg-key.sh
# Identidad: client/identity/identity.env (ver identity.env.example)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GPG_HOME="$SCRIPT_DIR/.gpg"

# Identidad del usuario → client/identity/identity.env (ignorado por git).
# Plantilla: identity.env.example. El entorno siempre tiene prioridad.
if [ -f "$SCRIPT_DIR/identity.env" ]; then
  # shellcheck disable=SC1091
  . "$SCRIPT_DIR/identity.env"
fi

GPG_NAME="${GPG_NAME:-}"
GPG_EMAIL="${GPG_EMAIL:-}"
GPG_COMMENT="${GPG_COMMENT:-Oasis client}"
GPG_PASSPHRASE="${GPG_PASSPHRASE:-}"
EXPORT_BASENAME="${GPG_EXPORT_BASENAME:-${GPG_NAME:-oasis-client}}"

if [ -z "$GPG_NAME" ] || [ -z "$GPG_EMAIL" ]; then
  echo "ERROR: faltan GPG_NAME / GPG_EMAIL." >&2
  echo "Copia client/identity/identity.env.example como identity.env y rellénalo," >&2
  echo "o pásalos por entorno: GPG_NAME=... GPG_EMAIL=... bash $0" >&2
  exit 1
fi
EXPORT_ASC="$GPG_HOME/${EXPORT_BASENAME}.pub.asc"

if ! command -v gpg >/dev/null 2>&1; then
  echo "ERROR: gpg no está disponible en PATH." >&2
  echo "En Windows instala GnuPG o usa Git Bash con gpg incluido." >&2
  exit 1
fi

mkdir -p "$GPG_HOME"
chmod 700 "$GPG_HOME" 2>/dev/null || true

export GNUPGHOME="$GPG_HOME"

fingerprint_for_email() {
  gpg --homedir "$GPG_HOME" --list-keys --with-colons "$1" 2>/dev/null \
    | awk -F: '$1 == "fpr" && $10 != "" { print $10; exit }'
}

existing_fp="$(fingerprint_for_email "$GPG_EMAIL" || true)"

if [[ -n "$existing_fp" ]]; then
  echo "✔ Clave GPG ya existe para <$GPG_EMAIL>"
  echo "  Huella: $existing_fp"
else
  echo "→ Generando clave GPG ed25519 en: $GPG_HOME"
  batch="$(mktemp)"
  trap 'rm -f "$batch"' EXIT
  cat >"$batch" <<EOF
%echo Generating Oasis client GPG key
Key-Type: EdDSA
Key-Curve: ed25519
Name-Real: ${GPG_NAME}
Name-Comment: ${GPG_COMMENT}
Name-Email: ${GPG_EMAIL}
Expire-Date: 0
EOF
  if [[ -n "$GPG_PASSPHRASE" ]]; then
    printf '%s\n' "Passphrase: ${GPG_PASSPHRASE}" >>"$batch"
  else
    printf '%s\n' '%no-protection' >>"$batch"
  fi
  printf '%s\n' '%commit' '%echo done' >>"$batch"
  gpg --homedir "$GPG_HOME" --batch --generate-key "$batch" >/dev/null
  existing_fp="$(fingerprint_for_email "$GPG_EMAIL")"
  echo "✔ Clave creada. Huella: $existing_fp"
fi

gpg --homedir "$GPG_HOME" --armor --export "$GPG_EMAIL" >"$EXPORT_ASC"
chmod 644 "$EXPORT_ASC" 2>/dev/null || true

cat >"$GPG_HOME/README.txt" <<EOF
Oasis client GPG keyring (private — do not commit)
Name:    ${GPG_NAME}
Email:   ${GPG_EMAIL}
Comment: ${GPG_COMMENT}
Fingerprint: ${existing_fp}

Public export for Oasis UI:
  ${EXPORT_ASC}

Upload ONLY the .pub.asc file in http://localhost:3000/profile/edit
Never upload private keys or this whole directory to the network.
EOF

echo
echo "============================================================"
echo " Clave pública (.asc) para Oasis → profile/edit"
echo "============================================================"
echo "  $EXPORT_ASC"
echo
echo "  Huella: $existing_fp"
echo "============================================================"
echo
head -n 6 "$EXPORT_ASC"
echo "  ..."
echo
echo "Sube ese archivo en la UI. Keyring privado (NO subir):"
echo "  $GPG_HOME"
