🛠️ Script de Provisionamiento Linux Multi-Sistema (provision.sh)
Este script de Bash automatiza la configuración inicial de un entorno de desarrollo basado en Docker/Docker Compose para aplicaciones web (ej. Laravel) en distribuciones Linux como Debian, Ubuntu y CentOS/RHEL/Fedora.

Su objetivo es estandarizar y asegurar la configuración de herramientas críticas como SSH, Docker y la clonación del repositorio de forma segura e idempotente (ejecutable varias veces sin causar efectos colaterales).

⚙️ Flujo de Ejecución y Configuración
El script sigue un flujo de trabajo lógico y adaptable:

1. Pre-chequeos y Detección (check_sudo, detect_os)
Sudo y Seguridad: El script inicia verificando si tienes privilegios de sudo. En distribuciones como Debian, donde sudo no siempre está preinstalado, la función check_sudo no solo arroja un error, sino que también proporciona la instrucción exacta (su -c 'apt-get install sudo -y') para instalarlo como root y poder continuar.

Detección de OS: Se usa el archivo estándar /etc/os-release para identificar la distribución y versión de Linux. Esto es crucial para usar los gestores de paquetes correctos (apt para Debian/Ubuntu, yum/dnf para RHEL/CentOS/Fedora) y para la instalación precisa de Docker (ej. usando el $VERSION_CODENAME en Debian).

2. Gestión de la Configuración (load_or_prompt_config)
Esta función prioriza la automatización sobre la interacción:

Persistencia: Intenta leer las variables clave (REPO_URL, PROJECT_DIR, ENV_MODE) desde el archivo .provision.conf.

Interacción: Si el archivo no existe o faltan variables (como el ambiente o la URL del repo), el script pregunta al usuario y guarda las respuestas en el archivo .provision.conf para futuras ejecuciones (principio de persistencia).

Ambientes: Define el ambiente de trabajo (dev o test) y establece el archivo docker-compose a utilizar (ej. docker-compose.dev.yml).

3. Provisionamiento Base (install_docker, setup_ssh, setup_github_ssh)
Instalación de Docker: Se garantiza que se instalen tanto Docker Engine como el plugin de Docker Compose v2 (docker compose). Luego, añade automáticamente al usuario actual al grupo docker (sudo usermod -aG docker $USER), permitiendo ejecutar comandos sin sudo (requiere reiniciar sesión).

Seguridad SSH y Respaldo (setup_ssh):

Respaldo Crítico: Antes de modificar el archivo /etc/ssh/sshd_config, se crea una copia de seguridad con timestamp (ej. sshd_config.bak.20251003103000). Esto permite revertir cualquier cambio de configuración.

Autenticación de Clave: Se fuerza el uso de pares de claves SSH para la autenticación al deshabilitar el login por contraseña (PasswordAuthentication no) y el login de root (PermitRootLogin no), un estándar de seguridad.

Claves GitHub (setup_github_ssh): Se genera un par de claves SSH (solo si no existe, lo que garantiza la idempotencia), y se muestra la clave pública para que sea registrada en GitHub.

4. Despliegue del Proyecto (clone_repository, setup_project)
Clonación Idempotente: La función clone_repository clona el código en el PROJECT_DIR. Si el directorio ya existe, intenta actualizarlo con git pull origin main y, si falla, prueba con git pull origin master para asegurar la continuidad.

Orquestación Docker: La función setup_project construye e inicia los contenedores usando el archivo docker-compose correspondiente al ambiente (dev o test).

🔎 Enfoque Académico: Expresiones Regulares y Seguridad
Uso de Expresiones Regulares (RegEx) en sed
El script utiliza el comando sed (Stream Editor) con expresiones regulares para modificar archivos de configuración de manera precisa y robusta.

Ejemplo en setup_ssh:

Bash

sudo sed -i -E 's/^\s*#?PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
Parte de RegEx	Significado	Coincide con...
s/.../.../	Comando de sustitución (s).	N/A
^	Inicio de la línea.	P, #, etc.
\s*	Cero o más espacios en blanco (útil para la indentación).	(espacio), (tabulación)
#?	El carácter # (comentario) opcional (cero o una vez).	# o nada. Esta es la clave para cambiar líneas comentadas o activas.
PermitRootLogin	Coincidencia literal de la palabra clave.	PermitRootLogin
.*	Cero o más de CUALQUIER carácter hasta el final de la línea.	yes, prohibit-password, no, etc.
/PermitRootLogin no/	El texto de reemplazo.	El nuevo valor deseado.

Exportar a Hojas de cálculo
Claves SSH y el Argumento -T
Prueba de Conexión: El comando ssh -T git@github.com se usa para probar la autenticación. La opción -T deshabilita la asignación de TTY (Terminal), lo que es crucial para evitar que el comando se quede esperando interacción en un script.

Manejo de Errores (|| true): El comando de prueba se ejecuta como ssh -T git@github.com || true.

Cuando GitHub te saluda, el comando ssh suele terminar con un código de error (distinto de 0) porque no se ejecuta ningún comando real en el servidor.

El || true asegura que, aunque el ssh falle (debido al código de error de la prueba), el script principal no se detenga, permitiendo la continuación del proceso.

📘 Resumen de Funciones Clave y su Propósito
Función	Propósito Principal	Enfoque de Evaluación
check_sudo	Asegurar privilegios y sugerir la instalación de sudo en Debian.	Lógica condicional y adaptación multi-sistema.
load_or_prompt_config	Cargar/Guardar variables desde .provision.conf y definir el ambiente (dev/test).	Persistencia de configuración y manejo de ambientes.
install_docker	Instalar Docker Engine/Compose y añadir al usuario al grupo docker (usermod).	Comandos de Linux/seguridad de permisos.
setup_ssh	Respaldar /etc/ssh/sshd_config y deshabilitar el login por contraseña (PasswordAuthentication no) usando RegEx.	Seguridad (claves), RegEx y respaldo.
setup_github_ssh	Generar clave SSH de GitHub (idempotente) y usar `	
setup_project	Usar docker compose exec -T para instalar Composer, generar claves y migrar la base de datos dentro del contenedor.	Uso de banderas Docker (-T) y orquestación.
