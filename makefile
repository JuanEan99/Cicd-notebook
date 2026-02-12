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


HF  := $(PY) -m huggingface_hub.cli
# ---- targets ---------------------------------------------------

install:
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

format:
	$(PY) -m black *.py
	black . --exclude venv || true

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
# CAMBIA por tu space
SPACE := JuanEan99/Drug-Classification

push-hub:
	@if not exist App    (echo [ERROR] Falta carpeta App    && exit 1)
	@if not exist Model  (echo [ERROR] Falta carpeta Model  && exit 1)
	@if not exist Results (echo [ERROR] Falta carpeta Results && exit 1)
	rem Crea el Space si no existe (idempotente)
	$(HF) repo create $(SPACE) --type space --space-sdk gradio || echo Repo ya existe
	rem Subidas (CLI nueva)
	$(HF) upload --repo $(SPACE) --repo-type space --path-in-repo App     App     -m "Sync App files"
	$(HF) upload --repo $(SPACE) --repo-type space --path-in-repo Model   Model   -m "Sync Model"
	$(HF) upload --repo $(SPACE) --repo-type space --path-in-repo Metrics Results -m "Sync Metrics"

deploy: hf-login push-hub

all: install format train eval update-branch deploy
# ----------------------------------------------------------------