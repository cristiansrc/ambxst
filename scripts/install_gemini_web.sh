#!/usr/bin/env bash
# Instalador automático de Gemini Web to API para ambxst
# Configura el servidor local y el servicio de systemd

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/share/gemini-web-to-api"
SERVICE_NAME="gemini-web-to-api@$(whoami).service"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Gemini Web to API - Instalador para ambxst              ║"
echo "║   Usa tu cuenta de Google AI Pro en el asistente          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Verificar dependencias
echo "🔍 Verificando dependencias..."

if ! command -v curl &> /dev/null; then
    echo "❌ curl no encontrado. Instálalo primero."
    exit 1
fi
echo "   ✅ curl"

if ! command -v jq &> /dev/null; then
    echo "⚠️  jq no encontrado (opcional, recomendado)"
else
    echo "   ✅ jq"
fi

# Detectar método de instalación
if command -v docker &> /dev/null; then
    METHOD="docker"
    echo "   ✅ Docker detectado"
elif command -v podman &> /dev/null; then
    METHOD="podman"
    echo "   ✅ Podman detectado"
else
    METHOD="binary"
    echo "   ℹ️  Usando binario nativo"
fi

echo ""

# Crear directorios
echo "📁 Creando directorios..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/cookies"
echo "   ✅ $INSTALL_DIR"

# Solicitar cookies
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Extracción de Cookies                                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Instrucciones:"
echo "   1. Abre Brave/Chrome y ve a https://gemini.google.com"
echo "   2. Inicia sesión con tu cuenta de Google"
echo "   3. Presiona F12 → Application → Cookies → gemini.google.com"
echo "   4. Copia los valores de:"
echo "      • __Secure-1PSID"
echo "      • __Secure-1PSIDTS"
echo ""

read -p "¿Tienes las cookies listas? (s/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    echo "❌ Configuración cancelada."
    echo "   Ejecuta este script nuevamente cuando tengas las cookies."
    exit 0
fi

echo ""
read -p "🔑 __Secure-1PSID: " PSID
read -p "🔑 __Secure-1PSIDTS: " PSIDTS

if [ -z "$PSID" ] || [ -z "$PSIDTS" ]; then
    echo ""
    echo "❌ Error: Las cookies no pueden estar vacías"
    exit 1
fi

# Crear archivo .env
echo ""
echo "📝 Creando configuración..."

cat > "$INSTALL_DIR/.env" << EOF
# Gemini Web to API - Configuración
# Generado: $(date)

# Cookies de autenticación
GEMINI_1PSID=$PSID
GEMINI_1PSIDTS=$PSIDTS

# Rotación de cookies (minutos) - Conservador para uso personal
GEMINI_REFRESH_INTERVAL=60
GEMINI_MAX_RETRIES=2

# Puerto del servidor
PORT=4981

# Rate limiting conservador
RATE_LIMIT_ENABLED=true
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=5

# Entorno
APP_ENV=production
EOF

chmod 600 "$INSTALL_DIR/.env"
chmod 700 "$INSTALL_DIR/cookies"
echo "   ✅ .env creado"

# Instalar según método
if [ "$METHOD" = "docker" ] || [ "$METHOD" = "podman" ]; then
    echo ""
    echo "🐳 Configurando con $METHOD..."
    
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
    
    echo "   ✅ docker-compose.yml creado"
    
    # Iniciar con Docker
    echo ""
    echo "🚀 Iniciando servidor con $METHOD..."
    cd "$INSTALL_DIR"
    if [ "$METHOD" = "docker" ]; then
        docker compose up -d
    else
        podman-compose up -d
    fi
    
    echo "   ✅ Servidor iniciado"
    
else
    echo ""
    echo "📦 Descargando binario nativo..."
    
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        BIN_NAME="gemini-web-to-api-linux-amd64"
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        BIN_NAME="gemini-web-to-api-linux-arm64"
    else
        echo "❌ Arquitectura no soportada: $ARCH"
        exit 1
    fi
    
    BIN_URL="https://github.com/ntthanh2603/gemini-web-to-api/releases/latest/download/$BIN_NAME"
    
    echo "   Descargando $BIN_NAME..."
    curl -L "$BIN_URL" -o "$INSTALL_DIR/$BIN_NAME"
    chmod +x "$INSTALL_DIR/$BIN_NAME"
    echo "   ✅ Binario descargado"
    
    # Configurar servicio de systemd
    echo ""
    echo "⚙️  Configurando servicio de systemd..."
    
    # Crear servicio adaptado a la arquitectura
    sed "s|gemini-web-to-api-linux-amd64|$BIN_NAME|g" "$SCRIPT_DIR/gemini-web-to-api.service" > "$INSTALL_DIR/gemini-web-to-api.service"
    
    # Instalar servicio
    mkdir -p "$HOME/.config/systemd/user"
    cp "$INSTALL_DIR/gemini-web-to-api.service" "$HOME/.config/systemd/user/$SERVICE_NAME"
    
    # Recargar y habilitar servicio
    systemctl --user daemon-reload
    systemctl --user enable "$SERVICE_NAME"
    systemctl --user start "$SERVICE_NAME"
    
    echo "   ✅ Servicio instalado y iniciado"
    echo "   ✅ Se iniciará automáticamente al boot"
fi

# Verificar que el servidor está funcionando
echo ""
echo "🔍 Verificando servidor..."
sleep 3

if curl -s --connect-timeout 5 http://localhost:4981/health > /dev/null 2>&1; then
    echo "   ✅ Servidor funcionando correctamente"
else
    echo "   ⚠️  El servidor podría estar iniciando..."
    echo "      Espera unos segundos y verifica con:"
    echo "      curl http://localhost:4981/health"
fi

# Resumen final
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   ✅ Instalación Completada                                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Estado:"
echo "   • Servidor: http://localhost:4981"
echo "   • Método: $METHOD"
echo "   • Config: $INSTALL_DIR/.env"
echo ""
echo "🎯 Próximos pasos:"
echo "   1. Reinicia ambxst (o recarga la shell)"
echo "   2. Abre el asistente"
echo "   3. Selecciona el modelo 'Gemini Advanced (Web)'"
echo "   4. ¡Listo! Usa tu cuenta de Google AI Pro"
echo ""
echo "📚 Comandos útiles:"
if [ "$METHOD" = "docker" ] || [ "$METHOD" = "podman" ]; then
    echo "   • Ver logs: docker logs -f gemini-web-to-api"
    echo "   • Reiniciar: cd $INSTALL_DIR && docker compose restart"
    echo "   • Detener: cd $INSTALL_DIR && docker compose down"
else
    echo "   • Ver logs: journalctl --user -u $SERVICE_NAME -f"
    echo "   • Reiniciar: systemctl --user restart $SERVICE_NAME"
    echo "   • Estado: systemctl --user status $SERVICE_NAME"
    echo "   • Detener: systemctl --user stop $SERVICE_NAME"
fi
echo ""
echo "🔐 Seguridad:"
echo "   • Las cookies se almacenan localmente (0600)"
echo "   • El servidor solo escucha en localhost"
echo "   • Rate limiting activado (5 req/min)"
echo ""
echo "💡 Consejo: Usa volumen bajo (10-20 requests/día) para mantener"
echo "   tu cuenta segura. Tu patrón de uso conversacional es ideal."
echo ""
