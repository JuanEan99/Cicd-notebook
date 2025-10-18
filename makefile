# ---------- Makefile cross-platform (Windows / Linux) ----------
.PHONY: install format train eval update-branch hf-login push-hub deploy all

# =========================================================
# Forzar shell de Windows (cmd.exe)
# =========================================================
SHELL := cmd.exe
.SHELLFLAGS := /C

# Detectar SO y definir rutas/comandos
ifeq ($(OS),Windows_NT)
PY := .venv\Scripts\python.exe
PIP := .venv\Scripts\pip.exe
CAT := type
ECHO_NL := echo.
else
PY := python3
PIP := $(PY) -m pip
CAT := cat
ECHO_NL := echo ""
endif


# --- utilidades cross-platform ---
ifeq ($(OS),Windows_NT)
CAT := type
NL  := echo.
SEP := \        # separador de Windows
else
CAT := cat
NL  := echo ""
SEP := /        # separador de Linux/Mac
endif

# ---- targets ---------------------------------------------------

install:
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

format:
	$(PY) -m black *.py

train:
	$(PY) train.py

# Generar report.md con métricas e imagen (Windows cmd.exe)
eval:
	rem 1) título
	echo ## Model Metrics > report.md
	rem 2) anexar métricas
	type Results\metrics.txt >> report.md
	rem 3) línea en blanco
	echo. >> report.md
	rem 4) título de la imagen
	echo ## Confusion Matrix Plot >> report.md
	rem 5) markdown de la imagen (usa ruta sin comillas)
	echo ![Confusion Matrix](Results\model_results.png) >> report.md
	rem 6) mensaje final (opcional)
	echo Reporte generado en report.md >> report.md

# (Opcional) Commit/push resultados a rama update
update-branch:
	git config --global user.name $(USER_NAME)
	git config --global user.email $(USER_EMAIL)
	git add -A
	git commit -m "Update with new results" || echo "Nada que commitear"
	git push --force origin HEAD:update

# ---- Hugging Face CLI -----------------------------------------
# Login (usa secreto HF si vas en CI, o te pedirá el token en local)
hf-login:
	$(PIP) install -U "huggingface_hub[cli]"
	# En Windows la CLI queda en .venv\Scripts\huggingface-cli.exe
	# Puedes ejecutar: .venv\Scripts\huggingface-cli.exe login --add-to-git-credential
	# En Linux/macOS: huggingface-cli login --add-to-git-credential

# Sube App, Modelo y Métricas a tu Space (cambia el owner/nombre!)
push-hub:
	# Reemplaza usuario/Space por el tuyo, p.ej.: JuanEan99/Drug-Classification
	.venv\Scripts\huggingface-cli.exe upload JuanEan99/Drug-Classification ./App --repo-type=space --commit-message="Sync App files"
	.venv\Scripts\huggingface-cli.exe upload JuanEan99/Drug-Classification ./Model /Model --repo-type=space --commit-message="Sync Model"
	.venv\Scripts\huggingface-cli.exe upload JuanEan99/Drug-Classification ./Results /Metrics --repo-type=space --commit-message="Sync Metrics"

deploy: hf-login push-hub

all: install format train eval update-branch deploy
# ----------------------------------------------------------------