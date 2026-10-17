# LiftLog Pro

## Primera revision

Esta version muestra el flujo principal de la propuesta:

- Dashboard con accesos a los modulos.
- Lista de ejercicios con alta, consulta, edicion y eliminacion por deslizamiento.
- Detalle de cada ejercicio.
- Pantalla de progreso visual preparada para integrar la camara.
- Perfil con una meta semanal temporal.

El CRUD de ejercicios funciona en memoria; los cambios se reinician al cerrar la aplicacion. La pantalla de progreso es una maqueta navegable y todavia no captura fotos. El inicio de sesion, SQLite y el guardado permanente de preferencias quedan para siguientes etapas.

El codigo de esta revision usa `StatefulWidget`, `setState`, `ListView.builder`, `AlertDialog`, `DropdownButton`, `Dismissible`, `SnackBar` y `Navigator.push`, patrones practicados en clase.

## Ejecutar en Chrome

```powershell
& "C:\src\flutter\bin\flutter.bat" run -d chrome
```

## Ejecutar en Android

```powershell
& "C:\src\flutter\bin\flutter.bat" run
```

## Analisis estatico

```powershell
& "C:\src\flutter\bin\flutter.bat" analyze --no-pub
```