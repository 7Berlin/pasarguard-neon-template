#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
LOCAL_SOURCE_FILE="${SCRIPT_DIR}/index.html"
LOCAL_CONFIG_FILE="${SCRIPT_DIR}/template.conf"
DEST_DIR="/var/lib/pasarguard/templates/neon-subscription"
ENV_FILE="/opt/pasarguard/.env"
REPOSITORY="7Berlin/pasarguard-neon-template"
VERSION="main"
ACTIVATE=0
LANG_SELECTION_EXPLICIT=0
DEFAULT_LANG=""
CONFIG_FILE=""
LANGS=()
TEMP_SOURCE=""
TEMP_CONFIG=""
TEMP_RENDERED=""

cleanup() {
  [[ -n "$TEMP_SOURCE" && -f "$TEMP_SOURCE" ]] && rm -f "$TEMP_SOURCE" || true
  [[ -n "$TEMP_CONFIG" && -f "$TEMP_CONFIG" ]] && rm -f "$TEMP_CONFIG" || true
  [[ -n "$TEMP_RENDERED" && -f "$TEMP_RENDERED" ]] && rm -f "$TEMP_RENDERED" || true
}
trap cleanup EXIT

usage() {
  cat <<'TXT'
PasarGuard Neon Template installer

Usage:
  sudo bash install.sh [languages] [options]

Languages:
  -fa, --fa            Persian
  -en, --en            English
  -ru, --ru            Russian
  -zh, --zh            Chinese

Default: Persian only.
The first selected language is used as the default language.

Options:
  --lang LIST          Comma-separated languages, for example fa,en
  --default-lang LANG  Initial language; it must also be selected
  --config FILE        Template configuration file
  --activate           Update PasarGuard .env and restart the panel
  --dest DIR           Destination directory
  --env FILE           PasarGuard .env path
  --version REF        Git branch, tag, or commit
  -h, --help           Show this help

Examples:
  sudo bash install.sh --activate
  sudo bash install.sh --activate -fa -en
  sudo bash install.sh --activate -en -ru --default-lang en
  sudo bash install.sh --activate --config ./template.conf
TXT
}

is_supported_lang() {
  case "$1" in
    fa|en|ru|zh) return 0 ;;
    *) return 1 ;;
  esac
}

add_lang() {
  local lang="${1,,}"
  if ! is_supported_lang "$lang"; then
    echo "Unsupported language: $1. Supported: fa, en, ru, zh" >&2
    exit 1
  fi
  local existing
  for existing in "${LANGS[@]:-}"; do
    [[ "$existing" == "$lang" ]] && return 0
  done
  LANGS+=("$lang")
}

select_language_flag() {
  if [[ "$LANG_SELECTION_EXPLICIT" -eq 0 ]]; then
    LANGS=()
    LANG_SELECTION_EXPLICIT=1
  fi
  add_lang "$1"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -fa|--fa) select_language_flag fa; shift ;;
    -en|--en) select_language_flag en; shift ;;
    -ru|--ru) select_language_flag ru; shift ;;
    -zh|--zh) select_language_flag zh; shift ;;
    --lang)
      [[ $# -ge 2 ]] || { echo "Missing value for --lang" >&2; exit 1; }
      if [[ "$LANG_SELECTION_EXPLICIT" -eq 0 ]]; then
        LANGS=()
        LANG_SELECTION_EXPLICIT=1
      fi
      IFS=',' read -r -a requested_langs <<< "$2"
      for requested_lang in "${requested_langs[@]}"; do
        add_lang "$requested_lang"
      done
      shift 2
      ;;
    --default-lang)
      [[ $# -ge 2 ]] || { echo "Missing value for --default-lang" >&2; exit 1; }
      DEFAULT_LANG="${2,,}"
      shift 2
      ;;
    --config)
      [[ $# -ge 2 ]] || { echo "Missing value for --config" >&2; exit 1; }
      CONFIG_FILE="$2"
      shift 2
      ;;
    --activate) ACTIVATE=1; shift ;;
    --dest)
      [[ $# -ge 2 ]] || { echo "Missing value for --dest" >&2; exit 1; }
      DEST_DIR="$2"
      shift 2
      ;;
    --env)
      [[ $# -ge 2 ]] || { echo "Missing value for --env" >&2; exit 1; }
      ENV_FILE="$2"
      shift 2
      ;;
    --version)
      [[ $# -ge 2 ]] || { echo "Missing value for --version" >&2; exit 1; }
      VERSION="$2"
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ ${#LANGS[@]} -eq 0 ]]; then
  LANGS=(fa)
fi
if [[ -z "$DEFAULT_LANG" ]]; then
  DEFAULT_LANG="${LANGS[0]}"
fi
if ! is_supported_lang "$DEFAULT_LANG"; then
  echo "Unsupported default language: $DEFAULT_LANG" >&2
  exit 1
fi

DEFAULT_SELECTED=0
for selected_lang in "${LANGS[@]}"; do
  [[ "$selected_lang" == "$DEFAULT_LANG" ]] && DEFAULT_SELECTED=1
done
if [[ "$DEFAULT_SELECTED" -ne 1 ]]; then
  echo "The default language '$DEFAULT_LANG' is not selected: ${LANGS[*]}" >&2
  exit 1
fi

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root: sudo bash install.sh --activate" >&2
  exit 1
fi

SOURCE_FILE="$LOCAL_SOURCE_FILE"
if [[ ! -f "$SOURCE_FILE" ]]; then
  TEMP_SOURCE="$(mktemp)"
  SOURCE_URL="https://raw.githubusercontent.com/${REPOSITORY}/${VERSION}/index.html"
  echo "Downloading template: $SOURCE_URL"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$SOURCE_URL" -o "$TEMP_SOURCE"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$TEMP_SOURCE" "$SOURCE_URL"
  else
    echo "curl or wget is required." >&2
    exit 1
  fi
  SOURCE_FILE="$TEMP_SOURCE"
fi

DEST_CONFIG_FILE="${DEST_DIR}/template.conf"
if [[ -n "$CONFIG_FILE" ]]; then
  [[ -f "$CONFIG_FILE" ]] || { echo "Config file not found: $CONFIG_FILE" >&2; exit 1; }
elif [[ -f "$LOCAL_CONFIG_FILE" ]]; then
  CONFIG_FILE="$LOCAL_CONFIG_FILE"
elif [[ -f "$DEST_CONFIG_FILE" ]]; then
  CONFIG_FILE="$DEST_CONFIG_FILE"
else
  TEMP_CONFIG="$(mktemp)"
  CONFIG_URL="https://raw.githubusercontent.com/${REPOSITORY}/${VERSION}/template.conf"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$CONFIG_URL" -o "$TEMP_CONFIG"
  else
    wget -qO "$TEMP_CONFIG" "$CONFIG_URL"
  fi
  CONFIG_FILE="$TEMP_CONFIG"
fi

# Defaults used when a value is missing from template.conf.
BRAND_NAME="Space VPN"
BRAND_SUBTITLE=""
LOGO_URL=""
AVATAR_URL=""
AVATAR_FILE=""
PRIMARY_COLOR="#9a4dff"
SECONDARY_COLOR="#d94dff"
CYAN_COLOR="#20d8ff"
DEFAULT_THEME="dark"
PANEL_DOMAIN=""
SUPPORT_URL=""
FLAG_CDN_BASE="https://flagcdn.com/w80"
SHOW_MASKED_HOST="true"
REFRESH_INTERVAL_MS="30000"

set +u
# shellcheck disable=SC1090
source "$CONFIG_FILE"
set -u

case "$DEFAULT_THEME" in dark|light) ;; *) echo "DEFAULT_THEME must be dark or light." >&2; exit 1 ;; esac
case "${SHOW_MASKED_HOST,,}" in true|1|yes) SHOW_MASKED_HOST="true" ;; false|0|no) SHOW_MASKED_HOST="false" ;; *) echo "SHOW_MASKED_HOST must be true or false." >&2; exit 1 ;; esac
[[ "$REFRESH_INTERVAL_MS" =~ ^[0-9]+$ ]] || { echo "REFRESH_INTERVAL_MS must be a number." >&2; exit 1; }

mime_for_image() {
  case "${1##*.}" in
    png|PNG) printf 'image/png' ;;
    jpg|JPG|jpeg|JPEG) printf 'image/jpeg' ;;
    webp|WEBP) printf 'image/webp' ;;
    gif|GIF) printf 'image/gif' ;;
    svg|SVG) printf 'image/svg+xml' ;;
    *) return 1 ;;
  esac
}

if [[ -n "$AVATAR_FILE" ]]; then
  if [[ "$AVATAR_FILE" != /* ]]; then
    AVATAR_FILE="$(cd "$(dirname "$CONFIG_FILE")" && pwd)/$AVATAR_FILE"
  fi
  [[ -f "$AVATAR_FILE" ]] || { echo "Avatar file not found: $AVATAR_FILE" >&2; exit 1; }
  MIME_TYPE="$(mime_for_image "$AVATAR_FILE")" || { echo "Unsupported avatar format. Use PNG, JPG, WEBP, GIF, or SVG." >&2; exit 1; }
  command -v base64 >/dev/null 2>&1 || { echo "base64 is required to embed AVATAR_FILE." >&2; exit 1; }
  AVATAR_URL="data:${MIME_TYPE};base64,$(base64 < "$AVATAR_FILE" | tr -d '\r\n')"
fi

json_quote() {
  local value="${1-}"
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  printf '"%s"' "$value"
}

LANG_JSON="["
for index in "${!LANGS[@]}"; do
  [[ "$index" -gt 0 ]] && LANG_JSON+=","
  LANG_JSON+="$(json_quote "${LANGS[$index]}")"
done
LANG_JSON+="]"

CONFIG_JSON="{\"brandName\":$(json_quote "$BRAND_NAME"),\"brandSubtitle\":$(json_quote "$BRAND_SUBTITLE"),\"logoUrl\":$(json_quote "$LOGO_URL"),\"avatarUrl\":$(json_quote "$AVATAR_URL"),\"primary\":$(json_quote "$PRIMARY_COLOR"),\"primary2\":$(json_quote "$SECONDARY_COLOR"),\"cyan\":$(json_quote "$CYAN_COLOR"),\"defaultLanguage\":$(json_quote "$DEFAULT_LANG"),\"supportedLanguages\":${LANG_JSON},\"defaultTheme\":$(json_quote "$DEFAULT_THEME"),\"panelDomain\":$(json_quote "$PANEL_DOMAIN"),\"supportUrl\":$(json_quote "$SUPPORT_URL"),\"flagCdnBase\":$(json_quote "$FLAG_CDN_BASE"),\"showMaskedHost\":${SHOW_MASKED_HOST},\"refreshIntervalMs\":${REFRESH_INTERVAL_MS}}"

command -v base64 >/dev/null 2>&1 || { echo "base64 is required." >&2; exit 1; }
ENCODED_CONFIG="$(printf '%s' "$CONFIG_JSON" | base64 | tr -d '\r\n')"

if ! grep -q 'const encodedConfig = "' "$SOURCE_FILE"; then
  echo "Template configuration marker was not found." >&2
  exit 1
fi

TEMP_RENDERED="$(mktemp)"
sed -E "s|const encodedConfig = \"[A-Za-z0-9+/=]*\";|const encodedConfig = \"${ENCODED_CONFIG}\";|" "$SOURCE_FILE" > "$TEMP_RENDERED"

mkdir -p "$DEST_DIR"
DEST_FILE="${DEST_DIR}/index.html"
if [[ -f "$DEST_FILE" ]]; then
  BACKUP_FILE="${DEST_FILE}.bak.$(date +%Y%m%d-%H%M%S)"
  cp -a "$DEST_FILE" "$BACKUP_FILE"
  echo "Backup: $BACKUP_FILE"
fi
install -m 0644 "$TEMP_RENDERED" "$DEST_FILE"

if [[ "$CONFIG_FILE" != "$DEST_CONFIG_FILE" ]]; then
  if [[ -f "$DEST_CONFIG_FILE" ]]; then
    cp -a "$DEST_CONFIG_FILE" "${DEST_CONFIG_FILE}.bak.$(date +%Y%m%d-%H%M%S)"
  fi
  install -m 0644 "$CONFIG_FILE" "$DEST_CONFIG_FILE"
fi

echo "Installed: $DEST_FILE"
echo "Config: $DEST_CONFIG_FILE"
echo "Languages: ${LANGS[*]}"
echo "Default language: $DEFAULT_LANG"

upsert_env() {
  local key="$1"
  local value="$2"
  if grep -qE "^[[:space:]]*${key}=" "$ENV_FILE"; then
    sed -i -E "s|^[[:space:]]*${key}=.*|${key}=\"${value}\"|" "$ENV_FILE"
  else
    printf '\n%s="%s"\n' "$key" "$value" >> "$ENV_FILE"
  fi
}

if [[ "$ACTIVATE" -eq 1 ]]; then
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "PasarGuard env file was not found: $ENV_FILE" >&2
    echo "The template was installed but not activated." >&2
    exit 1
  fi

  ENV_BACKUP="${ENV_FILE}.bak.$(date +%Y%m%d-%H%M%S)"
  cp -a "$ENV_FILE" "$ENV_BACKUP"

  TEMPLATE_ROOT="$(dirname "$DEST_DIR")/"
  TEMPLATE_PATH="$(basename "$DEST_DIR")/index.html"
  upsert_env CUSTOM_TEMPLATES_DIRECTORY "$TEMPLATE_ROOT"
  upsert_env SUBSCRIPTION_PAGE_TEMPLATE "$TEMPLATE_PATH"
  echo "Updated: $ENV_FILE"
  echo "Environment backup: $ENV_BACKUP"

  if command -v pasarguard >/dev/null 2>&1; then
    pasarguard restart
  else
    echo "Restart PasarGuard or its container manually."
  fi
else
  cat <<TXT

Add these values to ${ENV_FILE}:
CUSTOM_TEMPLATES_DIRECTORY="$(dirname "$DEST_DIR")/"
SUBSCRIPTION_PAGE_TEMPLATE="$(basename "$DEST_DIR")/index.html"

Then restart PasarGuard.
TXT
fi
