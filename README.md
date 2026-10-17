# LiftLog Pro

## Revisión 1: ejercicios

Esta versión inicial permite consultar una lista de ejercicios de ejemplo, agregar ejercicios, editar sus datos, abrir una pantalla de detalle y eliminar elementos deslizando la tarjeta.

El flujo usa conceptos que trabajamos en clase: `StatefulWidget`, `setState`, `ListView.builder`, `AlertDialog`, `DropdownButton`, `Dismissible`, `SnackBar` y `Navigator.push`.

Los datos se guardan únicamente mientras la aplicación está abierta. Al reiniciarla, vuelven los ejemplos iniciales. La persistencia, el inicio de sesión y registro, la cámara, el resumen y el perfil quedan para las siguientes etapas de la propuesta.

## Ejecutar

En Chrome:

```powershell
& "C:\src\flutter\bin\flutter.bat" run -d chrome
```

En Android:

```powershell
& "C:\src\flutter\bin\flutter.bat" run
```

## Revisión estática

```powershell
& "C:\src\flutter\bin\flutter.bat" analyze --no-pub
```