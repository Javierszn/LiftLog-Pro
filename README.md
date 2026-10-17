# LiftLog Pro

## Primera revision

La version muestra las cinco secciones principales planteadas para LiftLog Pro, mas el detalle de un ejercicio:

- Acceso y registro de muestra con validacion basica de campos.
- Dashboard con accesos a los modulos.
- Ejercicios: alta, consulta, edicion y eliminacion por deslizamiento.
- Detalle de cada ejercicio.
- Progreso visual, preparado para integrar la camara.
- Perfil con una meta semanal temporal.

El acceso es una demostracion y no guarda cuentas. El CRUD de ejercicios funciona en memoria; los cambios se reinician al cerrar la aplicacion. La pantalla de progreso es navegable, pero todavia no captura fotos. La autenticacion local, SQLite y el guardado permanente de preferencias quedan para siguientes etapas.

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