# REPORTE TÉCNICO: MEDICITAS 360
**Asignatura:** Aplicaciones Distribuidas  
**Proyecto:** MediCitas 360 (Sistema de agendamiento, facturación y control de acceso)  
**Modalidad:** Trabajo Práctico Final  

---

## 1. Datos Generales
- **Nombre del Sistema:** MediCitas 360
- **Integrantes:** [Nombres de los integrantes]
- **Institución:** Universidad Técnica de Ambato (UTA)

---

## 2. Arquitectura Implementada y Tecnologías Utilizadas

### 2.1 Arquitectura del Sistema
El sistema se ha diseñado bajo una **Arquitectura Distribuida Multicapa** con balanceo de carga local y replicación heterogénea de base de datos (Nube y Local). 

El flujo de información es el siguiente:
1. **Cliente Móvil (Flutter):** Envía peticiones HTTP al balanceador NGINX (`http://localhost:8080`).
2. **Capa de Balanceo (NGINX):** Actúa como proxy inverso y distribuye las peticiones mediante Round-Robin entre dos instancias de API ejecutadas localmente (API 1 en puerto 5001 y API 2 en puerto 5002).
3. **Capa de Negocio (Flask APIs):** Las APIs ejecutan la lógica de negocio, validan la disponibilidad de los horarios y autentican las transacciones críticas con tokens.
4. **Capa de Persistencia Nube (Supabase PostgreSQL):** Base de datos principal remota donde se registran médicos, horarios, citas y facturas.
5. **Capa de Persistencia Local (SQLite):** Réplica local (`local_citas.db`) para almacenar citas e invoices directamente desde la API (Opción A) o bajo demanda a través de un endpoint (Opción B), asegurando la continuidad operativa del sistema en escenarios offline.
6. **Servicio SOA Invoicing (Flask):** Servicio independiente en puerto 5003 que recibe la cita, calcula impuestos (15% IVA), genera y firma un comprobante XML conforme el estándar de facturación ecuatoriano, y devuelve la clave de acceso.

---

### 2.2 Tecnologías Utilizadas
- **Lenguajes de Programación:** Dart (Flutter), Python (APIs, Invoicing, DB Scripts), SQL.
- **Frontend / Cliente:** Flutter SDK (Material 3) para Android, iOS, Web y Desktop.
- **Backend / APIs:** Python Flask, Werkzeug, Requests, Gunicorn.
- **Bases de Datos:** Supabase (PostgreSQL en la nube) y SQLite (base de datos local embebida).
- **Balanceador de Carga:** NGINX Open Source.
- **Alta Disponibilidad del Portal:** Keepalived VRRP Daemon.
- **Proxy de Control de Navegación:** Squid Proxy.
- **Generación de QR:** Biblioteca `qrcode` de Python y API QRServer.

---

## 3. Explicación de Componentes e Implementación

### 3.1 Portal Informativo Joomla o WordPress e IP Virtual (Componentes 1 y 2)
El portal informativo de la clínica se despliega utilizando Joomla o WordPress para presentar la clínica de forma estática (Especialidades, médicos, agendamientos y pagos). 

Para lograr **Alta Disponibilidad (HA)**, se configuran dos servidores web:
- **Servidor MASTER:** IP `192.168.100.10` con Keepalived configurado en estado MASTER y prioridad `101`.
- **Servidor BACKUP:** IP `192.168.100.11` con Keepalived configurado en estado BACKUP y prioridad `100`.
- **IP Virtual (VIP):** `192.168.100.50` compartida.

**Funcionamiento de Failover:**
Keepalived monitorea continuamente la salud del servicio NGINX/Apache en el MASTER usando el script `chk_web_server`. Si el servidor MASTER sufre una caída, Keepalived libera la IP Virtual y el servidor BACKUP la asume automáticamente (dentro de un intervalo de 1 segundo). El usuario accede transparentemente al portal mediante `http://192.168.100.50` sin notar la interrupción.

### 3.2 Aplicativo Móvil Flutter (Componente 3)
El aplicativo consume las APIs exclusivamente a través del balanceador (`http://localhost:8080`). Permite:
- Consultar el catálogo de médicos y especialidades en tiempo real.
- Seleccionar horarios disponibles en una cuadrícula interactiva.
- Registrar una cita enviando la cédula y nombre del paciente.
- Mostrar la respuesta en una interfaz de recibo, detallando el valor a pagar, el código de pago (`PAGO-CITA-2026-XXXX`) y la clave de acceso de facturación.
- Renderizar el código QR directamente decodificando el Base64 generado por el servidor, o llamando de forma segura a una API QR de red en caso de consulta histórica.

### 3.3 API REST de Médicos, Horarios y Citas (Componentes 4, 5 y 6)
- `GET /api/medicos`: Retorna el catálogo completo. Cada médico tiene especialidad, consultorio asignado, duración de turno (30/60 min) y un costo de consulta diferenciado.
- `GET /api/medicos/{id}/horarios`: Consulta y devuelve los horarios. Las fechas y horas se serializan de forma limpia (`YYYY-MM-DD` y `HH:MM`).
- `POST /api/citas`: Registra la cita y valida que:
  1. El médico y el horario existan.
  2. El horario esté marcado como `disponible = True`.
  3. No exista otra reserva para el mismo médico en la misma fecha y hora (garantizado también por la restricción `uq_cita_medico_horario` en PostgreSQL).
  4. Los datos del paciente no estén vacíos.
  Una vez exitoso, actualiza el estado del horario a `disponible = False` y calcula la tasa de pago a partir del médico correspondiente.

### 3.4 Seguridad mediante Token (Componente 7)
Los endpoints `POST /api/citas`, `GET /api/citas` y `POST /api/sincronizar` se protegen mediante un decorador de Python que verifica la cabecera `Authorization: Bearer medicitas2026`.
- **Token Correcto:** La API procesa con éxito.
- **Token Incorrecto o Ausente:** La API devuelve `{ "error": "Token no válido o no autorizado" }` y código de estado HTTP `401 Unauthorized`.
*El aplicativo móvil incluye un panel para conmutar y simular el envío de tokens erróneos para facilitar la demostración de esta validación.*

### 3.5 Balanceo Local de Carga (Componente 8)
NGINX se configura en el puerto `8080` como proxy inverso. Utiliza la directiva `upstream` para balancear Round-Robin entre `127.0.0.1:5001` y `127.0.0.1:5002`.
- Si la **API 1 (5001)** se apaga repentinamente, la directiva `proxy_next_upstream` asegura que NGINX redirija la petición inmediatamente a la **API 2 (5002)**, manteniendo el servicio activo para el usuario móvil.

### 3.6 Supabase y Réplica Local de Citas (Componentes 9 y 10)
- **Supabase (Nube):** Base de datos relacional principal PostgreSQL. Mantiene la integridad y restricciones del sistema.
- **SQLite (Réplica Local):**
  - **Opción A (Replicación en línea):** Durante el `POST /api/citas`, tras guardar exitosamente en Supabase, la API escribe el registro de forma síncrona en el archivo local `local_citas.db`.
  - **Opción B (Sincronización masiva):** El endpoint `POST /api/sincronizar` realiza una descarga de todas las citas y facturas desde Supabase a SQLite para sincronizar datos locales huérfanos.
  - **Alta Disponibilidad Móvil:** Si la base de datos principal en la nube está caída, el API redirige transparentemente las lecturas al SQLite local (o el usuario puede forzarlo en el app con el toggle "Replica Local"), garantizando la disponibilidad del historial de citas.

### 3.7 Servicio SOA de Facturación y Código QR (Componentes 11 y 12)
- **Facturación XML:** Servicio SOA REST independiente que corre en el puerto `5003`. Genera la estructura XML `<FacturaCita>` con el paciente, cédula, médico, fecha/hora, total facturado y la clave de acceso estructurada `FAC-CITA-2026-{cita_id:04d}`. El XML se escribe físicamente en el disco en la carpeta `facturacion/facturas/` y la clave se registra en Supabase.
- **Código QR:** Contiene los datos indispensables de cobro de ventanilla. La API genera el QR en formato PNG Base64 mediante la librería `qrcode` y lo inyecta en la respuesta JSON para que el cliente móvil lo pinte de inmediato.

### 3.8 Squid Proxy como Control de Navegación (Componente 13)
Configura una restricción estricta de navegación web. Mediante ACLs, define `sitios_permitidos` apuntando al dominio institucional `.uta.edu.ec` y deniega cualquier otra petición externa (ej. Google, Facebook).
- Regla aplicada:
  ```squid
  acl sitios_permitidos dstdomain .uta.edu.ec uta.edu.ec
  acl red_local src all
  http_access allow red_local sitios_permitidos
  http_access deny all
  ```

---

## 4. Relación con las Unidades de la Asignatura

1. **Unidad 1 (Comunicación cliente-servidor y arquitectura distribuida):** Implementada mediante el aplicativo móvil en Flutter consumiendo recursos remotos a través de HTTP/REST, estructurando las transacciones mediante formato JSON y dividiendo las tareas en capas de presentación, lógica y almacenamiento.
2. **Unidad 2 (Alta disponibilidad y balanceo):** Evidenciada con Keepalived e IP Virtual para garantizar el failover del portal web (MASTER y BACKUP), y el balanceo de carga local con NGINX para failover y distribución de carga en puertos 5001 y 5002.
3. **Unidad 3 (API REST, Token y Bases de Datos):** Desarrollada mediante las APIs REST en Flask, autenticadas con Token Bearer estático, conectadas a Supabase (PostgreSQL en la nube) y con replicación directa/sincronizada en la base local SQLite.
4. **Unidad 4 (SOA y Comprobantes):** Desarrollada con el microservicio SOA independiente de facturación, estructuración y generación de archivos XML y códigos QR físicos para el cobro manual en ventanilla de la clínica.
