# Gemini Web to API - Integración con ambxst

Esta integración permite usar tu cuenta de **Google AI Pro** directamente en el asistente de ambxst, sin necesidad de API keys.

## 🎯 ¿Qué es esto?

Un servidor local que convierte la interfaz web de Gemini en una API REST, usando las cookies de tu navegador. Esto te permite:

- ✅ Usar tu cuenta de Google AI Pro
- ✅ Mantener la UI nativa del asistente de ambxst
- ✅ Soporte completo: streaming, attachments, function calling
- ✅ Sin problemas de ventanas/PWA en Hyprland
- ✅ Funciona en multipantalla sin issues

## 🚀 Instalación Rápida

```bash
cd /home/cristiansrc/.local/src/ambxst
chmod +x scripts/install_gemini_web.sh
./scripts/install_gemini_web.sh
```

El instalador te guiará paso a paso:
1. Detectará si tienes Docker/Podman o usará binario nativo
2. Te pedirá las cookies de tu navegador
3. Configuraré el servidor automáticamente
4. Iniciará el servicio (con systemd si usas binario)

## 📋 Extracción de Cookies

Antes de instalar, necesitas extraer 2 cookies de tu navegador:

1. Abre **Brave/Chrome** y ve a https://gemini.google.com
2. Inicia sesión con tu cuenta de Google
3. Presiona **F12** para abrir Developer Tools
4. Ve a **Application** → **Storage** → **Cookies** → `https://gemini.google.com`
5. Copia los valores de:
   - `__Secure-1PSID`
   - `__Secure-1PSIDTS`

## 🎮 Uso en ambxst

Una vez instalado el servidor:

1. **Reinicia ambxst** (o recarga la shell)
2. Abre el **asistente** (shortcut por defecto)
3. Haz clic en el **selector de modelos** (abajo del chat)
4. Selecciona **"Gemini Advanced (Web)"**
5. ¡Listo! Ya estás usando tu cuenta de Google AI Pro

## 🔧 Configuración

El archivo de configuración está en `~/.local/share/gemini-web-to-api/.env`:

```bash
# Cookies de autenticación
GEMINI_1PSID=tu_cookie_aqui
GEMINI_1PSIDTS=tu_cookie_aqui

# Rotación de cookies (minutos)
GEMINI_REFRESH_INTERVAL=60

# Rate limiting conservador
RATE_LIMIT_ENABLED=true
RATE_LIMIT_MAX_REQUESTS=5
```

### Parámetros recomendados para uso personal:

- `GEMINI_REFRESH_INTERVAL=60` - Rotar cookies cada hora
- `RATE_LIMIT_MAX_REQUESTS=5` - Máximo 5 requests por minuto
- `GEMINI_MAX_RETRIES=2` - No insistir demasiado si falla

## 📊 Comandos Útiles

### Si usas Docker/Podman:

```bash
# Ver logs
docker logs -f gemini-web-to-api

# Reiniciar servidor
cd ~/.local/share/gemini-web-to-api
docker compose restart

# Detener servidor
docker compose down

# Iniciar servidor
docker compose up -d
```

### Si usas binario nativo con systemd:

```bash
# Ver logs
journalctl --user -u gemini-web-to-api@$(whoami).service -f

# Reiniciar servidor
systemctl --user restart gemini-web-to-api@$(whoami).service

# Ver estado
systemctl --user status gemini-web-to-api@$(whoami).service

# Detener servidor
systemctl --user stop gemini-web-to-api@$(whoami).service

# Deshabilitar inicio automático
systemctl --user disable gemini-web-to-api@$(whoami).service
```

## 🔐 Seguridad

### ¿Es seguro?

✅ **Sí, para uso personal** con las siguientes consideraciones:

- Las cookies se almacenan localmente con permisos `0600` (solo tú)
- El servidor solo escucha en `localhost` (no expuesto a la red)
- Rate limiting activado para evitar patrones sospechosos
- Tu patrón de uso conversacional es indistinguible de un humano

### Riesgos

⚠️ **Técnicamente viola los ToS de Google**, pero:

- Google no valida telemetría estrictamente (Brave funciona sin ella)
- Tu patrón de uso es bajo y conversacional
- No hay reportes de bloqueos por uso similar
- El proyecto es activo y mantenido

### Mitigaciones implementadas:

- ✅ User-Agent realista
- ✅ Cookie rotation automática
- ✅ Rate limiting conservador
- ✅ Headers correctos
- ✅ Timing con jitter (no perfectamente regular)

## 🐛 Troubleshooting

### El servidor no inicia

```bash
# Verificar que el puerto 4981 está libre
lsof -i :4981

# Ver logs del servicio
journalctl --user -u gemini-web-to-api@$(whoami).service -n 50

# Probar manualmente
cd ~/.local/share/gemini-web-to-api
./.env
./gemini-web-to-api-linux-amd64
```

### Las cookies expiran

Las cookies de Google pueden expirar después de varios meses. Si ves errores de autenticación:

1. Extrae nuevas cookies del navegador
2. Actualiza `~/.local/share/gemini-web-to-api/.env`
3. Reinicia el servidor:
   ```bash
   systemctl --user restart gemini-web-to-api@$(whoami).service
   ```

### ambxst no detecta el modelo

1. Verifica que el servidor está corriendo:
   ```bash
   curl http://localhost:4981/health
   ```

2. Recarga ambxst:
   ```bash
   quickshell reload
   ```

3. Verifica los logs de ambxst:
   ```bash
   journalctl --user -u quickshell -f
   ```

### Error "Empty response from API"

Puede ser que:
- Las cookies expiraron → Actualízalas
- El servidor no está corriendo → Verifica con `systemctl --user status`
- Rate limit alcanzado → Espera un minuto

## 📈 Monitoreo

Para ver estadísticas de uso:

```bash
# Logs en tiempo real
journalctl --user -u gemini-web-to-api@$(whoami).service -f

# Contar requests por día
journalctl --user -u gemini-web-to-api@$(whoami).service --since today | grep "POST /gemini" | wc -l
```

## 🔄 Actualización

### Docker/Podman:

```bash
cd ~/.local/share/gemini-web-to-api
docker compose pull
docker compose up -d
```

### Binario nativo:

```bash
# Descargar nueva versión
cd ~/.local/share/gemini-web-to-api
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    BIN_NAME="gemini-web-to-api-linux-amd64"
elif [ "$ARCH" = "aarch64" ]; then
    BIN_NAME="gemini-web-to-api-linux-arm64"
fi
curl -L "https://github.com/ntthanh2603/gemini-web-to-api/releases/latest/download/$BIN_NAME" -o "$BIN_NAME"
chmod +x "$BIN_NAME"
systemctl --user restart gemini-web-to-api@$(whoami).service
```

## 📚 Recursos

- **Proyecto original**: https://github.com/ntthanh2603/gemini-web-to-api
- **Documentación API**: http://localhost:4981/docs (una vez iniciado)
- **Soporte**: Abre un issue en el repositorio original

## ⚖️ Legal

Este proyecto usa ingeniería inversa para acceder a Gemini. **Técnicamente viola los ToS de Google**, pero:

- Es para uso personal
- Volumen bajo y conversacional
- No hay reportes de bloqueos
- Similar a usar Brave (sin telemetría)

**Úsalo bajo tu responsabilidad.**

## 🤝 Contribuciones

Si encuentras bugs o tienes mejoras, abre un PR en el repositorio de ambxst.

---

**Desarrollado para ambxst** - Usa tu Google AI Pro donde quieras 🚀
