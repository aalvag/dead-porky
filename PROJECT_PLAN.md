# Dead Porky - Plan de Proyecto Actualizado

## Fecha de actualización
26 de mayo de 2026

## 1. Visión del producto
Dead Porky es una app Flutter de salud y fitness enfocada en combinar:
- seguimiento diario (entrenamiento, hábitos, nutrición y métricas de salud),
- integración con fuentes de datos de wearable,
- y un asistente IA para recomendaciones personalizadas.

El objetivo es que el usuario registre rápido, vea su progreso en un dashboard claro y reciba ajustes prácticos cada día y semana.

## 2. Estado real del producto

### 2.1. Base de aplicación
Completado:
- Inicialización Flutter + Firebase en el arranque.
- Navegación con GoRouter y shell con navegación inferior.
- Protección de rutas por autenticación.

Parcial:
- Inyección de dependencias declarada, pero no inicializada en main.

### 2.2. Autenticación
Completado:
- Login y registro por email.
- Flujo de redirección auth/no-auth.
- Modo local de debug para entrar sin backend en builds de desarrollo.

Pendiente:
- Google Sign-In.
- Apple Sign-In.

### 2.3. Dashboard y check-in
Completado:
- Dashboard principal con tarjetas de resumen, hábitos, métricas y accesos rápidos.
- Check-in diario con datos de agua, sueño, ánimo, energía, notas y cumplimiento básico.
- Accesos a chat IA, reportes y escaneo de dispositivos.

### 2.4. Salud y métricas
Completado:
- Pantalla de métricas de salud con secciones de resumen, composición, cardio y sueño.
- Registro manual de métricas (vía provider de health metrics).
- Sincronización de métricas wearable con enfoque en fuentes Huawei/bridge.

Parcial:
- Algunas visualizaciones todavía aplican valores de fallback cuando faltan datos (evitar presentar esos valores como medición real en UI final).

### 2.5. Wearable (Huawei + Health Connect)
Completado:
- Escaneo BLE de dispositivos.
- Provider de métricas wearable con lectura desde Health API.
- Integración Android por MethodChannel para Huawei Health Kit.
- Lógica de fallback cuando Huawei Health Kit no está disponible y paso a Health Connect/bridge.

Pendiente crítico externo:
- Configurar credenciales reales de Huawei Health Kit (HUAWEI_HEALTH_APP_ID) y permisos/scope aprobados en consola Huawei.
- En iOS, configurar capability/entitlements de HealthKit para sincronización real.

### 2.6. Nutrición
Completado:
- Módulo de nutrición operativo con:
  - entradas diarias por comida,
  - objetivos personalizados,
  - recetas guardadas,
  - persistencia en Drift.
- Captura por foto con IA (image_picker + análisis con Kilo Gateway), pasando por editor manual antes de guardar.

### 2.7. Entrenamiento y rutinas
Completado:
- Pantallas de rutinas, sesión activa y gestión base de ejercicios.
- Entidades de entrenamiento y registros de sesión.

Parcial:
- Servicio de historial aún mantiene almacenamiento en memoria para parte del flujo y no persiste todo en Drift/Firestore.
- Quedan TODOs de UX/acciones en algunas pantallas (iniciar desde template, detalle, reorder, etc.).

### 2.8. Hábitos, reportes y ajustes
Completado:
- Módulo de hábitos operativo.
- Pantalla de reportes disponible.
- Sección de ajustes con opciones de exportación/reset/base legal en UI.

Pendiente:
- Implementar cierre de sesión desde ajustes.
- Implementar eliminación de cuenta.
- Enlazar acciones legales (términos/privacidad) a URLs reales dentro de la app.

### 2.9. Persistencia y datos
Completado:
- Base local con Drift y tablas para:
  - workouts,
  - workout_sets,
  - habits,
  - habit_logs,
  - health_metrics,
  - daily_checkins,
  - nutrition_entries,
  - nutrition_goals,
  - nutrition_recipes,
  - sync_queue.
- Migración de esquema activa (versionado de DB y upgrade para tablas de nutrición).

### 2.10. Legal y publicación
Completado:
- Documentación legal web en docs (privacy policy, terms, index).
- Estructura lista para servir en GitHub Pages.

## 3. Arquitectura vigente
- Framework: Flutter (Material 3).
- Estado: Riverpod + StateNotifier.
- Navegación: GoRouter (StatefulShellRoute con tabs).
- Persistencia local: Drift/SQLite.
- Backend/servicios: Firebase (core/auth/firestore/messaging/crashlytics/analytics) y API IA (Kilo Gateway).
- Wearables: Health (Health Connect / Apple Health) + puente Huawei Health Kit por canal nativo Android.

## 4. Deuda técnica priorizada

Prioridad alta:
1. Activar inyección de dependencias en el arranque y limpiar wiring manual.
2. Persistir de forma consistente historial de entrenamientos/snapshots en Drift (y opcional sync remoto).
3. Completar flujo de sesión/cuenta en Ajustes (logout + delete account).
4. Reducir dependencias de respuestas fallback en IA y métricas para separar claramente dato real vs estimado.

Prioridad media:
1. Implementar Google/Apple Sign-In.
2. Finalizar acciones pendientes en pantallas de entrenamiento (templates, navegación y reorder).
3. Mejorar cobertura de tests unitarios/widget para providers críticos (auth, wearable, nutrición, health metrics).

Prioridad baja:
1. Internacionalización completa (mover constantes hardcodeadas a ARB).
2. Endurecer estrategia de sincronización offline/online sobre sync_queue.

## 5. Roadmap propuesto (alineado al estado actual)

### Fase A - Cerrar funcionalidad core (1-2 semanas)
- Implementar logout y eliminación de cuenta.
- Conectar términos y privacidad desde Ajustes.
- Activar DI en main y resolver dependencias de servicios.
- Completar persistencia faltante de historial de entreno.

### Fase B - Robustez de datos y wearable (2-3 semanas)
- Diferenciar explícitamente en UI datos medidos, agregados y fallback.
- Cerrar integración Huawei Health Kit productiva (app id real, scopes, prueba en dispositivo).
- Preparar HealthKit capability en iOS.
- Añadir telemetría de errores de sync wearable y trazabilidad por fuente.

### Fase C - Calidad y release readiness (2 semanas)
- Cobertura de pruebas en módulos críticos.
- QA end-to-end de flujo auth -> dashboard -> check-in -> nutrición -> IA -> reportes.
- Revisión de performance en pantallas más pesadas (salud y nutrición).
- Checklist de release Android/iOS y smoke tests finales.

## 6. Próximos pasos inmediatos
1. Resolver TODOs de Ajustes: logout, eliminación de cuenta y enlaces legales.
2. Integrar persistencia real en WorkoutHistoryService (Drift) y adaptar consumidores.
3. Inicializar DI en main y validar arranque completo.
4. Definir en dashboard/salud una convención visual única para datos sin muestra (sin convertirlos a cero ficticio).
5. Correr batería de validación mínima:
   - flutter analyze
   - pruebas de flujo auth
   - prueba de sync wearable en Android (Huawei/bridge)

## 7. Documentos de referencia del repo
- TRAINER_IA_DOCUMENTATION.md: visión funcional del producto e IA.
- APP_FLOW.md: flujo real de navegación y rutas.
- README.md: resumen general del repositorio.
- docs/privacy-policy.html y docs/terms-of-use.html: base legal pública.

---

Este plan reemplaza el enfoque de "módulos propuestos" por un estado de ejecución real y una hoja de ruta orientada a cierre de producto.