#!/bin/bash
# Servidor de documentación Zofía
# Uso: bash servidor.sh [puerto]

PUERTO="${1:-8888}"
DIR="$(cd "$(dirname "$0")" && pwd)"
URL="http://localhost:$PUERTO"

echo ""
echo "  ⚡ Zofía — Servidor de documentación"
echo "  ─────────────────────────────────────"
echo "  URL:     $URL"
echo "  Carpeta: $DIR"
echo "  Puerto:  $PUERTO"
echo ""
echo "  Presiona Ctrl+C para detener."
echo ""

# Abrir navegador automáticamente
if command -v xdg-open &>/dev/null; then
    xdg-open "$URL" 2>/dev/null &
elif command -v open &>/dev/null; then
    open "$URL" &
fi

cd "$DIR" && python3 -m http.server "$PUERTO"
