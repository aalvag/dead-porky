# Dead Porky User Flow

## Resumen general

La aplicación arranca desde `lib/main.dart`, carga variables de entorno, inicializa Firebase y ejecuta `ProviderScope`.

A partir de ahí, `DeadPorkyApp` usa `MaterialApp.router` con `routerProvider` de GoRouter.

El flujo principal es:

1. App inicia
2. El router evalúa si el usuario está autenticado
3. Si no está, va a `/auth/login`
4. Si está autenticado, carga el `MainShell` con la navegación inferior
5. El onboarding ya no es obligatorio al iniciar; se accede desde `Ajustes`

## Rutas principales

- `/auth/login` → `LoginScreen`
- `/auth/register` → `RegisterScreen`
- `/onboarding` → `OnboardingScreen`
- `/dashboard` → `DashboardScreen`
- `/exercises` → `RoutinesScreen`
- `/habits` → `HabitTrackerScreen`
- `/health` → `NutritionScreen`
- `/settings` → `SettingsScreen`

### Subrutas del dashboard

- `/dashboard/devices` → `DeviceScannerScreen`
- `/dashboard/ai-chat` → `AIChatScreen`
- `/dashboard/daily-checkin` → `DailyCheckinScreen`
- `/dashboard/reports` → `ReportsScreen`

## Comportamiento de login

- Si el usuario no está autenticado y accede a cualquier ruta distinta de `/auth/*`, se redirige automáticamente a `/auth/login`.
- Si el usuario está autenticado y trata de entrar en un auth route, se redirige a `/dashboard`.

## MainShell y navegación inferior

El `MainShell` usa `StatefulShellRoute.indexedStack`:

- `Inicio` → `DashboardScreen`
- `Ejercicios` → `RoutinesScreen`
- `Hábitos` → `HabitTrackerScreen`
- `Salud` → `NutritionScreen`
- `Ajustes` → `SettingsScreen`

## Onboarding / Perfil

- El onboarding ya no bloquea el arranque de la app.
- Se mantiene como un módulo opcional accesible desde `Ajustes`.
- Si el usuario quiere completar perfil físico, puede entrar a `/onboarding` desde `SettingsScreen`.

## Flujo típico de usuario

1. Usuario abre la app
2. Si no está logueado, ve pantalla de login
3. Ingresa credenciales y se redirige a `Inicio`
4. En `Inicio`, ve el dashboard con resumen, hábitos, check-in y accesos directos
5. Puede navegar a `Ejercicios`, `Hábitos`, `Salud` o `Ajustes`
6. Desde `Ajustes` puede abrir `Perfil/Onboarding` opcionalmente para completar datos

## Notas importantes

- Los datos `Dashboard` ya no muestran valores mock en `daily_summary_card.dart`, `calories_ring_card.dart` ni `health_metrics_card.dart`.
- El flujo actual es `auth` → `main shell`; `onboarding` es un módulo secundario.

## Diagrama de flujo

```mermaid
flowchart TD
  A[App inicia]
  A --> B[main.dart: ProviderScope + Firebase init]
  B --> C[DeadPorkyApp: MaterialApp.router]
  C --> D[routerProvider]
  D -->|no auth| E[/auth/login\nLoginScreen]
  D -->|auth| F[/dashboard\nMainShell]
  F --> G[Dashboard]
  F --> H[Ejercicios]
  F --> I[Hábitos]
  F --> J[Salud]
  F --> K[Ajustes]
  G --> G1[/dashboard/daily-checkin\nDailyCheckinScreen]
  G --> G2[/dashboard/ai-chat\nAIChatScreen]
  G --> G3[/dashboard/reports\nReportsScreen]
  G --> G4[/dashboard/devices\nDeviceScannerScreen]
  K --> L[/onboarding\nOnboardingScreen]
  E -->|login completo| F
```
