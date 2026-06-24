# Cómo Probar en iOS

## Opción 1: Simulador de iOS (Más fácil) ⚡

### Requisitos
- Xcode instalado (desde App Store o Apple Developer)
- Simulador de iOS disponible

### Pasos

1. **Abre un terminal en el proyecto:**
```bash
cd '/Users/valeriariera/arrowMaze-cliente copy'
```

2. **Verifica que tengas un simulador listo:**
```bash
xcrun simctl list devices
```
Deberías ver algo como: `iPhone 15 (77F4...) (Booted)` o similar.

3. **Si no hay uno activo, abre Xcode:**
```bash
open -a Simulator
```
Espera a que cargue, luego en Xcode:
- Device > Simulator > iPhone 15 (o el que prefieras)

4. **Ejecuta Flutter:**
```bash
flutter run
```

¡Listo! La app debería compilar y correr en el simulador.

### Durante el desarrollo
- Presiona `r` para hot reload (cambios rápidos)
- Presiona `R` para hot restart (más completo)
- Presiona `q` para salir

---

## Opción 2: Dispositivo iOS Real 📱

### Requisitos
- iPhone físico conectado por USB
- Xcode configurado con tu Apple ID
- Certificados de desarrollo válidos

### Pasos

1. **Conecta el iPhone y confía en la computadora:**
   - En el iPhone: Settings > Developer (o General > Trust This Computer)

2. **Ejecuta Flutter:**
```bash
flutter run
```

3. **Si pide seleccionar dispositivo:**
```bash
flutter devices
flutter run -d <device_id>
```

---

## Opción 3: Xcode (Control Total) 🎛️

Si necesitas más control o debugging:

```bash
cd '/Users/valeriariera/arrowMaze-cliente copy'
open ios/Runner.xcworkspace
```

Esto abre Xcode. Ahí puedes:
- Seleccionar el simulador/dispositivo en la esquina superior
- Presionar ▶️ (Play) para ejecutar
- Ver logs detallados
- Debuggear con breakpoints

---

## Troubleshooting

### "Flutter not found"
```bash
# Agregar Flutter al PATH (temporal)
export PATH="$PATH:`flutter/bin`"
```

O si necesitas permanente, edita `~/.zshrc`:
```bash
nano ~/.zshrc
# Agrega al final:
export PATH="$PATH:~/path/to/flutter/bin"
# Ctrl+X, Y, Enter
source ~/.zshrc
```

### "CocoaPods not available"
```bash
sudo gem install cocoapods
# o
brew install cocoapods
```

### "Pod install failed"
```bash
cd ios
rm -rf Pods Podfile.lock .symlinks/
cd ..
flutter clean
flutter pub get
flutter run
```

### "Xcode not configured"
```bash
sudo xcode-select --reset
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

---

## Estado de la App

✅ Todas las capas implementadas
✅ 83 tests pasando
✅ Estructura Flutter completa
✅ Listo para ejecutar

## Flujo esperado al iniciar

1. **SplashScreen** → carga y revisa autenticación
2. **LoginScreen** → si no está autenticado
3. **LevelSelectScreen** → si ya está autenticado
4. **GameScreen** → al seleccionar un nivel
5. **VictoryScreen/DefeatScreen** → según resultado

---

## Debugging

Para ver logs en tiempo real:
```bash
flutter run -v  # Verbose mode
```

Para conectar debugger:
- Presiona `D` durante `flutter run` para abrir DevTools
- O abre manualmente: http://localhost:9100

---

¡Listo! Prueba la app y reporta cualquier error. 🚀
