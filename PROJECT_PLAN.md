# Dead Porky - Proyecto de app de entrenador personal IA

## 1. Visión del producto
Dead Porky es una aplicación de salud y fitness que funciona como un entrenador personal inteligente. El usuario registra rápidamente su día (entrenamiento, comidas, sueño, agua, peso y medidas) y una IA analiza ese contexto para ajustar recomendaciones diarias y semanales.

### Metas principales
- Crear un flujo de entrada de datos rápido, intuitivo y accesible.
- Mantener contexto diario y semanal para que la IA pueda ofrecer ajustes personalizados.
- Permitir que la IA funcione como un asistente conversacional, pero también como un dashboard de progreso.
- Facilitar el seguimiento de resultados sin que el usuario pierda tiempo.

## 2. Usuarios objetivo
- Personas activas que quieren optimizar su entrenamiento y alimentación.
- Usuarios que desean un coach digital que interprete su comportamiento diario.
- Personas con interés en medir cambios de grasa corporal y ganancia muscular.

## 3. Flujos clave

### 3.1. Onboarding y objetivos
- Definir objetivo principal: pérdida de grasa, ganancia muscular o mantenimiento.
- Registrar restricciones: alergias, dieta, lesiones/cruces, horarios.
- Inicializar métricas iniciales: peso, grasa, cintura, cadera, pecho, bíceps, muslo.

### 3.2. Check-in diario
- Inputs rápidos para:
  - entrenamiento
  - comidas y snacks
  - hidratación
  - sueño
  - peso
  - medidas corporales
  - estado general (energía, ánimo, estrés)
- Guardar estos datos de forma estructurada en una DB local.

### 3.3. Evaluación del día
- Comparar lo esperado vs lo hecho.
- Generar recomendaciones inmediatas:
  - ajustar entrenamiento
  - cambiar ingesta
  - mejorar hidratación
  - optimizar sueño
- Comunicarlo en lenguaje simple.

### 3.4. Revisión semanal
- Mostrar tendencias:
  - peso y medidas
  - cumplimiento de entrenamientos
  - promedio de agua y sueño
  - balance de macros / comidas
- Ajustar el plan de la siguiente semana.

## 4. Módulos propuestos

### 4.1. Dashboard
- Resumen diario de cumplimiento.
- Acceso a check-in rápido.
- Grafico de progreso semanal.
- Entrada al asistente IA.

### 4.2. Entrenamiento
- Registro de sesión rápida:
  - tipo, duración, intensidad, ejercicios.
- Objetivos semanales.
- Historial de sesiones.

### 4.3. Nutrición
- Entradas por comida.
- Cálculo de macros/calorías.
- Plantillas y comidas frecuentes.
- Ajustes recomendados por la IA.

### 4.4. Sueño y recuperación
- Registro de horas soñadas.
- Calidad percibida.
- Consejos de higiene del sueño.

### 4.5. Hidratación
- Tracking de agua fácil.
- Meta diaria personalizable.

### 4.6. Peso y medidas
- Peso corporal.
- Medidas clave para cambio corporal.
- Análisis de ganancias de músculo vs pérdida de grasa.

### 4.7. Asistente IA
- Chat conversacional.
- Revisión del día y la semana.
- Prompts generados a partir de datos registrados.
- Ajustes y recomendaciones.

## 5. Arquitectura técnica

### 5.1. Estado global
- Usar Riverpod para estados de UI y datos.
- StateNotifier para lógica de negocio.

### 5.2. Persistencia
- Guardar datos en base local (Drift / SQLite) para historial.
- Opcional: sincronización con Firebase.

### 5.3. Estructura de prompt IA
- No reenviar todo el historial cada vez.
- Enviar datos estructurados y resumen relevante.
- Mantener:
  - metas del usuario
  - estado de la semana
  - resultados de los últimos 3-5 días
  - entradas del día actual
  - pregunta o petición específica

## 6. Prioridades de implementación

### Sprint 1: Base y flujo diario
- Actualizar README y documentación.
- Crear dashboard base.
- Implementar check-in diario para entrenamiento, comida, agua y sueño.
- Guardar datos en DB local.
- Mostrar resumen simple.

### Sprint 2: IA y ajustes
- Configurar asistente conversacional.
- Crear motor de contexto y prompt.
- Integrar respuestas de la IA con recomendaciones.
- Añadir revisión diaria.

### Sprint 3: Revisión semanal y métricas
- Añadir medidas corporales.
- Implementar gráficos de progreso.
- Construir resumen semanal.
- Ajustar plan y notificaciones.

## 7. Archivo de trabajo
- `TRAINER_IA_DOCUMENTATION.md`: visión del producto e IA.
- `PROJECT_PLAN.md`: plan del proyecto y roadmap.
- `agent.md` / `copilot-instructions.md`: configuración de agente.

## 8. Tareas iniciales inmediatas
1. Actualizar `README.md` con visión del producto.
2. Definir los modelos de datos principales:
   - Entrenamiento
   - Comida
   - Sueño
   - Agua
   - Peso/medidas
3. Crear pantallas básicas de check-in y resumen.
4. Establecer el prompt builder para IA.

---

**Siguiente paso:** comenzar por crear la base de datos y las entidades del flujo diario, y luego construir el dashboard inicial con cards de estado y botones de check-in.