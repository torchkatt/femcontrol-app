#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  FemControl — Setup completo: GitHub + Firebase CI/CD       ║
# ║  Ejecutar UNA sola vez desde la raíz del proyecto           ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."
REPO_NAME="femcontrol-app"
REPO_DESC="Aplicación de seguimiento del ciclo menstrual — Flutter PWA"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

step() { echo -e "\n${BLUE}▶ $1${NC}"; }
ok()   { echo -e "${GREEN}✓ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  FemControl — Setup GitHub + Firebase CI/CD     ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ── Verificar herramientas ────────────────────────────────────
step "Verificando herramientas..."
command -v git      >/dev/null || fail "git no encontrado"
command -v gh       >/dev/null || fail "gh no encontrado — instalar con: brew install gh"
command -v firebase >/dev/null || fail "firebase no encontrado — instalar con: npm i -g firebase-tools"
ok "Todas las herramientas disponibles"

# ── Paso 1: Autenticar GitHub CLI ─────────────────────────────
step "Paso 1/4 — Autenticando GitHub CLI"
if gh auth status &>/dev/null; then
  GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "usuario")
  ok "Ya autenticado como @$GH_USER"
else
  warn "Se abrirá el navegador para autenticar con GitHub..."
  gh auth login --web --git-protocol https
  GH_USER=$(gh api user --jq '.login')
  ok "Autenticado como @$GH_USER"
fi

# ── Paso 2: Crear repositorio en GitHub ──────────────────────
step "Paso 2/4 — Creando repositorio GitHub"
cd "$PROJECT_DIR"

if gh repo view "$GH_USER/$REPO_NAME" &>/dev/null; then
  warn "Repositorio $GH_USER/$REPO_NAME ya existe"
  REPO_URL=$(gh repo view "$GH_USER/$REPO_NAME" --json url --jq '.url')
else
  echo -e "  Visibilidad del repositorio:"
  echo -e "  ${GREEN}[1]${NC} Privado (recomendado)"
  echo -e "  ${YELLOW}[2]${NC} Público"
  read -rp "  Elige [1/2, default=1]: " VISIBILITY_CHOICE
  VISIBILITY="${VISIBILITY_CHOICE:-1}"

  if [ "$VISIBILITY" = "2" ]; then
    gh repo create "$REPO_NAME" \
      --public \
      --description "$REPO_DESC" \
      --source="$PROJECT_DIR" \
      --remote=origin \
      --push
  else
    gh repo create "$REPO_NAME" \
      --private \
      --description "$REPO_DESC" \
      --source="$PROJECT_DIR" \
      --remote=origin \
      --push
  fi

  REPO_URL=$(gh repo view "$GH_USER/$REPO_NAME" --json url --jq '.url')
  ok "Repositorio creado: $REPO_URL"
fi

# Asegurar que el remote apunta al repo correcto
if ! git remote get-url origin &>/dev/null; then
  git remote add origin "https://github.com/$GH_USER/$REPO_NAME.git"
fi

# ── Paso 3: Token Firebase CI ─────────────────────────────────
step "Paso 3/4 — Generando Firebase CI token"
warn "Se abrirá el navegador para autorizar Firebase CI..."
echo -e "  (Este token permite que GitHub Actions haga deploy automáticamente)"

FIREBASE_TOKEN=$(firebase login:ci --no-localhost 2>/dev/null | grep "1//" | tr -d '[:space:]')

if [ -z "$FIREBASE_TOKEN" ]; then
  warn "No se pudo capturar el token automáticamente."
  echo -e "  Pega aquí el token que apareció en tu navegador (empieza con '1//'):"
  read -rp "  Token: " FIREBASE_TOKEN
fi

if [ -z "$FIREBASE_TOKEN" ]; then
  fail "No se proporcionó el Firebase CI token"
fi

ok "Firebase CI token obtenido"

# ── Paso 4: Agregar secret a GitHub ──────────────────────────
step "Paso 4/4 — Agregando FIREBASE_TOKEN a GitHub Secrets"
echo "$FIREBASE_TOKEN" | gh secret set FIREBASE_TOKEN --repo "$GH_USER/$REPO_NAME"
ok "Secret FIREBASE_TOKEN agregado"

# ── Push final (si no se hizo con gh repo create) ─────────────
if ! git ls-remote --heads origin main &>/dev/null; then
  step "Subiendo código a GitHub..."
  git branch -M main
  git push -u origin main
  ok "Código en GitHub"
fi

# ── Resumen ───────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ¡Todo listo! FemControl está configurado 🎉    ${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BLUE}Repositorio GitHub:${NC} $REPO_URL"
echo -e "  ${BLUE}App en producción: ${NC} https://femcontrol-app.web.app"
echo -e "  ${BLUE}Actions/CI:        ${NC} $REPO_URL/actions"
echo ""
echo -e "  ${YELLOW}Próximo push a main → deploy automático a Firebase${NC}"
echo ""
