# 🛠️ Script de Provisionamiento Linux Multi-Sistema (`provision.sh`)

Este script de Bash automatiza la configuración inicial de un entorno de desarrollo basado en **Docker/Docker Compose** para aplicaciones web (ej. Laravel) en distribuciones Linux como **Debian**, **Ubuntu** y **CentOS/RHEL/Fedora**.

Su objetivo es estandarizar y asegurar la configuración de herramientas críticas como **SSH**, **Docker** y la clonación del repositorio de forma **segura e idempotente** (ejecutable varias veces sin causar efectos colaterales).

---

## ⚙️ Flujo de Ejecución y Configuración

El script sigue un flujo de trabajo lógico y adaptable, garantizando que cada paso sea robusto y bien documentado:

### 1. Pre-chequeos y Detección (`check_sudo`, `detect_os`)

* **Sudo y Seguridad:** La función `check_sudo` verifica la existencia de `sudo`. Si no se encuentra en una distribución compatible (como **Debian**), el script proporciona la instrucción exacta (`su -c 'apt-get install sudo -y'`) para instalarlo como *root*, resolviendo el problema de adaptabilidad.
* **Detección de OS:** Utiliza `/etc/os-release` para identificar la distribución. Esto es vital en la instalación de Docker, ya que permite obtener el **nombre en código** de la versión (ej. `$VERSION_CODENAME`) necesario para configurar los repositorios de Docker.

### 2. Gestión de la Configuración (`load_or_prompt_config`)

* **Persistencia:** La función `load_or_prompt_config` intenta cargar las variables (`REPO_URL`, `PROJECT_DIR`, `ENV_MODE`) desde el archivo **`.provision.conf`** usando el comando `source`. Esto hace que las ejecuciones posteriores sean no interactivas.
* **Ambientes:** Define el ambiente de trabajo (`dev` o `test`) y, en consecuencia, el archivo de Docker Compose a utilizar (ej. `docker-compose.dev.yml`).

### 3. Provisionamiento Base (`install_docker`, `setup_ssh`, `setup_github_ssh`)

* **Instalación de Docker:** Instala **Docker Engine** y el **plugin de Docker Compose v2** (`docker compose`). Luego añade al usuario actual al **grupo `docker`** (`sudo usermod -aG docker $USER`), lo que permite ejecutar comandos de Docker sin `sudo` (requiere reiniciar sesión).
* **Seguridad SSH y Respaldo (`setup_ssh`)**:
    * **Respaldo Crítico:** Antes de cualquier cambio, se crea una **copia de seguridad** del archivo `/etc/ssh/sshd_config` con un *timestamp*.
    * **Autenticación de Clave:** Se fuerza el uso de **pares de claves SSH** al deshabilitar el *login* por contraseña (`PasswordAuthentication no`) y el *login* de *root* (`PermitRootLogin no`), reforzando la seguridad.
* **Claves GitHub (`setup_github_ssh`)**: Se genera un par de claves SSH (solo si no existe, garantizando la **idempotencia**). La prueba de conexión a GitHub utiliza la lógica **`|| true`** para evitar que el script falle debido a los códigos de retorno no-cero de las pruebas de SSH.

### 4. Despliegue del Proyecto (`clone_repository`, `setup_project`)

* **Clonación Idempotente:** Si el directorio ya existe, `clone_repository` intenta actualizarlo con **`git pull origin main || git pull origin master`**, gestionando las ramas principales comunes.
* **Orquestación Docker:** La función `setup_project` utiliza la bandera **`-T`** en `docker compose exec` (ej. `composer install`). Esta bandera evita la **asignación de TTY** (terminal), una buena práctica al ejecutar comandos dentro de contenedores de forma no interactiva.

---

## 🔎 Enfoque Académico: Expresiones Regulares y Seguridad

### Uso de Expresiones Regulares (RegEx) en `sed`

El script utiliza el comando `sed` (Stream Editor) con expresiones regulares para modificar archivos de configuración de manera precisa y robusta.

**Ejemplo en `setup_ssh`:**
```bash
sudo sed -i -E 's/^\s*#?PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
