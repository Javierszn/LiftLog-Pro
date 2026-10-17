# LiftLog Pro

Aplicación Flutter para registrar rutinas de fuerza, ejercicios, marcas y progreso visual. Usa SQLite en Android/iOS y almacenamiento local del navegador en Web.

## Ejecutar en Chrome

```powershell
& "C:\src\flutter\bin\flutter.bat" run -d chrome
```

## Ejecutar en Android

```powershell
& "C:\src\flutter\bin\flutter.bat" run
```

## Compilar APK de Android

```powershell
& "C:\src\flutter\bin\flutter.bat" build apk --release
```

El APK se genera en `build/app/outputs/flutter-apk/app-release.apk`.

## Módulos

- Registro e inicio de sesión local.
- Resumen de actividad, meta semanal y volumen estimado.
- Rutinas por día con alta, consulta, edición y borrado por deslizamiento.
- Progreso visual con fotos capturadas y guardadas en el dispositivo.
- Perfil con meta semanal y cierre de sesión.

Los datos se guardan localmente en el dispositivo o navegador donde se creó la cuenta.
