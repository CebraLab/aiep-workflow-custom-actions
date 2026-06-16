# AIEP Workflow Custom Actions

Custom workflow actions para HubSpot que envían datos de contactos a sistemas externos vía API.

## Arquitectura

```
HubSpot Workflow → Custom Action → NestJS Backend → API Externa
                       ↑                  ↑
                  (ngrok tunnel)    (PM2 + SQLite)
```

## Estructura del proyecto

```
├── hubspot-app/                  # HubSpot App Project (Projects V2)
│   ├── hsproject.json
│   └── src/app/
│       ├── app-hsmeta.json
│       └── workflow-actions/
│           ├── admision-callcenter-hsmeta.json
│           ├── admision-no-callcenter-hsmeta.json
│           └── difusion-hsmeta.json
│
├── nestjs-backend/               # NestJS Backend
│   ├── src/
│   │   ├── config/               # Configuración tipada
│   │   ├── common/guards/        # Validación firma v3 de HubSpot
│   │   ├── modules/
│   │   │   ├── webhook/          # Endpoints de ejecución
│   │   │   ├── queue/            # BullMQ (Redis) o fallback síncrono
│   │   │   └── execution-log/    # Auditoría de envíos
│   │   └── database/             # TypeORM (SQLite dev / MySQL prod)
│   ├── docker-compose.yml
│   └── .env.example
│
└── .gitignore
```

## Custom Actions

| Acción | Endpoint externo | Inputs |
|---|---|---|
| **Admisión — Call Center** | `POST /queues/.../admision/callcenter` | `ap_tipolanding`, `eres_estudiante_de_ed__media_`, `ap_curso` |
| **Admisión — No Call Center** | `POST /queues/.../admision/no-callcenter` | `ap_tipolanding`, `eres_estudiante_de_ed__media_`, `ap_curso` |
| **Difusión** | `POST /queues/.../difusion` | `ap_rbd`, `eres_estudiante_de_ed__media_`, `id_actividad_de_colegio` |

Las acciones aparecen bajo **"Colas Externas"** en el panel de workflow actions de HubSpot.

## Flujo de ejecución

1. HubSpot envía `POST` al `actionUrl` con el payload del workflow
2. NestJS valida la firma v3 (`X-HubSpot-Signature`)
3. Construye el payload externo: `{ objectId, properties }`
4. Intenta encolar en BullMQ (Redis). Si no está disponible → forward síncrono
5. Registra el resultado en `ExecutionLog` (SQLite/MySQL)
6. Responde a HubSpot: `SENT` (éxito) o `ERROR` (fallo)

## Setup local

### Prerrequisitos

- Node.js 20+
- HubSpot CLI (`npm install -g @hubspot/cli@latest`)
- ngrok

### Variables de entorno

```bash
cp .env.example .env
# Editar .env según entorno
```

| Variable | Descripción |
|---|---|
| `EXTERNAL_API_BASE_URL` | URL base de la API externa destino |
| `DB_TYPE` | `sqlite` (local) o `mysql` (producción) |
| `HUBSPOT_CLIENT_SECRET` | App secret para validar firma v3 (opcional en dev) |
| `REDIS_HOST` | Host de Redis (opcional) |

### Iniciar el backend

```bash
cd nestjs-backend
npm install
npm run build
node dist/main.js    # Corre en http://localhost:3000
```

### Exponer con ngrok

```bash
ngrok http 3000
```

Luego actualizar los `actionUrl` en `hubspot-app/src/app/workflow-actions/*.hsmeta.json` con la URL generada.

### Desplegar a HubSpot

```bash
cd hubspot-app
hs project upload --account <nombre-cuenta>
```

## Endpoints del backend

```
POST /api/hubspot/execute/admision-callcenter
POST /api/hubspot/execute/admision-no-callcenter
POST /api/hubspot/execute/difusion
```

### Payload esperado (HubSpot)

```json
{
  "callbackId": "ap-...",
  "object": { "objectId": 123, "objectType": "CONTACT", "properties": {...} },
  "inputFields": { "ap_tipolanding": "...", "ap_curso": "5" }
}
```

### Respuesta

```json
{
  "outputFields": {
    "hs_execution_state": "SUCCESS",
    "externalStatus": "SENT"
  }
}
```

## Deploy a AWS (EC2)

Ver `DEPLOY.md` para instrucciones detalladas de deploy a EC2 con PM2 + ngrok.

## Tecnologías

- **HubSpot Projects V2** — Custom workflow actions
- **NestJS** — Backend API
- **TypeORM** — ORM (SQLite / MySQL)
- **BullMQ** — Job queue (Redis opcional)
- **PM2** — Process manager (producción)
- **ngrok** — Túnel HTTPS
