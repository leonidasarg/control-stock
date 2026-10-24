# Cotizador · Vestí Tu Negocio

Herramienta para armar cotizaciones de **Vestí Tu Negocio** (remeras, buzos y gorras personalizadas con estampado DTF), guardar clientes y productos, y hacer seguimiento de cada cotización.

Usa la identidad del [manual de marca](https://github.com/leonidasarg/web-vesti-tu-negocio/blob/main/brand/manual-de-marca.html): logo, favicon, paleta de imprenta (magenta `#D6006E` y cyan `#0089C7` sobre papel `#F2EFEE`), Archivo / IBM Plex Sans / IBM Plex Mono y el desregistro en el título. Tiene modo oscuro automático.

## Cómo usarla

Abrí `index.html` con doble clic (se abre en el navegador). No necesita instalación, servidor ni conexión a internet salvo para cargar las tipografías.

A la izquierda tenés el menú con las cuatro secciones (en el celular se abre con el botón ☰):

- **Clientes**: nombre o razón social, rubro, contacto, CUIT/DNI, condición de IVA, teléfono, email, dirección, localidad, provincia y notas.
- **Productos**: código, nombre, unidad, costo y precio de venta. Si cargás costo y margen, el precio se calcula solo. Tiene un botón para aumentar todos los precios en un porcentaje y, la primera vez, otro para cargar el catálogo base (remeras, buzos, gorras, estampas DTF, urgencia y envío) con los precios en cero para que completes los tuyos.
- **Nueva cotización**: elegís el cliente, buscás productos por código o nombre, ajustás cantidad, precio, descuento y detalle de cada línea (talles, color, ubicación de la estampa), más un descuento general, IVA opcional y la seña. Las condiciones de entrega, pago, logo y cuidado se cargan solas. Al costado ves el total y, solo para vos, el costo, la ganancia y el margen.
- **Cotizaciones**: todas las que guardaste, numeradas (COT-0001, COT-0002…), con una sección de **estado** de un toque: venta (Borrador, Enviada, En negociación, Cerrada), pedido (Seña cobrada, En producción, Lista para entregar, Entregada) o no concretada (Rechazada, Vencida). Mientras se vende tiene fecha de próximo seguimiento; al cerrarla, fecha de entrega prevista. Lleva un historial donde anotás cada llamado o novedad. En el menú, "Cotizaciones" muestra un aviso rojo con las que tenés que seguir hoy o están atrasadas. Desde el detalle podés imprimir o guardar en PDF (A4, con márgenes propios y el nombre del archivo armado con el número y el cliente), mandarla por WhatsApp o email (siempre con el precio de lista, el descuento y cuánto ahorra el cliente), editarla o duplicarla.

Las cotizaciones abiertas pasan solas a "Vencida" cuando se termina su validez. Los datos quedan en el navegador; usá **Descargar copia** (en Ajustes, dentro del menú) cada tanto para no perderlos, y **Restaurar copia** para pasarlos a otra PC. En **Datos de mi empresa** cargás lo que sale en el encabezado de la cotización impresa y en el mensaje de WhatsApp: CUIT, WhatsApp, email, Instagram, web, el porcentaje de seña y las condiciones por defecto.

## Guardar en la nube (Supabase)

Por defecto todo se guarda en el navegador. Si conectás Supabase, además queda guardado en tu proyecto y lo ves igual desde cualquier compu o celular. El cotizador sigue andando sin internet: los cambios se suben solos cuando vuelve la conexión.

1. En tu proyecto de Supabase, abrí **SQL Editor → New query**, pegá el contenido de [`supabase/schema.sql`](supabase/schema.sql) y tocá **Run**. Crea la tabla `cotizador_items` con Row Level Security: cada usuario ve y edita solo lo suyo.
2. En **Authentication → Users → Add user** creá tu usuario con email y contraseña, con **Auto Confirm User** tildado. Si no querés que nadie más se registre, en **Authentication → Sign In / Providers** desactivá **Allow new users to sign up**.
3. En **Project Settings → API** copiá la clave pública (**anon** o **publishable**). Nunca uses la **service_role** ni la **secret**.
4. En el cotizador tocá **Nube** (menú, en Ajustes) y entrá con tu usuario. El proyecto de Vestí Tu Negocio ya viene cargado; para usar otro, tocá **Cambiar proyecto** y pegá su URL y clave. La primera vez sube todo lo que ya tenías en ese navegador.

**Números de cotización sin repetir.** Con la nube conectada, el número lo reparte Supabase con un contador que se bloquea mientras se incrementa: el primero que empieza una cotización (al elegir el cliente o el primer producto) se lleva el siguiente número, aunque haya otra sesión abierta al mismo tiempo. Si descartás la cotización, el número se devuelve, siempre que siga siendo el último. Además, la base rechaza dos cotizaciones con el mismo número. Si guardás sin conexión, queda como *COT-pendiente* (no se puede imprimir ni mandar) y recibe su número apenas vuelve internet.

En cada compu o celular nuevo repetís el paso 4 y se baja todo. El puntito al lado de **Nube** muestra el estado: verde sincronizado, celeste sincronizando, naranja pendiente (sin conexión) y magenta falta iniciar sesión.
