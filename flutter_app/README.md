# Studiary Android en Flutter

Esta es la nueva aplicación Android de Studiary. Está hecha con Flutter y usa:

- Supabase Auth para cuentas por correo y Google.
- Supabase Postgres para sincronizar los datos de cada usuario.
- Supabase Storage para documentos, imágenes y vídeos privados (máximo 50 MB por archivo).
- AdMob y Google Play Billing para monetización.

## Configurar Supabase

El proyecto Supabase de producción de Studiary ya está creado y configurado en la región `eu-west-3`. El archivo local `supabase.env.json` contiene únicamente la URL y la clave publishable necesarias para conectar la app.

1. Si se prepara otro entorno, aplica `../supabase/schema.sql`, `../supabase/release_sync.sql` y `../supabase/premium.sql`, en ese orden.
2. Mantén desplegadas `delete-account` y `verify-play-purchase`, ambas con JWT obligatorio.
3. Mantén activos Email/Password y Google en Authentication > Providers.
4. Configura el cliente OAuth web de Google y el cliente Android con el paquete `com.studiary.app`.
5. Compila pasando el archivo local `supabase.env.json` (ya preparado para producción):

```powershell
flutter pub get
flutter run --dart-define-from-file=supabase.env.json
```

La clave publishable puede estar en la aplicación. No pongas nunca una clave `secret` o `service_role` en Flutter.

Supabase Storage tiene cuotas y límites propios. Esta migración evita depender de Firebase Storage, pero no significa almacenamiento ilimitado sin coste.

## Migración de datos existentes

La app conserva la lectura de los nombres de datos de la versión anterior para facilitar la transición. Los usuarios de Firebase no se convierten automáticamente en usuarios de Supabase: sus credenciales y sus UID pertenecen a sistemas distintos. Antes de retirar Firebase hay que decidir una migración de cuentas y de archivos existentes.

Los archivos nuevos se guardan en el bucket privado `note-files` con rutas `users/{uid}/notes/{noteId}/{fileName}`. Las políticas RLS impiden que un usuario vea los archivos de otra cuenta.

## Ejecutar y compilar

Desde `flutter_app`:

```powershell
flutter pub get
flutter test
flutter analyze
flutter build apk --debug
flutter build appbundle --release --dart-define-from-file=supabase.env.json
```

El APK de comprobación queda en `build/app/outputs/flutter-apk/app-debug.apk`. Para Play Store se debe subir el AAB firmado, no el APK de debug.

## Firma de Play

La clave de subida encontrada en el equipo es `F:\Keys\studiary-upload`. Es un almacén PKCS12 válido con alias `studiary-upload`.

El archivo local `android/key.properties` ya está configurado y está ignorado por Git. Nunca lo subas al repositorio ni compartas su contraseña. La configuración release se detiene si falta la clave para evitar generar un AAB que no pueda actualizar la aplicación publicada.

## Monetización

- El banner usa unidades reales en producción. Para pruebas, compila con `--dart-define=USE_TEST_ADS=true`; debug también usa anuncios de prueba.
- Los intersticiales no se muestran al terminar una sesión de estudio.
- Premium usa el producto único no consumible `studiary_premium_lifetime`.
  La app muestra el precio localizado que devuelve Google Play (2,99 € en la cuenta de prueba española), sin precios incrustados.
- Los productos antiguos mensual y anual no se ofrecen de nuevo, pero se
  reconocen al restaurar compras de usuarios que ya los adquirieron.
- La función `verify-play-purchase` valida los recibos con la API de Google Play y vincula cada compra a una única cuenta de Studiary.
- `PLAY_SERVICE_ACCOUNT_JSON` debe existir solo como secreto de Supabase. Nunca se incluye en Flutter, Git ni el AAB.
- `play_purchases` es accesible únicamente desde el servidor; cada usuario solo puede consultar su propio `premium_entitlements`, nunca escribirlo.
- Un pago pendiente o no verificado no activa Premium. Solo se confirma a Google una compra verificada; la compra vitalicia no se consume.
- Configura una cuenta de tester de licencias para comprobar compras sin dinero real. Una instalación USB normal puede ser rechazada por Google Play Billing.

## Fiabilidad y cuaderno

- Los cambios se guardan localmente por cuenta y se sincronizan con control de revisión para evitar sobrescribir cambios independientes de otro dispositivo.
- El temporizador persiste la sesión y calcula el tiempo transcurrido por reloj, incluidas las interrupciones de la aplicación.
- El cuaderno tiene editor, herramientas de formato, vista previa y recuperación de borradores locales. Guardar publica el apunte en la cuenta; un borrador todavía no está sincronizado.
- Los vídeos se reproducen dentro de la app. Los documentos se abren con una aplicación compatible del dispositivo.
- Los adjuntos son privados; su eliminación pendiente se reintenta después de sincronizar la eliminación del apunte.
- Las pruebas están en `test/`. Las reglas del servidor se prueban desde la raíz con `node --experimental-strip-types --test supabase/functions/verify-play-purchase/purchase_status.test.ts`.

La carpeta Next.js/Capacitor original se conserva en la raíz como respaldo durante la transición. La versión Flutter es la candidata para sustituirla en la publicación Android.
