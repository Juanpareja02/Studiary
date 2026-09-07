import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Política de privacidad | Studiary',
  description: 'Información sobre el uso de datos en Studiary.',
};

export default function PrivacyPage() {
  return (
    <main className="min-h-screen bg-slate-50 px-6 py-12 text-slate-900">
      <article className="mx-auto max-w-3xl rounded-3xl bg-white p-8 shadow-sm ring-1 ring-slate-200 sm:p-12">
        <p className="mb-3 text-sm font-semibold uppercase tracking-[0.2em] text-blue-600">
          Studiary
        </p>
        <h1 className="mb-3 font-[family-name:var(--font-poppins)] text-3xl font-bold sm:text-4xl">
          Política de privacidad
        </h1>
        <p className="mb-10 text-sm text-slate-500">Última actualización: 5 de septiembre de 2026</p>

        <div className="space-y-8 text-[15px] leading-7 text-slate-700">
          <section>
            <h2 className="mb-2 text-xl font-semibold text-slate-950">1. Responsable</h2>
            <p>
              Studiary es una aplicación desarrollada por Juan Álvaro Pareja Pedrero. Para
              cualquier consulta sobre privacidad o para solicitar la eliminación de tus datos,
              escribe a{' '}
              <a className="font-medium text-blue-600 underline" href="mailto:pacuan2417@gmail.com">
                pacuan2417@gmail.com
              </a>
              .
            </p>
          </section>

          <section>
            <h2 className="mb-2 text-xl font-semibold text-slate-950">2. Datos que usamos</h2>
            <p>
              Cuando creas una cuenta podemos tratar tu correo electrónico, nombre y foto de
              perfil proporcionados por Google, además de los datos que guardes en el planificador:
              eventos, asignaturas, objetivos, notas, horarios y estadísticas de estudio. Si
              adjuntas un documento, una imagen o un vídeo, guardamos también ese archivo en
              almacenamiento privado. Los enlaces y el contenido del cuaderno forman parte de tus notas.
            </p>
            <p className="mt-3">
              Para validar Premium conservamos en el servidor el identificador del producto, el
              token de compra de Google Play y el estado de acceso, vinculados a tu cuenta. No
              recibimos el número de tu tarjeta ni sus datos de seguridad. Google Play procesa el pago.
              Los borradores del cuaderno y la sesión de estudio en curso se guardan en el dispositivo;
              las notas guardadas y las sesiones finalizadas se sincronizan con tu cuenta.
            </p>
            <p className="mt-3">
              La aplicación y los proveedores de publicidad pueden tratar información técnica del
              dispositivo, identificadores de publicidad, diagnósticos y datos de uso necesarios
              para mostrar y medir anuncios, prevenir abusos y mejorar el servicio.
            </p>
          </section>

          <section>
            <h2 className="mb-2 text-xl font-semibold text-slate-950">3. Para qué los usamos</h2>
            <ul className="list-disc space-y-1 pl-6">
              <li>Crear y proteger tu cuenta e iniciar sesión con Google o correo.</li>
              <li>Sincronizar tus datos entre tus dispositivos.</li>
              <li>Guardar tus adjuntos y mostrar recordatorios que hayas configurado.</li>
              <li>Validar y restaurar compras Premium, incluidas las suscripciones antiguas.</li>
              <li>Mostrar anuncios a las cuentas gratuitas y medir su rendimiento.</li>
              <li>Detectar errores, abusos y problemas de seguridad.</li>
            </ul>
          </section>

          <section>
            <h2 className="mb-2 text-xl font-semibold text-slate-950">4. Proveedores</h2>
            <p>
              Para prestar el servicio utilizamos Supabase Auth, Supabase Postgres y Supabase
              Storage; Google Sign-In; Google Mobile Ads (AdMob); y Google Play Billing.
              Estos proveedores pueden procesar la información necesaria para sus funciones según
              sus propias políticas y condiciones. Studiary no vende tus datos personales.
            </p>
          </section>

          <section>
            <h2 className="mb-2 text-xl font-semibold text-slate-950">5. Conservación y eliminación</h2>
            <p>
              Conservamos los datos mientras mantengas tu cuenta o mientras sean necesarios para
              prestar el servicio y cumplir obligaciones legales.
            </p>
            <p className="mt-3">
              Para eliminar tu cuenta desde la aplicación, abre <strong>Perfil</strong>, pulsa
              <strong>Eliminar mi cuenta</strong> y confirma. También puedes solicitarlo por
              correo a{' '}
              <a className="font-medium text-blue-600 underline" href="mailto:pacuan2417@gmail.com">
                pacuan2417@gmail.com
              </a>
              . Eliminamos la cuenta de autenticación, los eventos, asignaturas, objetivos,
              notas, horarios, estadísticas y archivos adjuntos sincronizados. La eliminación se
              procesa al recibir la solicitud; solo podemos conservar información que sea
              necesaria por obligaciones legales o registros de seguridad durante el plazo legal
              aplicable.
            </p>
          </section>

          <section>
            <h2 className="mb-2 text-xl font-semibold text-slate-950">6. Tus opciones</h2>
            <p>
              Puedes cerrar sesión, modificar y eliminar tus datos y revisar el consentimiento
              desde Perfil, en Privacidad de anuncios, cuando corresponda a tu región. También puedes
              contactar con nosotros para ejercer los derechos que correspondan según tu país.
            </p>
          </section>

          <section>
            <h2 className="mb-2 text-xl font-semibold text-slate-950">7. Cambios</h2>
            <p>
              Podemos actualizar esta política cuando cambien las funciones o los proveedores. La
              fecha que aparece al principio indicará la versión vigente.
            </p>
          </section>
        </div>
      </article>
    </main>
  );
}
