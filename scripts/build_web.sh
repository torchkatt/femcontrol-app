#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  FemControl — Script de build PWA para web                  ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$SCRIPT_DIR/../mobile"
BUILD_DIR="$MOBILE_DIR/build/web"

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  FemControl — Build PWA                         ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

cd "$MOBILE_DIR"

echo -e "\n${YELLOW}[1/3] Obteniendo dependencias...${NC}"
flutter pub get

echo -e "\n${YELLOW}[2/3] Compilando para web (PWA offline-first)...${NC}"
flutter build web \
  --pwa-strategy=offline-first \
  --release \
  --base-href="/" \
  --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://www.gstatic.com/flutter-canvaskit/

echo -e "\n${YELLOW}[3/3] Build completado.${NC}"
echo -e "${GREEN}✓ Archivos listos en: $BUILD_DIR${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Opciones de despliegue:"
echo -e ""
echo -e "  ${GREEN}Firebase Hosting${NC} (recomendado):"
echo -e "    cd mobile && firebase deploy"
echo -e ""
echo -e "  ${GREEN}Netlify${NC} (drag & drop):"
echo -e "    Arrastra la carpeta ${YELLOW}mobile/build/web/${NC} a netlify.com/drop"
echo -e ""
echo -e "  ${GREEN}Vercel${NC}:"
echo -e "    cd mobile && vercel --prod"
echo -e ""
echo -e "  ${GREEN}Servidor local (pruebas)${NC}:"
echo -e "    cd mobile/build/web && python3 -m http.server 8080"
echo -e "    Abrir: http://localhost:8080"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
