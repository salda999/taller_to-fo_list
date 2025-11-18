# Aplicación Lista de Tareas

Una aplicación moderna de Lista de Tareas en Flutter con arquitectura offline-first, integración con API y persistencia local usando SQLite.

## Características

- ✅ Crear, leer, actualizar y eliminar tareas
- 🔄 Offline-first con sincronización automática
- 📱 Interfaz moderna Material Design
- 🌐 Integración con API REST
- 💾 Almacenamiento local SQLite
- 🔗 Detección de conectividad y cola de sincronización
- 📋 Filtrado de tareas (Todas, Pendientes, Completadas)
- ⏱️ Timeouts HTTP con manejo robusto de errores
- 🔄 Backoff exponencial para reintentos
- 🔑 Soporte de Idempotency-Key para evitar duplicados
- 🏆 Resolución de conflictos Last-Write-Wins

## Tecnologías Utilizadas

- **Flutter** 3.x - Desarrollo móvil multiplataforma
- **Provider** - Gestión de estado
- **SQLite (sqflite)** - Base de datos local
- **HTTP** - Comunicación con API
- **Connectivity Plus** - Detección de red
- **UUID** - Generación de IDs únicos
- **Node.js + Express** - Servidor API REST

## Arquitectura

La aplicación sigue los principios de Clean Architecture con clara separación de responsabilidades:

```
lib/
├── data/
│   ├── datasources/
│   │   ├── local/          # Fuentes de datos SQLite
│   │   └── remote/         # Fuentes de datos API
│   ├── models/             # Objetos de transferencia de datos
│   └── repositories/       # Implementaciones de repositorios
├── domain/
│   ├── entities/           # Entidades de negocio
│   ├── repositories/       # Repositorios abstractos
│   └── usecases/           # Lógica de negocio
└── presentation/
    ├── pages/              # Pantallas de UI
    ├── providers/          # Gestión de estado
    └── widgets/            # Componentes reutilizables
```

## Endpoints de API

La aplicación se comunica con una API REST con los siguientes endpoints:

- `GET /tasks` - Obtener todas las tareas
- `GET /tasks/{id}` - Obtener una tarea específica
- `POST /tasks` - Crear una nueva tarea
- `PUT /tasks/{id}` - Actualizar una tarea existente
- `DELETE /tasks/{id}` - Eliminar una tarea

### Esquema de Tarea

```json
{
  "id": "string",
  "title": "string",
  "completed": boolean,
  "updatedAt": "cadena ISO8601"
}
```

## Estrategia Offline-First

La aplicación implementa un enfoque offline-first:

1. **Almacenamiento Local**: Todas las operaciones se realizan primero en la base de datos SQLite local
2. **Cola de Sincronización**: Las operaciones fallidas se ponen en cola para reintentar cuando vuelva la conectividad
3. **Sincronización en Segundo Plano**: Sincronización automática cuando hay red disponible
4. **Resolución de Conflictos**: Estrategia Last-Write-Wins basada en el campo `updatedAt`

### Esquema de Base de Datos

```sql
-- Tabla de tareas
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  completed INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL,
  deleted INTEGER NOT NULL DEFAULT 0
);

-- Tabla de cola de sincronización
CREATE TABLE queue_operations (
  id TEXT PRIMARY KEY,
  entity TEXT,
  entity_id TEXT,
  op TEXT,
  payload TEXT,
  created_at INTEGER,
  attempt_count INTEGER,
  last_error TEXT
);
```

## Instalación y Configuración

### Prerrequisitos

- Flutter 3.x
- Node.js 14+
- Android Studio / Xcode (para desarrollo móvil)

### Configuración de la App Flutter

1. Navega al directorio flutter_app:
   ```bash
   cd flutter_app
   ```

2. Instala las dependencias:
   ```bash
   flutter pub get
   ```

3. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

   Para web:
   ```bash
   flutter run -d chrome
   ```
   Nota: Web usa almacenamiento en memoria en lugar de SQLite. Los datos no se persisten entre sesiones.

### Configuración del Servidor API

1. Navega al directorio api:
   ```bash
   cd api
   ```

2. Instala las dependencias:
   ```bash
   npm install
   ```

3. Inicia el servidor:
   ```bash
   npm start
   # o para desarrollo
   npm run dev
   ```

El servidor API se ejecutará en `http://localhost:3000`.

### Construyendo APK

Para construir un APK de producción:

```bash
cd flutter_app
flutter clean
flutter pub get
flutter build apk --release
```

El APK estará disponible en `flutter_app/build/app/outputs/flutter-apk/app-release.apk`.

**Nota**: Si encuentras problemas con Gradle, consulta `APK_BUILD_INSTRUCTIONS.md` para soluciones alternativas.

## Uso

### Agregando Tareas
- Toca el botón flotante (+) para agregar una nueva tarea
- Ingresa el título de la tarea y envía

### Gestionando Tareas
- **Completar/Incompleta**: Toca la casilla junto a la tarea
- **Editar**: Toca el título de la tarea para editarla
- **Eliminar**: Toca el ícono de eliminar para remover la tarea

### Filtrando Tareas
- Usa el botón de menú en la barra de aplicación para filtrar por:
  - Todas las tareas
  - Tareas pendientes
  - Tareas completadas

### Modo Offline
- La aplicación funciona completamente offline
- Los cambios se sincronizan automáticamente cuando vuelve la conectividad
- Las operaciones fallidas se reintentan en segundo plano

## Estructura del Proyecto

```
taller_to-fo_list/
├── flutter_app/           # Aplicación Flutter
│   ├── lib/
│   │   ├── data/          # Capa de datos
│   │   ├── domain/        # Capa de dominio
│   │   └── presentation/  # Capa de presentación
│   ├── android/           # Código de plataforma Android
│   ├── ios/              # Código de plataforma iOS
│   └── pubspec.yaml      # Dependencias Flutter
├── api/                  # Servidor API REST
│   ├── server.js         # Servidor Express
│   └── package.json      # Dependencias Node.js
└── README.md            # Este archivo
```

## Notas de Desarrollo

### Gestión de Estado
La aplicación usa Provider para gestión de estado con un solo `TaskProvider` que maneja:
- Operaciones CRUD de tareas
- Estados de carga
- Manejo de errores
- Monitoreo de conectividad

### Manejo de Errores
- **Timeouts HTTP**: 10 segundos por petición con TimeoutException
- **Errores de Red**: Distinción entre 4xx (cliente), 5xx (servidor) y conexión
- **Backoff Exponencial**: Reintentos con demora creciente (máx 5 intentos)
- **Idempotencia**: Evita duplicados con Idempotency-Key
- **Resolución LWW**: Comparación automática de `updatedAt` para conflictos
- Las operaciones fallidas se ponen en cola para reintentar
- Mensajes de error amigables para el usuario

### Probando Modo Offline
1. Inicia la aplicación con conexión a internet
2. Agrega algunas tareas
3. Detén el servidor API
4. Realiza operaciones (deberían funcionar localmente)
5. Reinicia el servidor API
6. Observa la sincronización automática

## Contribuyendo

1. Haz fork del repositorio
2. Crea una rama de funcionalidad
3. Haz tus cambios
4. Prueba exhaustivamente (incluyendo escenarios offline)
5. Envía un pull request

## Licencia

Este proyecto está licenciado bajo la Licencia MIT.