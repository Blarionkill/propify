# Propify – Gestión Residencial

App estática (HTML + JS) para gestión de arriendo con un propietario y un inquilino. Backend en **Supabase** (Auth email/contraseña, Postgres, Storage).

---

## ¿Qué hacer ahora? — Guía Rápida

Sigue estos pasos en orden. Cada uno se detalla en las secciones siguientes.

- [ ] **Paso 1 — Crea tu proyecto Supabase** en [supabase.com](https://supabase.com) y anota la URL y la `anon key`.
- [ ] **Paso 2 — Crea las tablas** ejecutando `supabase_schema.sql` en el SQL Editor de Supabase.
- [ ] **Paso 3 — Crea el bucket de Storage** llamado `supports` (tipo público) desde *Storage → New bucket*.
- [ ] **Paso 4 — Configura Auth** en *Authentication → Providers → Email*: habilita el proveedor Email y asegúrate de que **"Confirm email"** esté desactivado (o actívalo si quieres confirmación de email). En *Authentication → URL Configuration* agrega la URL de tu sitio como Site URL y Redirect URL.
- [ ] **Paso 5 — Pon tus credenciales en el HTML**: abre `propify_app.html` y reemplaza `YOUR_SUPABASE_URL` y `YOUR_SUPABASE_ANON_KEY` con los valores reales. *(O usa el `netlify.toml` + variables de entorno — ver Paso 7.)*
- [ ] **Paso 6 — Crea los usuarios** en *Authentication → Users → Invite user* (o vía la API) con email y contraseña.
- [ ] **Paso 7 — Asigna roles**: una vez creado cada usuario, ve a *Authentication → Users* en Supabase, copia sus UUIDs y ejecuta el INSERT de la sección [Usuarios / Roles](#usuarios--roles).
- [ ] **Paso 8 — Despliega en Netlify**: conecta este repositorio desde *Netlify → Add new site → Import an existing project → GitHub*. Build command: vacío. Publish directory: `.`
- [ ] **¡Listo!** Entra a `https://tu-sitio.netlify.app/propify_app.html`, ingresa tu email y contraseña.

---

## Tabla de Contenidos

1. [Setup Supabase](#1-setup-supabase)
2. [Esquema de base de datos](#2-esquema-de-base-de-datos)
3. [Configurar Auth (email/contraseña)](#3-configurar-auth-emailcontraseña)
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

Después de crear cada usuario en Supabase Auth, inserta su perfil manualmente en la tabla `profiles`:

```sql
-- Reemplaza el UUID con el id real del usuario (auth.users)
INSERT INTO profiles (id, email, role)
VALUES
  ('uuid-del-propietario', 'bxfrias@gmail.com',       'owner'),
  ('uuid-del-inquilino',   'ingenieria5kld@gmail.com', 'tenant');
```

Puedes obtener el UUID desde *Authentication → Users* en el dashboard de Supabase.

---

## 3. Configurar Auth (email/contraseña)

1. En Supabase ve a *Authentication → Providers → Email*.
2. Asegúrate de que **Email** esté habilitado.
3. Desactiva "Confirm email" si prefieres acceso directo sin doble confirmación (opcional).
4. En *Authentication → URL Configuration* configura:

   | Campo | Valor |
   |---|---|
   | **Site URL** | `https://tu-sitio.netlify.app` |
   | **Redirect URLs** | `https://tu-sitio.netlify.app/propify_app.html` |

   > Para desarrollo local agrega también `http://localhost:puerto/propify_app.html`.

5. Crea los usuarios desde *Authentication → Users → Invite user* o con el script de SQL de la sección anterior.

> **Restablecer contraseña:** Si un usuario olvida su contraseña, puede usar el enlace **"¿Olvidaste tu contraseña?"** en la pantalla de inicio de sesión. Recibirá un correo con un enlace para establecer una nueva contraseña.

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
  command = "sed -i 's|YOUR_SUPABASE_URL|'\"$SUPABASE_URL\"'|g' propify_app.html && sed -i 's|YOUR_SUPABASE_ANON_KEY|'\"$SUPABASE_ANON_KEY\"'|g' propify_app.html"
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
- Inicia sesión con email y contraseña → accede con todas las secciones habilitadas.
- Puede crear/editar inquilinos, registrar abonos, gestionar cuotas de administración y cuentas maestras de servicios.

### Inquilino (`tenant`)
- Inicia sesión con email y contraseña → ve Inquilinos, Recaudos y Servicios (solo lectura, incluyendo cuentas maestras y registro de medidores).
- Puede registrar pagos de servicios con soporte (foto o PDF).
