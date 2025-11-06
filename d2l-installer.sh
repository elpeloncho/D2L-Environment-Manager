#!/usr/bin/env bash
set -e

# =============================================================================
# CONFIGURACIÓN Y CONSTANTES
# =============================================================================

readonly SCRIPT_NAME="D2L Environment Manager"
readonly D2L_VENV=".d2l_venv"
readonly D2L_VERSION="1.0.3"
readonly NUMPY_VERSION="1.26.4"
readonly PYTHON_REQUIRED="3.9"
readonly TORCH_VERSION="2.0.0"
readonly TORCHVISION_VERSION="0.15.1"

# Variables globales
ADD_JUPYTER=false
PYTHON_BIN=""
MODE="install"  # install o remove

# =============================================================================
# FUNCIONES DE UTILIDAD
# =============================================================================

print_header() {
    echo ""
    echo "  (˶ᵔ ᵕ ᵔ˶)"
    echo "  ¡Bienvenido al gestor de entornos D2L (Dive into Deep Learning)!"
    echo "  ================================================================="
    echo ""
}

print_section() {
    echo ""
    echo "=== $1 ==="
}

log_info() {
    echo "[i] $1"
}

log_success() {
    echo "[+] $1"
}

log_warning() {
    echo "[!] $1"
}

log_action() {
    echo "[*] $1"
}

log_question() {
    echo "[?] $1"
}

log_process() {
    echo "[>] $1"
}

log_error() {
    echo "[✗] ERROR: $1"
}

# =============================================================================
# FUNCIONES DE DETECCIÓN DE PYENV Y PYTHON
# =============================================================================

check_pyenv_installed() {
    print_section "Verificando pyenv"
    
    if ! command -v pyenv &> /dev/null; then
        log_error "pyenv no está instalado en el sistema"
        echo ""
        log_info "Instala pyenv siguiendo las instrucciones en:"
        log_info "https://github.com/pyenv/pyenv#installation"
        echo ""
        exit 1
    fi
    
    log_success "pyenv detectado: $(command -v pyenv)"
    log_info "Versión de pyenv: $(pyenv --version)"
}

check_python_version() {
    print_section "Verificando Python $PYTHON_REQUIRED"
    
    # Obtener versiones de Python instaladas en pyenv
    local available_versions=$(pyenv versions --bare 2>/dev/null | grep "^${PYTHON_REQUIRED}" || true)
    
    if [ -z "$available_versions" ]; then
        log_error "Python $PYTHON_REQUIRED.x no está instalado en pyenv"
        echo ""
        log_info "Versiones de Python disponibles en pyenv:"
        pyenv versions --bare 2>/dev/null || echo "    (ninguna)"
        echo ""
        log_info "Instala Python $PYTHON_REQUIRED con:"
        log_info "    pyenv install $PYTHON_REQUIRED"
        log_info ""
        log_info "Para ver versiones disponibles:"
        log_info "    pyenv install --list | grep \" $PYTHON_REQUIRED\""
        echo ""
        exit 1
    fi
    
    # Tomar la primera versión que coincida con 3.9.x
    local python_version=$(echo "$available_versions" | head -n 1)
    log_success "Python $python_version encontrado en pyenv"
    
    # Configurar el Python a usar
    PYTHON_BIN="$(pyenv root)/versions/$python_version/bin/python"
    
    if [ ! -f "$PYTHON_BIN" ]; then
        log_error "No se pudo acceder al ejecutable de Python: $PYTHON_BIN"
        exit 1
    fi
    
    log_success "Ejecutable de Python: $PYTHON_BIN"
    log_info "Versión completa: $($PYTHON_BIN --version)"
}

detect_python() {
    # Esta función ahora verifica pyenv y Python 3.9
    check_pyenv_installed
    check_python_version
}

# =============================================================================
# FUNCIONES DE DETECCIÓN (resto)
# =============================================================================

detect_jupyter() {
    JUPYTER_BIN=$(command -v jupyter)
    
    if [ -z "$JUPYTER_BIN" ]; then
        log_warning "Jupyter no encontrado en el sistema."
        log_info "No se configurará como kernel."
        ADD_JUPYTER=false
        return 1
    fi
    
    log_success "Jupyter detectado: $JUPYTER_BIN"
    return 0
}

detect_gpu() {
    print_section "Detectando hardware GPU"
    
    if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
        local gpu_info=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n 1)
        log_success "GPU NVIDIA detectada: $gpu_info"
        log_info "PyTorch se instalará con soporte CUDA"
        return 0
    fi
    
    log_warning "No se detectó GPU NVIDIA"
    log_info "PyTorch se instalará en versión CPU"
    return 1
}

# =============================================================================
# FUNCIONES DE CONFIGURACIÓN DE USUARIO
# =============================================================================

prompt_mode_selection() {
    log_question "¿Qué deseas hacer?"
    echo "    1) Instalar entorno D2L"
    echo "    2) Eliminar entorno D2L"
    echo ""
    read -p "Selecciona una opción [1/2]: " choice
    
    case $choice in
        1)
            MODE="install"
            log_action "Modo: Instalación"
            ;;
        2)
            MODE="remove"
            log_action "Modo: Eliminación"
            ;;
        *)
            log_warning "Opción inválida. Saliendo..."
            exit 1
            ;;
    esac
}

check_existing_venv() {
    if [ -d "$D2L_VENV" ]; then
        echo ""
        log_warning "El entorno D2L ya existe en: $D2L_VENV"
        log_warning "Si continúas, se ELIMINARÁ completamente y se reinstalará desde cero."
        echo ""
        read -p "[?] ¿Deseas SOBREESCRIBIR el entorno D2L? [y/N]: " choice
        choice=${choice:-N}
        
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            log_action "Eliminando entorno antiguo: $D2L_VENV"
            rm -rf "$D2L_VENV"
            log_success "Entorno eliminado correctamente"
            return 0
        else
            log_info "Operación cancelada por el usuario"
            exit 0
        fi
    fi
    return 0
}

prompt_jupyter_configuration() {
    echo ""
    read -p "[?] ¿Deseas añadir el entorno como kernel de Jupyter? [Y/n]: " choice
    choice=${choice:-Y}
    
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        detect_jupyter
        ADD_JUPYTER=true
        log_success "Se configurará el kernel de Jupyter"
    else
        log_info "No se configurará kernel de Jupyter"
    fi
}

# =============================================================================
# FUNCIONES DE ELIMINACIÓN
# =============================================================================

detect_existing_venv() {
    if [ ! -d "$D2L_VENV" ]; then
        echo ""
        log_warning "No se encontró el entorno virtual D2L."
        log_info "No hay nada que eliminar. Saliendo..."
        exit 0
    fi
    
    echo ""
    log_info "Entorno virtual detectado:"
    echo "    ✓ D2L: $D2L_VENV"
}

remove_venv() {
    echo ""
    log_warning "Vas a eliminar el entorno: D2L ($D2L_VENV)"
    log_warning "Esta acción NO se puede deshacer."
    echo ""
    read -p "[?] ¿Estás seguro de que deseas eliminar el entorno D2L? [y/N]: " confirm
    confirm=${confirm:-N}
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        log_action "Eliminando entorno D2L..."
        
        # Eliminar el kernel de Jupyter si existe
        remove_jupyter_kernel
        
        # Eliminar el entorno virtual
        rm -rf "$D2L_VENV"
        log_success "Entorno D2L eliminado correctamente"
    else
        log_info "Eliminación cancelada"
        exit 0
    fi
}

remove_jupyter_kernel() {
    local kernel_name="d2l-env"
    
    if command -v jupyter &> /dev/null && jupyter kernelspec list 2>/dev/null | grep -q "$kernel_name"; then
        log_action "Eliminando kernel de Jupyter: $kernel_name"
        jupyter kernelspec uninstall "$kernel_name" -f 2>/dev/null || true
        log_success "Kernel eliminado"
    fi
}

print_removal_summary() {
    echo ""
    log_success "Operación de eliminación completada"
    
    if command -v jupyter &> /dev/null; then
        echo ""
        log_info "Kernels disponibles:"
        jupyter kernelspec list
    fi
    
    echo ""
    echo "  (˶ᵔ ᵕ ᵔ˶) ¡Hasta luego!"
    echo ""
}

# =============================================================================
# FUNCIONES DE INSTALACIÓN
# =============================================================================

create_venv() {
    log_action "Creando entorno virtual $D2L_VENV con Python $PYTHON_REQUIRED..."
    $PYTHON_BIN -m venv "$D2L_VENV"
    log_success "Entorno virtual creado"
}

upgrade_pip() {
    log_process "Actualizando pip..."
    pip install --upgrade pip -q
}

install_numpy() {
    log_process "Instalando numpy $NUMPY_VERSION (versión específica requerida)..."
    pip install "numpy==$NUMPY_VERSION"
    log_success "numpy $NUMPY_VERSION instalado"
}

install_pytorch() {
    print_section "Instalando PyTorch"
    
    if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
        log_action "Instalando PyTorch $TORCH_VERSION con soporte CUDA..."
        pip install "torch==$TORCH_VERSION" "torchvision==$TORCHVISION_VERSION" torchaudio
    else
        log_action "Instalando PyTorch $TORCH_VERSION (CPU)..."
        pip install "torch==$TORCH_VERSION" "torchvision==$TORCHVISION_VERSION" torchaudio --index-url "https://download.pytorch.org/whl/cpu"
    fi
    
    log_success "PyTorch $TORCH_VERSION y torchvision $TORCHVISION_VERSION instalados correctamente"
}

install_d2l() {
    print_section "Instalando D2L"
    
    log_process "Instalando d2l==$D2L_VERSION..."
    pip install "d2l==$D2L_VERSION"
    log_success "D2L $D2L_VERSION instalado correctamente"
}

install_dependencies() {
    print_section "Instalando dependencias adicionales"
    
    log_process "Instalando matplotlib, pandas, requests..."
    pip install matplotlib pandas requests -q
    log_success "Dependencias adicionales instaladas"
}

install_jupyter_packages() {
    if [ "$ADD_JUPYTER" = true ]; then
        log_process "Instalando Jupyter y IPykernel..."
        pip install jupyter ipykernel -q
        log_success "Jupyter instalado en el entorno"
    fi
}

verify_installation() {
    print_section "Verificando instalación"
    
    log_question "Verificando paquetes principales..."
    python - <<'EOF'
import sys
import numpy as np
import torch
import d2l

print("\n=== Versiones instaladas ===")
print(f"Python: {sys.version.split()[0]}")
print(f"NumPy: {np.__version__}")
print(f"PyTorch: {torch.__version__}")
print(f"Torchvision: {torch.__version__}")
print(f"D2L: {d2l.__version__}")

print("\n=== Estado de PyTorch ===")
print(f"CUDA disponible: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name(0)}")
else:
    print("Ejecutando en modo CPU")

print("\n[+] ¡Todas las librerías se importaron correctamente!")
EOF
    
    log_success "Verificación completada"
}

add_jupyter_kernel() {
    if [ "$ADD_JUPYTER" = true ]; then
        print_section "Configurando kernel de Jupyter"
        
        log_action "Añadiendo kernel 'Python (d2l-1.0.3)'..."
        python -m ipykernel install --user --name="d2l-env" --display-name="Python (d2l-1.0.3)"
        log_success "Kernel añadido correctamente"
    fi
}

install_d2l_environment() {
    print_section "Configurando entorno D2L"
    
    # Verificar si existe y preguntar
    check_existing_venv
    
    # Crear entorno virtual
    create_venv
    
    # Activar entorno
    source "$D2L_VENV/bin/activate"
    
    # Instalar todo
    upgrade_pip
    install_numpy
    install_pytorch
    install_d2l
    install_dependencies
    install_jupyter_packages
    
    # Verificar instalación
    verify_installation
    
    # Desactivar entorno
    deactivate
    
    # Añadir kernel de Jupyter si se solicitó
    if [ "$ADD_JUPYTER" = true ]; then
        source "$D2L_VENV/bin/activate"
        add_jupyter_kernel
        deactivate
    fi
}

# =============================================================================
# FUNCIONES DE RESUMEN
# =============================================================================

print_summary() {
    echo ""
    echo "[OK] Instalación completada con éxito."
    echo ""
    echo "--- Resumen de configuración:"
    echo "    * Python version: $PYTHON_REQUIRED"
    echo "    * D2L version: $D2L_VERSION"
    echo "    * NumPy version: $NUMPY_VERSION"
    echo "    * PyTorch version: $TORCH_VERSION"
    echo "    * Torchvision version: $TORCHVISION_VERSION"
    echo "    * Entorno: $D2L_VENV"
    
    if [ "$ADD_JUPYTER" = true ]; then
        echo "    * Kernel de Jupyter: configurado"
    fi
}

print_activation_instructions() {
    echo ""
    echo "==> Activa el entorno con:"
    echo "    source $D2L_VENV/bin/activate"
    echo ""
    echo "==> Para desactivar el entorno:"
    echo "    deactivate"
}

print_jupyter_instructions() {
    if [ "$ADD_JUPYTER" = true ]; then
        echo ""
        log_info "Para usar el kernel en Jupyter:"
        echo "    1. Inicia Jupyter: jupyter notebook"
        echo "    2. Crea un nuevo notebook"
        echo "    3. Selecciona 'Python (d2l-1.0.3)' desde: Kernel > Change kernel"
        echo ""
        log_info "Kernels disponibles:"
        jupyter kernelspec list 2>/dev/null || log_warning "Ejecuta desde el entorno para ver los kernels"
    fi
}

print_usage_example() {
    echo ""
    echo "[i] Ejemplo de uso rápido:"
    echo "    source $D2L_VENV/bin/activate"
    echo "    python"
    echo "    >>> import d2l"
    echo "    >>> import torch"
    echo "    >>> print(d2l.__version__)  # $D2L_VERSION"
    echo "    >>> print(torch.__version__)  # $TORCH_VERSION"
}

print_installation_reminder() {
    echo ""
    echo "[!] RECORDATORIO IMPORTANTE:"
    echo "    Si necesitas instalar librerías adicionales,"
    echo "    debes hacerlo DENTRO del entorno virtual:"
    echo ""
    echo "    source $D2L_VENV/bin/activate"
    echo "    pip install <nombre-libreria>"
    echo "    deactivate"
}

print_compatibility_note() {
    echo ""
    echo "[i] NOTA DE COMPATIBILIDAD:"
    echo "    Este entorno usa versiones específicas para garantizar"
    echo "    la compatibilidad con D2L 1.0.3:"
    echo "    - Python $PYTHON_REQUIRED (gestionado por pyenv)"
    echo "    - numpy==$NUMPY_VERSION (requerido)"
    echo "    - torch==$TORCH_VERSION"
    echo "    - torchvision==$TORCHVISION_VERSION"
    echo "    - d2l==$D2L_VERSION"
    echo ""
    echo "    No actualices estas versiones a menos que sea necesario."
}

print_goodbye() {
    echo ""
    echo "  (˶ᵔ ᵕ ᵔ˶) ¡Feliz aprendizaje con D2L!"
    echo ""
}

# =============================================================================
# FUNCIÓN PRINCIPAL
# =============================================================================

main() {
    print_header
    
    # Selección de modo
    prompt_mode_selection
    
    # Detección del sistema (ahora incluye pyenv y Python 3.9)
    detect_python
    
    if [ "$MODE" = "remove" ]; then
        # Modo eliminación
        detect_existing_venv
        remove_venv
        print_removal_summary
    else
        # Modo instalación
        prompt_jupyter_configuration
        
        # Detección de hardware
        detect_gpu
        
        # Instalación del entorno D2L
        install_d2l_environment
        
        # Resumen e instrucciones finales
        print_summary
        print_activation_instructions
        print_jupyter_instructions
        print_usage_example
        print_installation_reminder
        print_compatibility_note
        print_goodbye
    fi
}

# =============================================================================
# PUNTO DE ENTRADA
# =============================================================================

main "$@"