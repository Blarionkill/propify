# Propify – Gestión Residencial

App estática (HTML + JS) para gestión de arriendo con un propietario y un inquilino. Backend en **Supabase** (Auth magic-link, Postgres, Storage).

---

## Tabla de Contenidos

1. [Setup Supabase](#1-setup-supabase)
2. [Esquema de base de datos](#2-esquema-de-base-de-datos)
3. [Configurar Auth (magic link)](#3-configurar-auth-magic-link)
4. [Configurar variables en el HTML](#4-configurar-variables-en-el-html)
5. [Despliegue en Netlify](#5-despliegue-en-netlify)

---

## 1. Setup Supabase

1. Crea una cuenta en [supabase.com](https://supabase.com) y crea un nuevo proyecto.
2. Anota la **Project URL** y la **anon public key** desde  
   *Settings → API → Project URL / Project API keys*.
3. Ejecuta el archivo `supabase_schema.sql` en el **SQL Editor** de Supabase  
   (*Table Editor → SQL Editor → New query → pega el contenido → Run*).
4. Crea el bucket de Storage:
   - Ve a *Storage → New bucket*.
   - Nombre: `supports`.
   - Marca **Public bucket** para que los soportes sean accesibles por URL pública.

---

## 2. Esquema de base de datos

El archivo `supabase_schema.sql` crea:

| Tabla | Descripción |
|---|---|
| `profiles` | Un registro por usuario Auth; campo `role` = `owner` o `tenant` |
| `tenants` | Directorio de inquilinos |
| `payments` | Pagos de arriendo recibidos (con URL de soporte opcional) |
| `admin_fees` | Cuotas de administración por mes |
| `utility_accounts` | Cuentas maestras de servicios (Luz/Agua/Gas) |
| `service_readings` | Lecturas de medidores |
| `service_payments` | Pagos de servicios por inquilino (con URL de soporte opcional) |

### Usuarios / Roles

Después de que cada usuario confirme su primer magic link, inserta su perfil manualmente en la tabla `profiles`:

```sql
-- Reemplaza el UUID con el id real del usuario (auth.users)
INSERT INTO profiles (id, email, role)
VALUES
  ('uuid-del-propietario', 'bxfrias@gmail.com',       'owner'),
  ('uuid-del-inquilino',   'ingenieria5kld@gmail.com', 'tenant');
```

Puedes obtener el UUID desde *Authentication → Users* en el dashboard de Supabase.

---

## 3. Configurar Auth (magic link)

1. En Supabase ve a *Authentication → Providers → Email*.
2. Asegúrate de que **Email** esté habilitado.
3. Desactiva "Confirm email" si prefieres acceso directo sin doble confirmación (opcional).
4. En *Authentication → URL Configuration* configura:

   | Campo | Valor |
   |---|---|
   | **Site URL** | `https://tu-sitio.netlify.app` |
   | **Redirect URLs** | `https://tu-sitio.netlify.app/propify_app.html` |

   > Para desarrollo local agrega también `http://localhost:puerto/propify_app.html`.

---

## 4. Configurar variables en el HTML

Abre `propify_app.html` y localiza estas dos líneas al inicio del bloque `<script>`:

```js
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

Reemplaza los placeholders con los valores reales de tu proyecto Supabase:

```js
const SUPABASE_URL = 'https://xxxxxxxxxxxxxxxxxxxx.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

> **Nota de seguridad:** La `anon key` de Supabase es pública por diseño; las Row Level Security (RLS) policies en la base de datos son la capa de protección real. **Nunca** uses la `service_role` key en el frontend.

---

## 5. Despliegue en Netlify

### Opción A – Edición directa (más simple)

1. Edita `propify_app.html` con tus valores reales de Supabase (ver sección anterior).
2. En [netlify.com](https://app.netlify.com) elige **"Add new site → Deploy manually"**.
3. Arrastra la carpeta del proyecto (o sube el archivo `propify_app.html`).
4. Netlify te asignará una URL tipo `https://nombre-aleatorio.netlify.app`.
5. Actualiza la **Site URL** y el **Redirect URL** en Supabase con esa URL.

### Opción B – Desde GitHub (recomendado)

1. Haz fork o push de este repositorio a tu cuenta GitHub.
2. Conecta el repo en Netlify: *"Add new site → Import an existing project → GitHub"*.
3. Configuración de build:
   - **Build command:** *(vacío, no hay build)*
   - **Publish directory:** `.` *(raíz del proyecto)*
4. Publica y actualiza las URLs en Supabase.

### Variables de entorno (opcional)

Si prefieres no hardcodear las credenciales puedes usar un build script mínimo de Netlify.  
Crea el archivo `netlify.toml` en la raíz:

```toml
[build]
  command = "sed -i 's|YOUR_SUPABASE_URL|'\"$SUPABASE_URL\"'|g; s|YOUR_SUPABASE_ANON_KEY|'\"$SUPABASE_ANON_KEY\"'|g' propify_app.html"
  publish = "."
```

Y agrega las variables en *Netlify → Site settings → Environment variables*:

| Variable | Valor |
|---|---|
| `SUPABASE_URL` | `https://xxxx.supabase.co` |
| `SUPABASE_ANON_KEY` | `eyJhbGci...` |

---

## Flujo de uso

### Propietario (`owner`)
- Inicia sesión → recibe link en su email → accede con todas las secciones habilitadas.
- Puede crear/editar inquilinos, registrar abonos, gestionar cuotas de administración y cuentas maestras de servicios.

### Inquilino (`tenant`)
- Inicia sesión → recibe link en su email → ve Dashboard, Servicios y Administración (solo lectura).
- Puede registrar pagos de servicios con soporte (foto o PDF).
