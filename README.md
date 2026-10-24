# Cotizador

Herramienta para armar cotizaciones, guardar clientes y productos, y hacer seguimiento de cada cotización.

## Cómo usarla

Abrí `index.html` con doble clic (se abre en el navegador). No necesita instalación, servidor ni conexión a internet salvo para cargar las tipografías.

A la izquierda tenés el menú con las cuatro secciones (en el celular se abre con el botón ☰):

- **Clientes**: nombre o razón social, contacto, CUIT/DNI, condición de IVA, teléfono, email, dirección, localidad, provincia y notas.
- **Productos**: código, nombre, unidad, costo y precio de venta. Si cargás costo y margen, el precio se calcula solo. Tiene un botón para aumentar todos los precios en un porcentaje.
- **Nueva cotización**: elegís el cliente, buscás productos por código o nombre, ajustás cantidad, precio y descuento por línea, más un descuento general e IVA opcional. Al costado ves el total y, solo para vos, el costo, la ganancia y el margen.
- **Cotizaciones**: todas las que guardaste, numeradas (COT-0001, COT-0002…), con estado (Borrador, Enviada, En negociación, Aceptada, Rechazada, Vencida), fecha de próximo seguimiento y un historial donde anotás cada llamado o novedad. En el menú, "Cotizaciones" muestra un aviso rojo con las que tenés que seguir hoy o están atrasadas. Desde el detalle podés imprimir o guardar en PDF, mandarla por WhatsApp o email, editarla o duplicarla.

Las cotizaciones abiertas pasan solas a "Vencida" cuando se termina su validez. Los datos quedan en el navegador; usá **Descargar copia** (en Ajustes, dentro del menú) cada tanto para no perderlos, y **Restaurar copia** para pasarlos a otra PC. En **Datos de mi empresa** cargás lo que sale en el encabezado de la cotización impresa.
