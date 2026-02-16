# Studiary 🎓 - Sistema de Gestión Académica Multiplataforma

[![Next.js](https://img.shields.io/badge/Next.js-15-black?style=flat&logo=next.js)](https://nextjs.org/)
[![Capacitor](https://img.shields.io/badge/Capacitor-7-blue?style=flat&logo=capacitor)](https://capacitorjs.com/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5-blue?style=flat&logo=typescript)](https://www.typescriptlang.org/)
[![Firebase](https://img.shields.io/badge/Firebase-11-orange?style=flat&logo=firebase)](https://firebase.google.com/)

**Studiary** es una solución integral diseñada para optimizar la organización estudiantil. A diferencia de las agendas tradicionales, Studiary combina una interfaz minimalista inspirada en la filosofía "Zen" con la potencia de una arquitectura moderna que permite su uso tanto en navegadores web como de forma nativa en dispositivos Android.

---

## 🚀 Características Principales

El proyecto se divide en módulos clave diseñados para cubrir todo el ciclo de vida del estudiante:

### 📅 Planificación Inteligente
* **Calendario Multi-Vista:** Visualización dinámica en formatos anual, mensual y semanal para una planificación estratégica.
* **Horarios Flexibles:** Gestión de bloques horarios para clases y actividades extracurriculares en jornadas de mañana y tarde.

### 📊 Seguimiento y Rendimiento
* **Gestión de Calificaciones:** Módulo dedicado para el registro de notas y cálculo de promedios.
* **Visualización de Datos:** Gráficos interactivos construidos con **Recharts** que permiten analizar el progreso académico visualmente.
* **Modo de Estudio:** Herramientas específicas para mejorar la concentración y el seguimiento de tareas pendientes.

### 🔔 Productividad Avanzada
* **Recordatorios Inteligentes:** Sistema de notificaciones para entregas y exámenes.
* **Exportación de Documentos:** Capacidad para generar reportes en PDF y capturas mediante la integración de `jspdf` y `html2canvas`.

---

## 🛠️ Stack Tecnológico

### Frontend & Web
* **Next.js 15 (App Router):** Utilizando las últimas capacidades de React 18, incluyendo Server Actions y optimización con Turbopack.
* **Tailwind CSS:** Para un diseño responsivo y un sistema de diseño basado en utilidad.
* **Shadcn/UI & Radix UI:** Implementación de componentes accesibles como diálogos, menús desplegables, y hojas laterales (sheets).

### Mobile Core
* **Capacitor 7:** Puente nativo que permite convertir la experiencia web en una aplicación Android robusta, utilizando configuraciones de esquema HTTPS y gestión de assets nativos.

### Backend & Estado
* **Firebase:** Suite completa para la gestión de datos y persistencia.
* **Zod & React Hook Form:** Validación estricta de esquemas de datos y manejo eficiente de formularios complejos.

---

## 🎨 Filosofía de Diseño (Zen Blueprint)

La aplicación sigue una guía de estilo rigurosa para garantizar la legibilidad y reducir el estrés del usuario:

* **Paleta de Colores:** Uso de tonos pasteles como *Soft Pink* (#F4C2C2) para calma y *Light Beige* (#F5F5DC) como fondo neutro.
* **Tipografía:** 'PT Sans' para una experiencia de lectura clara y amigable.
* **Minimalismo:** Layouts limpios con espaciado generoso para evitar la saturación visual.

---

## 📦 Instalación y Desarrollo

### Requisitos Previos
* Node.js (Versión recomendada v20+)
* Android Studio (para compilación nativa)

### Configuración Local
1.  **Clonar el repositorio:**
    ```bash
    git clone [https://github.com/Juanpareja02/Studiary.git](https://github.com/Juanpareja02/Studiary.git)
    cd Studiary
    ```
2.  **Instalar dependencias:**
    ```bash
    npm install
    ```
3.  **Ejecutar entorno de desarrollo:**
    ```bash
    npm run dev
    ```

### Despliegue en Android
```bash
# Generar la exportación estática
npm run build

# Sincronizar con el proyecto de Android
npx cap sync android

# Abrir en Android Studio
npx cap open android
