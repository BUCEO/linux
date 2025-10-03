# 🧠 Evaluación del Script de Provisionamiento (`provision.sh`)

## 1. Detección y Adaptación

1.  **¿Cuál es el propósito principal de la expresión `$(. /etc/os-release && echo "$VERSION_CODENAME")` utilizada en el bloque de instalación de Docker para Debian?**
    A. Detectar la arquitectura del procesador (ej. `amd64`).
    B. Obtener el nombre en código de la versión de Debian (ej. `bookworm` o `bullseye`) para el repositorio.
    C. Verificar si el usuario actual tiene el comando `echo`.
    D. Instalar la librería `os-release` si no existe.

2.  **Si el script no encuentra el comando `sudo` al ejecutar `check_sudo` en un sistema Debian, ¿cuál es la acción de seguridad y ayuda que recomienda?**
    A. Continuar el script asumiendo que el usuario es *root*.
    B. Detener el script y sugerir instalarlo con `su -c 'apt-get update && apt-get install sudo -y'`.
    C. Cambiar automáticamente el usuario actual al grupo `sudo`.
    D. Sugerir la instalación de un entorno de escritorio (GUI).

3.  **¿Qué función es responsable de garantizar que el script use el archivo `docker-compose.test.yml` si el usuario selecciona el ambiente de *test*?**
    A. `detect_os`
    B. `install_docker_compose`
    C. `load_or_prompt_config`
    D. `setup_github_ssh`

---

## 2. Seguridad y Manejo de Claves

4.  **En la función `setup_ssh`, ¿cuál es el mecanismo de seguridad implementado antes de modificar el archivo `/etc/ssh/sshd_config`?**
    A. Solicita la clave de root.
    B. Realiza un **respaldo** del archivo de configuración con un *timestamp*.
    C. Cifra el archivo `sshd_config` con una clave pública.
    D. Deshabilita temporalmente el servicio SSH.

5.  **El principio de **idempotencia** en la función `setup_github_ssh` se aplica para evitar:**
    A. La creación de un repositorio duplicado en GitHub.
    B. La doble instalación del paquete `ssh-keygen`.
    C. La **doble generación de la clave privada** `~/.ssh/id_rsa`.
    D. El *login* sin contraseña a GitHub.

6.  **¿Cuál es la consecuencia de establecer `PasswordAuthentication no` en el archivo `/etc/ssh/sshd_config`?**
    A. Solo se permite la autenticación mediante certificados SSL/TLS.
    B. Se obliga al uso **exclusivo de pares de claves SSH** para el acceso remoto.
    C. Se exige que la contraseña del usuario tenga más de 12 caracteres.
    D. Se prohíbe el acceso SSH al servidor de forma permanente.

---

## 3. Docker y Expresiones Regulares

7.  **En la función `setup_project`, ¿por qué se utiliza el argumento `-T` en los comandos `docker compose exec` (ej. `composer install`)?**
    A. Para forzar la ejecución en modo `detached`.
    B. Para **evitar la asignación de TTY**, lo que previene problemas en entornos de *scripting*.
    C. Para usar la versión Standalone de Docker Compose.
    D. Para transferir un archivo binario al contenedor.

8.  **El script utiliza la lógica para preferir el comando `docker compose` (sin guion) sobre `docker-compose` (con guion). ¿Qué representa `docker compose` en una instalación moderna de Docker?**
    A. La versión Standalone v1.
    B. Un alias simbólico.
    C. El **plugin oficial** de Docker Compose v2.
    D. Un comando deprecado.

9.  **En la expresión regular `s/^\s*#?PermitRootLogin.*/PermitRootLogin no/`, ¿qué parte de la RegEx coincide con un posible carácter de comentario (`#`) o ningún carácter antes de la palabra clave?**
    A. `^\s*`
    B. `.*`
    C. **`#?`**
    D. `PermitRootLogin`

---

## 4. Lógica y Comandos de Shell

10. **Al usar la función `load_or_prompt_config`, si el archivo `.provision.conf` existe, ¿qué comando de Bash se utiliza para leer las variables definidas en él y cargarlas en la sesión actual?**
    A. `cat .provision.conf`
    B. `exec .provision.conf`
    C. **`source`** (o `.`)
    D. `read .provision.conf`

11. **¿Qué hace el operador `|| true` al final del comando `ssh -T git@github.com || true` en la función `setup_github_ssh`?**
    A. Asegura que el *output* del comando sea siempre verdadero.
    B. Permite que el script **no falle** si la prueba de conexión a GitHub devuelve un código de error (distinto de 0).
    C. Fuerza una conexión TCP a GitHub.
    D. Asigna la clave pública a GitHub automáticamente.

12. **Después de instalar Docker, ¿cuál es el comando utilizado para añadir al usuario actual (`$USER`) al grupo `docker` para que pueda ejecutar comandos de Docker sin `sudo`?**
    A. `sudo docker group add $USER`
    B. `sudo usermod -aG docker $USER`
    C. `sudo systemctl add-group docker $USER`
    D. `newgrp docker` (esta última no requiere `sudo`)

---
<br>
<br>
