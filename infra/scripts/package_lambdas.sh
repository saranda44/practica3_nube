#!/bin/bash
set -e

export AWS_PAGER=cat

SRC_DIR="src"
BUILD_ROOT="build"
PYTHON_BIN="python3.12"

mkdir -p "$BUILD_ROOT"

for func in "$SRC_DIR"/*; do
    if [ -d "$func" ]; then
        FUNC_NAME=$(basename "$func")

        # Saltar db_utils (no es una Lambda)
        if [ "$FUNC_NAME" = "db_utils" ]; then
            continue
        fi

        echo "Empaquetando $FUNC_NAME..."

        WORK_DIR="$BUILD_ROOT/$FUNC_NAME"
        CACHE_DIR="$WORK_DIR/deps"
        PACKAGE_DIR="$WORK_DIR/package"
        VENV_DIR="$WORK_DIR/venv"

        mkdir -p "$WORK_DIR"
        mkdir -p "$PACKAGE_DIR"

        REQ_FILE="$func/requirements.txt"
        HASH_FILE="$WORK_DIR/requirements.hash"

        # Calcular hash
        if [ -f "$REQ_FILE" ]; then
            NEW_HASH=$(sha256sum "$REQ_FILE" | awk '{print $1}')
        else
            NEW_HASH="no_requirements"
        fi

        OLD_HASH=""
        if [ -f "$HASH_FILE" ]; then
            OLD_HASH=$(cat "$HASH_FILE")
        fi

        # Reinstalar dependencias si cambian
        if [ "$NEW_HASH" != "$OLD_HASH" ]; then
            echo "  Instalando dependencias..."

            rm -rf "$CACHE_DIR" "$VENV_DIR"
            mkdir -p "$CACHE_DIR"

            if [ "$NEW_HASH" != "no_requirements" ]; then
                # Crear venv limpio
                $PYTHON_BIN -m venv "$VENV_DIR"
                source "$VENV_DIR/bin/activate"

                pip install --upgrade pip

                # ✅ instalación NORMAL (sin hacks)
                pip install -r "$REQ_FILE"

                # Obtener site-packages
                SITE_PACKAGES=$(python -c "import site; print(site.getsitepackages()[0])")

                # Copiar dependencias
                cp -a "$SITE_PACKAGES"/. "$CACHE_DIR"/

                deactivate
            fi

            echo "$NEW_HASH" > "$HASH_FILE"
        else
            echo "  Reutilizando dependencias en cache."
        fi

        # Preparar package
        rm -rf "$PACKAGE_DIR"
        mkdir -p "$PACKAGE_DIR"

        cp -a "$CACHE_DIR"/. "$PACKAGE_DIR"/ 2>/dev/null || true

        # Copiar handler
        cp "$func/handler.py" "$PACKAGE_DIR"/

        # Copiar db_utils
        if [ -f "$SRC_DIR/db_utils/db_utils.py" ]; then
            cp "$SRC_DIR/db_utils/db_utils.py" "$PACKAGE_DIR"/
        fi

        # Crear ZIP
        cd "$PACKAGE_DIR"
        zip -r9 "../../../$FUNC_NAME.zip" . > /dev/null
        cd - > /dev/null

        echo "✓ $FUNC_NAME.zip listo"
    fi
done

echo ""
echo "Empaquetado completo."
ls -lh *.zip 2>/dev/null || echo "No hay ZIPs"