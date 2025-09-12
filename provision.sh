#!/bin/bash

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Función para imprimir mensajes
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARN: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Función para verificar si el usuario tiene privilegios de sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        if ! sudo -n true 2>/dev/null; then
            error "Este script requiere privilegios de sudo. Por favor ejecuta con sudo o como root."
        fi
    fi
}

# Función para detectar la distribución de Linux
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        error "No se pudo detectar la distribución de Linux"
    fi
}

# Función para actualizar el sistema
update_system() {
    log "Actualizando el sistema..."
    case "$OS" in
        ubuntu|debian)
            sudo apt-get update -qq
            sudo apt-get upgrade -y -qq
            ;;
        centos|rhel|fedora)
            sudo yum update -y -q
            ;;
        *)
            error "Sistema operativo no soportado: $OS"
            ;;
    esac
}

# Función para instalar paquetes básicos
install_basic_tools() {
    log "Instalando herramientas básicas..."
    case "$OS" in
        ubuntu|debian)
            sudo apt-get install -y -qq git curl wget rsync openssh-client openssh-server \
                software-properties-common apt-transport-https ca-certificates \
                gnupg-agent unzip make nano htop vim
            ;;
        centos|rhel|fedora)
            sudo yum install -y -q git curl wget rsync openssh-clients openssh-server \
                unzip nano htop vim
            ;;
    esac
}

# Función para instalar Docker
install_docker() {
    log "Instalando Docker..."
    if command -v docker &> /dev/null; then
        warn "Docker ya está instalado"
        return
    fi

    case "$OS" in
        ubuntu|debian)
            # Agregar repositorio oficial de Docker
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            sudo add-apt-repository \
                "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) \
                stable"
            sudo apt-get update -qq
            sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io
            ;;
        centos)
            sudo yum install -y -q yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y -q docker-ce docker-ce-cli containerd.io
            ;;
        fedora)
            sudo dnf -y -q install dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf -y -q install docker-ce docker-ce-cli containerd.io
            ;;
    esac

    # Agregar usuario actual al grupo docker
    sudo usermod -aG docker $USER
    
    # Habilitar e iniciar Docker
    sudo systemctl enable docker
    sudo systemctl start docker
    
    log "Docker instalado correctamente"
}

# Función para instalar Docker Compose
install_docker_compose() {
    log "Instalando Docker Compose..."
    if command -v docker-compose &> /dev/null; then
        warn "Docker Compose ya está instalado"
        return
    fi

    # Descargar la última versión estable de Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose --silent
    
    # Dar permisos de ejecución
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Crear enlace simbólico para compatibilidad
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    log "Docker Compose instalado correctamente"
}

# Función para configurar SSH
setup_ssh() {
    log "Configurando SSH..."
    
    # Asegurarse de que el directorio .ssh existe
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # Configurar permisos adecuados para el directorio SSH
    sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    
    # Reiniciar servicio SSH
    sudo systemctl restart ssh
    
    log "SSH configurado correctamente"
}

# Función para configurar el acceso SSH a GitHub
setup_github_ssh() {
    log "Configurando acceso SSH a GitHub..."
    
    # Verificar si ya existe una clave SSH
    if [ ! -f ~/.ssh/id_rsa ]; then
        info "Generando nueva clave SSH..."
        ssh-keygen -t rsa -b 4096 -C "devops@laravel-docker" -N "" -f ~/.ssh/id_rsa
    fi
    
    # Mostrar la clave pública para GitHub
    log "Por favor agrega la siguiente clave pública a tu cuenta de GitHub:"
    echo -e "${YELLOW}"
    cat ~/.ssh/id_rsa.pub
    echo -e "${NC}"
    
    read -p "Presiona Enter después de haber agregado la clave a GitHub..."
    
    # Probar la conexión a GitHub
    log "Probando conexión SSH con GitHub..."
    ssh -T git@github.com || true
}

# Función para clonar el repositorio
clone_repository() {
    local repo_url=$1
    local target_dir=${2:-"/opt/laravel-app"}
    
    log "Clonando repositorio: $repo_url"
    
    if [ -d "$target_dir" ]; then
        warn "El directorio $target_dir ya existe. Actualizando en lugar de clonar..."
        cd "$target_dir"
        git pull origin main
    else
        sudo mkdir -p "$target_dir"
        sudo chown $USER:$USER "$target_dir"
        git clone "$repo_url" "$target_dir"
        cd "$target_dir"
    fi
    
    # Configurar permisos para el proyecto
    find . -type d -exec chmod 755 {} \;
    find . -type f -exec chmod 644 {} \;
    
    log "Repositorio clonado/actualizado en: $target_dir"
}

# Función para configurar el entorno del proyecto
setup_project() {
    log "Configurando el proyecto Laravel..."
    
    # Copiar archivo de entorno si no existe
    if [ ! -f .env ]; then
        cp .env.example .env
    fi
    
    # Construir contenedores Docker
    log "Construyendo contenedores Docker..."
    docker-compose -f docker-compose.dev.yml build
    
    # Iniciar contenedores
    log "Iniciando contenedores..."
    docker-compose -f docker-compose.dev.yml up -d
    
    # Instalar dependencias de Composer
    log "Instalando dependencias de Composer..."
    docker-compose -f docker-compose.dev.yml exec app composer install
    
    # Generar key de Laravel
    log "Generando key de aplicación..."
    docker-compose -f docker-compose.dev.yml exec app php artisan key:generate
    
    # Ejecutar migraciones
    log "Ejecutando migraciones de base de datos..."
    docker-compose -f docker-compose.dev.yml exec app php artisan migrate --seed
    
    # Configurar permisos de almacenamiento
    log "Configurando permisos..."
    docker-compose -f docker-compose.dev.yml exec app chmod -R 775 storage bootstrap/cache
    docker-compose -f docker-compose.dev.yml exec app chown -R www-data:www-data storage bootstrap/cache
    
    log "Proyecto configurado correctamente"
}

# Función principal
main() {
    log "Iniciando proceso de provisionamiento para entorno de desarrollo"
    
    # Verificar privilegios de sudo
    check_sudo
    
    # Detectar sistema operativo
    detect_os
    info "Sistema operativo detectado: $OS $OS_VERSION"
    
    # Actualizar sistema
    update_system
    
    # Instalar herramientas básicas
    install_basic_tools
    
    # Instalar Docker
    install_docker
    
    # Instalar Docker Compose
    install_docker_compose
    
    # Configurar SSH
    setup_ssh
    
    # Configurar acceso a GitHub
    setup_github_ssh
    
    # Solicitar URL del repositorio
    read -p "Introduce la URL SSH de tu repositorio GitHub (ej: git@github.com:usuario/repo.git): " repo_url
    
    if [ -z "$repo_url" ]; then
        error "Debes proporcionar una URL de repositorio válida"
    fi
    
    # Clonar repositorio
    clone_repository "$repo_url"
    
    # Configurar proyecto
    setup_project
    
    # Mostrar información final
    log "Provisionamiento completado exitosamente!"
    info "Acceso a la aplicación: http://localhost"
    info "Acceso a PHPMyAdmin: http://localhost:8080"
    info "Para ver los logs: docker-compose logs -f"
    info "Para detener los contenedores: docker-compose down"
    info "Para iniciar los contenedores: docker-compose up -d"
    
    # Recordatorio sobre la clave SSH
    warn "Recuerda que has tenido que agregar manualmente la clave SSH a tu cuenta de GitHub"
    warn "Puedes ver tu clave pública con: cat ~/.ssh/id_rsa.pub"
}

# Ejecutar función principal
main "$@"