# Clase 1: Introducción a los Sistemas Operativos y Primeros Comandos en Linux

## 🎯 Objetivos
- Comprender qué es un sistema operativo y cuál es su función.
- Identificar la estructura básica de Linux.
- Conocer y usar comandos esenciales de la terminal.
- Preparar el entorno de trabajo (WSL o máquina virtual).
- Introducir el concepto de usuario y permisos.

## 🧠 Parte 1: Introducción teórica

### ¿Qué es un sistema operativo?
- Software que administra los recursos del sistema.
- Funciona como intermediario entre el usuario y el hardware.
- En Linux, los dos componentes más importantes son:
  - **Kernel**: núcleo, controla el hardware.
  - **Shell**: interfaz que interpreta comandos del usuario.

### Funciones principales
1. Interfaz al usuario.
2. Administración de recursos (CPU, RAM, discos).
3. Gestión de archivos.
4. Gestión de tareas/procesos.
5. Servicios de soporte (drivers, seguridad, actualizaciones).

### ¿Qué es Linux?
- Sistema operativo libre y de código abierto.
- Muchas distribuciones: Debian, Ubuntu, Fedora, Arch, etc.
- Usado en servidores, PC, móviles y más.

## 🧪 Parte 2: Práctica guiada

### 🔧 Entorno de trabajo
- WSL o máquina virtual (Debian/Ubuntu).
- Comandos iniciales:
  ```bash
  uname -a
  cat /etc/os-release
