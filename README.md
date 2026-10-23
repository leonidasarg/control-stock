# Stock al Día

Herramienta para calcular y registrar diferencias de stock por artículo y depósito (Chamical, Chepes, Villa Unión).

## Cómo usarla

Simplemente abrí `index.html` con doble clic (se abre en el navegador) o hacé clic derecho → Abrir con → tu navegador preferido.

No necesita instalación, servidor ni conexión a internet salvo para cargar las tipografías. Los datos (historial de cálculos y catálogo de productos) se guardan en el almacenamiento local del navegador, así que quedan disponibles la próxima vez que la abras desde el mismo navegador y la misma PC.

## Funcionalidad

- Selección de depósito: Chamical, Chepes, Villa Unión.
- Carga por código de producto (catálogo precargado con 287 artículos; se pueden agregar más desde el botón "Productos").
- Cálculo automático: stock esperado = inicial + compras − ventas, comparado contra el stock contado.
- Estado por color: verde (coincide), amarillo (sobra stock), rojo (falta stock).
- Historial de cálculos por depósito, con buscador por código o nombre.

## Cotizador

Abrí `cotizador.html` (o tocá el botón **Cotizador** arriba a la derecha en Stock al Día). Tiene cuatro pantallas:

- **Clientes**: nombre o razón social, contacto, CUIT/DNI, condición de IVA, teléfono, email, dirección, localidad, provincia y notas.
- **Productos**: código, nombre, unidad, costo y precio de venta. Si cargás costo y margen, el precio se calcula solo. Tiene un botón para aumentar todos los precios en un porcentaje.
- **Nueva cotización**: elegís el cliente, buscás productos por código o nombre, ajustás cantidad, precio y descuento por línea, más un descuento general e IVA opcional. Al costado ves el total y, solo para vos, el costo, la ganancia y el margen.
- **Cotizaciones**: todas las que guardaste, numeradas (COT-0001, COT-0002…), con estado (Borrador, Enviada, En negociación, Aceptada, Rechazada, Vencida), fecha de próximo seguimiento y un historial donde anotás cada llamado o novedad. La pestaña muestra un aviso rojo con las que tenés que seguir hoy o están atrasadas. Desde el detalle podés imprimir o guardar en PDF, mandarla por WhatsApp o email, editarla o duplicarla.

Las cotizaciones abiertas pasan solas a "Vencida" cuando se termina su validez. Los datos quedan en el navegador; usá **Descargar copia de seguridad** cada tanto para no perderlos, y **Restaurar copia** para pasarlos a otra PC. En **Datos de mi empresa** cargás lo que sale en el encabezado de la cotización impresa.
