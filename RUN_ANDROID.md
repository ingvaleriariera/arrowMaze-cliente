# Guía: Correr Arrow Maze en Android físico (macOS)

Guía paso a paso para levantar el cliente Flutter (`arrowMaze-cliente`) en un dispositivo Android físico conectado por USB-C, y conectarlo correctamente al backend NestJS local.

---

## 1. Verificar que `adb` esté disponible en la terminal

`adb` (Android Debug Bridge) viene incluido con el Android SDK, pero no siempre está en el `PATH` del sistema.

**Probar:**
```bash
adb devices
```

**Si da error `zsh: command not found: adb`:**

### 1.1 Buscar dónde está instalado el SDK
```bash
echo $ANDROID_HOME
ls ~/Library/Android/sdk/platform-tools/
```
La ruta típica en Mac es:
```
~/Library/Android/sdk/platform-tools/adb
```

### 1.2 Agregar `adb` al PATH (temporal, solo esta sesión)
```bash
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"
adb devices
```

### 1.3 Dejarlo permanente (agregar al `.zshrc`)
```bash
echo 'export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"' >> ~/.zshrc
source ~/.zshrc
```

### 1.4 Confirmar que el dispositivo aparece
```bash
adb devices
```
Debería listar el dispositivo conectado por USB-C. Si aparece como `unauthorized`, revisar el celular por un popup pidiendo autorizar "Allow USB debugging" y aceptarlo.

---

## 2. Diagnosticar pérdida de conexión ("Lost connection to device")

Si al correr `flutter run` la app se instala pero luego aparece `Lost connection to device`, revisar en este orden:

1. **Cable/puerto USB-C**: usar un cable de datos (no solo de carga) y probar otro puerto.
2. **Reiniciar el servidor ADB:**
   ```bash
   adb kill-server
   adb start-server
   adb devices
   ```
3. **Revisar si la app crasheó** (en vez de perder conexión por USB):
   ```bash
   adb logcat -d | grep -A 20 "FATAL EXCEPTION"
   ```

---

## 3. Configurar la IP del backend para el dispositivo físico

El emulador Android puede usar `10.0.2.2` para apuntar a `localhost` de la Mac, pero un **dispositivo físico no puede usar `localhost` ni `10.0.2.2`** — necesita la IP real de la Mac en la red WiFi local.

### 3.1 Obtener la IP actual de la Mac
```bash
ipconfig getifaddr en0
```
Si no devuelve nada, probar:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```
Esto lista todas las IPs IPv4 activas. Tomar la que corresponde a la red WiFi (ej: `192.168.0.3`).

> ⚠️ **Importante:** esta IP puede cambiar cada vez que la Mac se conecta a una red WiFi distinta (casa, universidad, etc.), o incluso al reconectarse a la misma red. Hay que repetir este paso si vuelve a fallar la conexión.

### 3.2 Confirmar que el teléfono está en la misma red WiFi que la Mac
En el Android: Ajustes → WiFi → confirmar que está conectado a la misma red (mismo rango de IP, ej: `192.168.0.x`).

> El cable USB-C se usa solo para debugging (ADB) — el tráfico HTTP de la app va por WiFi, no por el cable.

### 3.3 Probar que la Mac responde en esa IP
```bash
ping 192.168.0.3
```
(reemplazar por la IP obtenida en el paso 3.1)

Si da `Request timeout`, la IP está mal o hay un firewall bloqueando.

### 3.4 Actualizar la IP en el cliente Flutter
Buscar dónde está configurada la base URL del backend:
```bash
grep -r "172.16.0.146" . --include="*.dart"
```
(reemplazar por la IP vieja que se esté usando)

Actualizar el archivo encontrado (ej: `api_config.dart`, `constants.dart`) con la IP nueva.

---

## 4. Confirmar que el backend NestJS escuche en todas las interfaces

Por defecto, si `main.ts` solo tiene `app.listen(3000)`, puede terminar escuchando únicamente en IPv6 o en `localhost`, bloqueando el acceso desde el celular.

### 4.1 Revisar la configuración actual
```bash
grep -A 2 "app.listen" src/main.ts
```

### 4.2 Asegurar que escuche en `0.0.0.0` (todas las interfaces IPv4)
```typescript
await app.listen(3000, '0.0.0.0');
```

### 4.3 Verificar qué proceso está escuchando en el puerto 3000
```bash
lsof -i :3000
```
Confirmar que aparece como `LISTEN` y en `IPv4` (no solo `IPv6`).

### 4.4 Reiniciar el backend
Después de cualquier cambio en `main.ts`, reiniciar el servidor NestJS para que tome efecto.

---

## 5. Correr la app

```bash
flutter run
```

Con el dispositivo Android conectado por USB-C, autorizado en ADB, y en la misma red WiFi que la Mac con la IP correcta configurada en el cliente.

---

## Checklist rápido para la próxima vez que falle la conexión

- [ ] `adb devices` muestra el dispositivo (no vacío, no `unauthorized`)
- [ ] IP actual de la Mac: `ipconfig getifaddr en0`
- [ ] IP del paso anterior coincide con la configurada en el cliente Flutter
- [ ] Teléfono conectado a la misma red WiFi que la Mac
- [ ] `ping <IP de la Mac>` responde sin timeout
- [ ] Backend NestJS escuchando en `0.0.0.0:3000` (no solo IPv6/localhost)
- [ ] `lsof -i :3000` confirma que el backend está corriendo

---

*Nota: esto es un workaround temporal para desarrollo local. Está identificado como tarea pendiente el deploy del backend a un hosting público (Railway o Render) para eliminar la dependencia de la IP local.*