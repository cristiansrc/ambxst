# Copia de Seguridad y Restauración de Ambxst

Este directorio contiene una copia de seguridad de tu configuración personalizada de **Ambxst** (el shell para Hyprland). Puedes usar este respaldo para restaurar tu interfaz personalizada después de formatear tu PC o reinstalar el sistema.

---

## 🚀 Guía de Instalación y Restauración desde Cero

Sigue estos pasos una vez que tengas **Hyprland** instalado y funcionando en tu nuevo sistema.

### Paso 1: Instalar Ambxst
Abre una terminal y ejecuta el script oficial de instalación de Ambxst:

```bash
curl -L get.axeni.de/ambxst | sh
```

### Paso 2: Integrar Ambxst con tu Compositor (Hyprland)
Una vez que el comando `ambxst` esté disponible en tu terminal, realiza la integración con Hyprland:

```bash
ambxst install hyprland
```

*Nota: Esto generará los archivos de configuración por defecto de Ambxst en `~/.config/ambxst` y `~/.local/share/ambxst`.*

### Paso 3: Restaurar tu Copia de Seguridad (Tus Personalizaciones)
Para restaurar todos tus atajos (`binds.json`), temas, barra de estado y comportamiento del compositor que tenías guardados:

1. **Asegúrate de que Ambxst no esté ejecutándose:**
   ```bash
   ambxst quit
   # O también mediante axctl:
   # axctl system exit
   ```

2. **Copiar las carpetas respaldadas a sus rutas originales:**
   Desde este directorio del proyecto (`/home/cristiansrc/Documentos/Proyectos/ambxst`), ejecuta:

   ```bash
   # Restaurar la configuración principal (temas, atajos, etc.)
   cp -r config/. ~/.config/ambxst/

   # Restaurar los datos locales y estados de Ambxst
   cp -r share/. ~/.local/share/ambxst/
   ```

### Paso 4: Iniciar / Recargar Ambxst
Para aplicar y levantar de nuevo la interfaz con tus configuraciones:

```bash
ambxst reload
```

¡Listo! Tu shell de Ambxst debería verse y funcionar exactamente igual que antes.
