#!/usr/bin/env bash
# Script de configuración para gemini-web-to-api
# Este script configura el servidor local que permite usar Gemini con cookies

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/share/gemini-web-to-api"
ENV_FILE="$INSTALL_DIR/.env"

echo "=== Configuración de Gemini Web to API ==="
echo ""

# Crear directorio de instalación
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/cookies"

# Verificar si Docker está disponible
if command -v docker &> /dev/null; then
    echo "✅ Docker detectado"
    USE_DOCKER=true
elif command -v podman &> /dev/null; then
    echo "✅ Podman detectado"
    USE_DOCKER=true
else
    echo "❌ Docker/Podman no detectado"
    echo "   Se usará el binario nativo en su lugar"
    USE_DOCKER=false
fi

# Solicitar cookies al usuario
echo ""
echo "=== Extracción de Cookies ==="
echo ""
echo "Para usar Gemini Web, necesitas extraer 2 cookies de tu navegador:"
echo ""
echo "1. Abre Brave/Chrome y ve a https://gemini.google.com"
echo "2. Inicia sesión con tu cuenta de Google"
echo "3. Presiona F12 para abrir Developer Tools"
echo "4. Ve a Application → Storage → Cookies → https://gemini.google.com"
echo "5. Copia los valores de:"
echo "   - __Secure-1PSID"
echo "   - __Secure-1PSIDTS"
echo ""

read -p "¿Tienes las cookies listas? (s/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Configuración cancelada. Ejecuta este script nuevamente cuando tengas las cookies."
    exit 0
fi

echo ""
read -p "Pega el valor de __Secure-1PSID: " PSID
read -p "Pega el valor de __Secure-1PSIDTS: " PSIDTS

if [ -z "$PSID" ] || [ -z "$PSIDTS" ]; then
    echo "❌ Error: Las cookies no pueden estar vacías"
    exit 1
fi

# Crear archivo .env
cat > "$ENV_FILE" << EOF
# Configuración de Gemini Web to API
# Generado automáticamente por setup_gemini_web.sh

# Cookies de autenticación (obtenidas del navegador)
GEMINI_1PSID=$PSID
GEMINI_1PSIDTS=$PSIDTS

# Intervalo de rotación de cookies (minutos)
# Recomendado: 30-60 minutos para uso normal
GEMINI_REFRESH_INTERVAL=60

# Máximo de reintentos cuando una llamada falla
GEMINI_MAX_RETRIES=2

# Puerto del servidor (no cambiar sin actualizar ambxst)
PORT=4981

# Rate limiting (configuración conservadora para uso personal)
RATE_LIMIT_ENABLED=true
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=5

# Entorno
APP_ENV=production
EOF

echo ""
echo "✅ Archivo .env creado en: $ENV_FILE"

# Configurar permisos seguros
chmod 600 "$ENV_FILE"
chmod 700 "$INSTALL_DIR/cookies"

if [ "$USE_DOCKER" = true ]; then
    echo ""
    echo "=== Configuración con Docker ==="
    
    # Crear docker-compose.yml
    cat > "$INSTALL_DIR/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  gemini-web-to-api:
    image: ghcr.io/ntthanh2603/gemini-web-to-api:latest
    container_name: gemini-web-to-api
    ports:
      - "4981:4981"
    env_file:
      - .env
    volumes:
      - ./cookies:/home/appuser/.cookies
    tmpfs:
      - /tmp:rw,size=512m
      - /home/appuser/.cache:rw,size=256m
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4981/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF

    echo "✅ docker-compose.yml creado"
    echo ""
    echo "=== Iniciar servidor ==="
    echo ""
    echo "Para iniciar el servidor, ejecuta:"
    echo "  cd $INSTALL_DIR"
    echo "  docker compose up -d"
    echo ""
    echo "Para ver los logs:"
    echo "  docker logs -f gemini-web-to-api"
    echo ""
    echo "Para detener el servidor:"
    echo "  cd $INSTALL_DIR"
    echo "  docker compose down"
    
else
    echo ""
    echo "=== Configuración con Binario Nativo ==="
    echo ""
    
    # Descargar binario
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        BIN_URL="https://github.com/ntthanh2603/gemini-web-to-api/releases/latest/download/gemini-web-to-api-linux-amd64"
        BIN_NAME="gemini-web-to-api-linux-amd64"
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        BIN_URL="https://github.com/ntthanh2603/gemini-web-to-api/releases/latest/download/gemini-web-to-api-linux-arm64"
        BIN_NAME="gemini-web-to-api-linux-arm64"
    else
        echo "❌ Arquitectura no soportada: $ARCH"
        echo "   Por favor, instala Docker o descarga el binario manualmente"
        exit 1
    fi
    
    echo "Descargando binario para $ARCH..."
    curl -L "$BIN_URL" -o "$INSTALL_DIR/$BIN_NAME"
    chmod +x "$INSTALL_DIR/$BIN_NAME"
    
    echo "✅ Binario descargado en: $INSTALL_DIR/$BIN_NAME"
    echo ""
    echo "=== Iniciar servidor ==="
    echo ""
    echo "Para iniciar el servidor, ejecuta:"
    echo "  cd $INSTALL_DIR"
    echo "  ./$BIN_NAME"
    echo ""
    echo "Para ejecutar en background:"
    echo "  nohup ./$BIN_NAME > gemini-web.log 2>&1 &"
fi

echo ""
echo "=== Verificar funcionamiento ==="
echo ""
echo "Una vez iniciado el servidor, verifica que funciona con:"
echo "  curl http://localhost:4981/health"
echo ""
echo "O prueba una llamada:"
echo "  curl -X POST http://localhost:4981/openai/v1/chat/completions \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"model\": \"gemini-advanced\", \"messages\": [{\"role\": \"user\", \"content\": \"Hola!\"}]}'"
echo ""
echo "=== Configuración completada ==="
echo ""
echo "El servidor estará disponible en http://localhost:4981"
echo "ambxst detectará automáticamente los modelos disponibles."
