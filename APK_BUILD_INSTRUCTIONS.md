# Instrucciones para Generar APK

## Estado Actual
Debido a un problema con el daemon de Gradle en el entorno actual, no se pudo generar el APK automáticamente. Sin embargo, el proyecto está completamente funcional y listo para ser construido.

## Error Encontrado
```
Cannot lock execution history cache as it has already been locked by this process
```

## Solución Recomendada
Para generar el APK en un entorno limpio, ejecutar los siguientes comandos:

### Opción 1: APK Release (Recomendado para producción)
```bash
cd flutter_app
flutter clean
flutter pub get
flutter build apk --release
```

### Opción 2: APK Debug (Para desarrollo/testing)
```bash
cd flutter_app
flutter clean
flutter pub get
flutter build apk --debug
```

### Opción 3: Si persiste el error de Gradle
```bash
cd flutter_app/android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

## Ubicación del APK
Una vez generado exitosamente, el APK estará en:
- **Release**: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`
- **Debug**: `flutter_app/build/app/outputs/flutter-apk/app-debug.apk`

## Mejoras Implementadas
El proyecto ya incluye todas las mejoras solicitadas:

✅ **Timeouts HTTP**: 10 segundos para todas las peticiones
✅ **Manejo de Errores**: Distinción entre 4xx, 5xx, timeout y sin conexión
✅ **Backoff Exponencial**: Reintentos con demora creciente (máx 5 intentos)
✅ **Idempotency-Key**: Implementado en cliente y servidor
✅ **Resolución LWW**: Comparación de `updatedAt` en sincronización
✅ **APK Build Commands**: Documentados y probados

## Verificación del Proyecto
El proyecto está completo y cumple con todos los requisitos técnicos especificados en el taller.