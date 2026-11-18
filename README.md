
<h1 align="center">Studiary</h1>

<p align="center">
  <strong>Planifica. Estudia. Avanza.</strong><br>
  Una aplicación de organización académica que reúne agenda, asignaturas, apuntes y sesiones de estudio en un mismo lugar.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Mobile-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-Language-0175C2?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Supabase-Backend-3FCF8E?logo=supabase&logoColor=white" alt="Supabase">
  <img src="https://img.shields.io/badge/Android-App-3DDC84?logo=android&logoColor=white" alt="Android">
</p>

---

## Sobre el proyecto

**Studiary** es una aplicación móvil dirigida a estudiantes que quieren organizar sus estudios, centralizar sus materiales y hacer seguimiento de su progreso.

La aplicación está desarrollada con **Flutter y Dart**. Utiliza **Supabase** para la autenticación, la persistencia de datos y la sincronización entre dispositivos, combinada con almacenamiento local para conservar cambios y mejorar la continuidad de uso.

> **Estado del repositorio:** la aplicación móvil actual se encuentra en [`flutter_app/`](flutter_app/). La raíz del repositorio conserva una versión anterior basada en **Next.js y Capacitor** como referencia durante la transición. La versión Flutter es la implementación móvil principal documentada aquí.

## Funcionalidades

### Organización académica

- **Agenda y calendario:** vistas de mes, semana y año para consultar clases, exámenes, prácticas y otros eventos.
- **Horarios:** planificación semanal con perfiles de horario.
- **Asignaturas:** organización de materias, exámenes, calificaciones y apuntes asociados.
- **Inicio personalizado:** resumen de próximos eventos, accesos rápidos y objetivos.

### Estudio y seguimiento

- **Sesiones de concentración:** temporizador de estudio con posibilidad de pausar y reanudar.
- **Registro de actividad:** seguimiento del tiempo dedicado a estudiar.
- **Progreso:** consulta de estadísticas y evolución de las sesiones.
- **Recordatorios locales:** avisos de eventos y exámenes en Android.

### Apuntes y personalización

- **Cuaderno digital:** creación y edición de apuntes, con recuperación de borradores locales.
- **Archivos adjuntos:** soporte para documentos, imágenes, vídeos, enlaces y otros archivos.
- **Personalización visual:** temas y colores configurables.
- **Cuentas de usuario:** registro e inicio de sesión por correo electrónico o Google.

### Sincronización y monetización

- **Sincronización en la nube:** datos asociados a cada cuenta, con control de revisiones y tratamiento de cambios offline.
- **Almacenamiento privado:** archivos en Supabase Storage con políticas de acceso por usuario.
- **Monetización:** integración con Google AdMob y compras en Google Play para funcionalidades Premium.

## Tecnologías

| Área | Tecnologías |
| --- | --- |
| Aplicación móvil | Flutter, Dart, Material 3 |
| Autenticación | Supabase Auth, Google Sign-In |
| Base de datos y sincronización | Supabase, PostgreSQL |
| Archivos | Supabase Storage |
| Persistencia local | SharedPreferences |
| Notificaciones | flutter_local_notifications |
| Monetización | Google Mobile Ads, Google Play Billing |
| Pruebas | flutter_test |
| Plataforma de distribución | Android / Google Play |

## Estructura del repositorio

```text
Studiary/
├── flutter_app/                 # Aplicación móvil principal (Flutter/Dart)
│   ├── assets/                  # Logo, mascota y recursos visuales
│   ├── android/                 # Configuración nativa de Android
│   ├── lib/
│   │   ├── main.dart           # Arranque, navegación y pantallas
│   │   ├── app_state.dart      # Estado y sincronización de la aplicación
│   │   ├── models.dart         # Modelos de datos
│   │   ├── services.dart       # Autenticación, nube y monetización
│   │   ├── sync_merge.dart     # Combinación de cambios entre dispositivos
│   │   ├── focus_session.dart  # Temporizador de estudio
│   │   ├── notifications.dart  # Recordatorios locales
│   │   ├── subject_pages.dart  # Pantallas de asignaturas
│   │   └── notebook_page.dart  # Cuaderno y edición de apuntes
│   ├── test/                    # Pruebas automatizadas
│   └── pubspec.yaml            # Dependencias de Flutter
├── supabase/
│   ├── functions/               # Funciones de backend
│   ├── schema.sql               # Esquema y políticas iniciales
│   ├── release_sync.sql         # Sincronización
│   └── premium.sql              # Lógica de Premium
├── src/                         # Código de la versión web anterior
├── public/                      # Recursos de la versión anterior
└── README.md
```

## Instalación y ejecución

### Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) compatible con el SDK de Dart indicado en [`pubspec.yaml`](flutter_app/pubspec.yaml).
- Android Studio o VS Code con las herramientas de Flutter.
- Emulador Android o dispositivo físico.
- Proyecto de Supabase configurado, si se quiere utilizar autenticación y sincronización.

### 1. Clonar el repositorio

```bash
git clone https://github.com/Juanpareja02/Studiary.git
cd Studiary/flutter_app
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar Supabase

Crea un archivo **local** llamado `supabase.env.json` dentro de `flutter_app/`:

```json
{
  "SUPABASE_URL": "https://TU-PROYECTO.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "TU_CLAVE_PUBLICABLE"
}
```

El cliente usa estas variables mediante `--dart-define-from-file`. El archivo está excluido del control de versiones.

Para preparar un entorno propio hay que configurar Supabase Auth (correo/Google), la base de datos, las políticas RLS, el almacenamiento y las funciones de backend según [`flutter_app/README.md`](flutter_app/README.md) y los scripts de [`supabase/`](supabase/).

**Seguridad:** nunca incluyas claves `service_role`, `secret`, credenciales de firma ni secretos del servidor en el código cliente o en el repositorio.

### 4. Ejecutar la aplicación

```bash
flutter run --dart-define-from-file=supabase.env.json
```

### 5. Analizar y ejecutar las pruebas

```bash
flutter analyze
flutter test
```

Las pruebas incluyen componentes visuales, fiabilidad del temporizador, restauración de sesiones y resolución de determinados conflictos de sincronización.

### 6. Generar una compilación Android

Para pruebas:

```bash
flutter build apk --debug --dart-define-from-file=supabase.env.json
```

Para una publicación en Google Play:

```bash
flutter build appbundle --release --dart-define-from-file=supabase.env.json
```

La compilación `release` requiere configurar previamente la **firma de Android** en `android/key.properties` con una clave de subida válida. No compartas el keystore ni sus contraseñas.

## Decisiones técnicas destacadas

- **Flutter:** base de código compartida para el desarrollo de interfaces móviles; la configuración de distribución actualmente documentada está centrada en Android.
- **Supabase:** autenticación y persistencia en PostgreSQL, con archivos privados por cuenta.
- **Persistencia local y sincronización:** almacenamiento de cambios locales y reconciliación de actualizaciones para reducir la pérdida de datos al alternar dispositivos.
- **Temporizador resiliente:** cálculo basado en tiempo real para evitar que la suspensión de la aplicación altere la duración de la sesión.
- **Pruebas automatizadas:** casos para la sincronización, los borradores y la continuidad de sesiones.

## Seguridad y privacidad

Los datos se asocian al usuario autenticado. El proyecto incorpora políticas **Row Level Security (RLS)** para restringir el acceso a registros y archivos, además de funciones de backend para operaciones como eliminación de cuenta y verificación de compras.

La configuración final de permisos, proveedores OAuth, políticas y secretos debe revisarse antes de desplegar un entorno nuevo.

## Evolución del proyecto

Studiary comenzó con una implementación web basada en Next.js y Capacitor. Posteriormente se desarrolló una aplicación en Flutter para disponer de una base móvil más específica y facilitar su evolución.

Esta transición permite mostrar experiencia en:

- Desarrollo móvil con Flutter y Dart.
- Integración de autenticación y servicios en la nube.
- Persistencia local y sincronización de información.
- Pruebas, depuración y preparación de versiones Android.

## Autor

**Juan Álvaro Pareja**

- [GitHub](https://github.com/Juanpareja02)
- [Portfolio](https://juan-alvaro-pareja.vercel.app/)

---

<p align="center"><strong>Studiary — Planifica. Estudia. Avanza.</strong></p>
