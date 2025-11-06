# D2L Environment Manager

> Gestor automatizado de entornos virtuales para **Dive into Deep Learning (D2L)**

Script en Bash que configura automáticamente un entorno virtual optimizado para trabajar con el libro [Dive into Deep Learning](https://d2l.ai/) usando versiones específicas y compatibles de Python, PyTorch y D2L.

## Características

-  Instalación automática de un entorno virtual para D2L
-  Detección automática de GPU NVIDIA (instalación con CUDA o CPU)
-  Gestión de versiones de Python mediante **pyenv**
-  Configuración opcional de kernel para Jupyter Notebook
-  Verificación de la instalación con diagnóstico completo
-  Modo de eliminación del entorno

## Requisitos previos

### 1. pyenv (obligatorio)

El script requiere **pyenv** para gestionar la versión de Python.

**Instalación en Linux/macOS:**
```bash
curl https://pyenv.run | bash
```

**Configuración del shell (~/.bashrc, ~/.zshrc):**
```bash
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
```

**Verificar instalación:**
```bash
pyenv --version
```

📚 Más información: [https://github.com/pyenv/pyenv#installation](https://github.com/pyenv/pyenv#installation)

### 2. Python 3.9 (obligatorio)

El entorno requiere **Python 3.9.x** instalado en pyenv.

**Instalar Python 3.9:**
```bash
# Ver versiones disponibles de Python 3.9
pyenv install --list | grep " 3.9"

# Instalar la última versión de Python 3.9 (ejemplo: 3.9.18)
pyenv install 3.9.18
```

**Verificar instalación:**
```bash
pyenv versions | grep 3.9
```

### 3. Requisitos opcionales

- **CUDA Toolkit** (opcional): Para aprovechar GPU NVIDIA
- **Jupyter** (opcional): Si ya lo tienes instalado globalmente, puedes usarlo

## 🔧 Versiones instaladas

El script instala las siguientes versiones específicas para garantizar compatibilidad:

| Paquete | Versión |
|---------|---------|
| Python | 3.9.x |
| NumPy | 1.26.4 |
| PyTorch | 2.0.0 |
| Torchvision | 0.15.1 |
| D2L | 1.0.3 |

## 🚀 Instalación

### 1. Clonar o descargar el script

```bash
# Clonar el repositorio
git clone https://github.com/elpeloncho/D2L-Environment-Manager.git
cd d2l-installer
```

### 2. Dar permisos de ejecución

```bash
chmod +x d2l-installer.sh
```

### 3. Ejecutar el script

```bash
./d2l-installer.sh
```

## Uso

### Modo instalación

Al ejecutar el script, selecciona la opción `1) Instalar entorno D2L`:

```bash
./d2l-installer.sh
```

El script te guiará a través de:
1. Verificación de pyenv
2. Verificación de Python 3.9
3. Configuración opcional de kernel Jupyter
4. Detección de GPU
5. Instalación de paquetes
6. Verificación de instalación

### Modo eliminación

Para eliminar el entorno, selecciona la opción `2) Eliminar entorno D2L`:

```bash
./d2l-installer.sh
# Seleccionar opción 2
```

## Activar y usar el entorno

### Activar el entorno virtual

```bash
source .d2l_venv/bin/activate
```

### Usar Python y D2L

```python
python
>>> import d2l
>>> import torch
>>> print(d2l.__version__)  # 1.0.3
>>> print(torch.__version__) # 2.0.0
>>> print(torch.cuda.is_available())  # True si tienes GPU
```

### Desactivar el entorno

```bash
deactivate
```

## Usar con Jupyter Notebook

Si configuraste el kernel de Jupyter durante la instalación:

1. **Iniciar Jupyter:**
   ```bash
   jupyter notebook
   ```

2. **Crear un nuevo notebook**

3. **Seleccionar el kernel:**
   - Ve a: `Kernel` → `Change kernel` → `Python (d2l-1.0.3)`

### Ver kernels disponibles

```bash
jupyter kernelspec list
```

## Instalar paquetes adicionales

Si necesitas instalar librerías adicionales, hazlo **dentro del entorno virtual**:

```bash
source .d2l_venv/bin/activate
pip install nombre-paquete
deactivate
```

## Errores comunes

### Error: "pyenv no está instalado"

```bash
# Instalar pyenv
curl https://pyenv.run | bash

# Añadir a ~/.bashrc o ~/.zshrc
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Recargar shell
source ~/.bashrc  # o source ~/.zshrc
```

### Error: "Python 3.9.x no está instalado en pyenv"

```bash
# Ver versiones disponibles
pyenv install --list | grep " 3.9"

# Instalar (ejemplo con 3.9.18)
pyenv install 3.9.18

# Verificar
pyenv versions
```

### Error: "CUDA not available" (teniendo GPU NVIDIA)

Verifica que tengas los drivers de NVIDIA y CUDA Toolkit instalados:

```bash
nvidia-smi
```

Si no funciona, instala los drivers NVIDIA correspondientes a tu sistema operativo.

## Estructura del proyecto

```
.
├── d2l-installer.sh       # Script principal
├── README.md              # Este archivo
└── .d2l_venv/            # Entorno virtual (se crea al ejecutar)
    ├── bin/
    ├── lib/
    └── ...
```

## Notas de compatibilidad

- Las versiones instaladas están **fijadas** para garantizar compatibilidad con D2L 1.0.3
- **No actualices** numpy, torch o d2l a menos que sepas lo que haces
- El script usa Python 3.9 específicamente por compatibilidad con PyTorch 2.0.0


## Licencia

Este proyecto está bajo la licencia MIT. Ver el archivo `LICENSE` para más detalles.

## Fuentes

- [Dive into Deep Learning](https://d2l.ai/) - El libro de Deep Learning de código abierto
- [PyTorch](https://pytorch.org/) - Framework de Deep Learning
- [pyenv](https://github.com/pyenv/pyenv) - Gestor de versiones de Python

---

** Si este script te fue útil, considera darle una estrella en GitHub!**