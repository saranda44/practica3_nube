#!/bin/bash
set -e

SRC_DIR="src"
BUILD_ROOT="build"
PYTHON_BIN="python3"

rm -rf "$BUILD_ROOT"
mkdir -p "$BUILD_ROOT"

for func in "$SRC_DIR"/*; do
  if [ -d "$func" ]; then
    FUNC_NAME=$(basename "$func")

    # Saltar db_utils
    if [ "$FUNC_NAME" = "db_utils" ]; then
      continue
    fi

    echo "Empaquetando $FUNC_NAME..."

    WORK_DIR="$BUILD_ROOT/$FUNC_NAME"
    VENV_DIR="$WORK_DIR/venv"
    PACKAGE_DIR="$WORK_DIR/package"

    mkdir -p "$PACKAGE_DIR"

    # Crear venv aislado
    $PYTHON_BIN -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"

    pip install --upgrade pip

    if [ -f "$func/requirements.txt" ]; then
      pip install -r "$func/requirements.txt"
    fi

    # Copiar dependencias al package dir
    SITE_PACKAGES=$(python -c "import site; print(site.getsitepackages()[0])")
    cp -r "$SITE_PACKAGES"/* "$PACKAGE_DIR"/

    # Copiar handler
    cp "$func/handler.py" "$PACKAGE_DIR"/

    # Copiar db_utils si existe
    if [ -f "$SRC_DIR/db_utils/db_utils.py" ]; then
      cp "$SRC_DIR/db_utils/db_utils.py" "$PACKAGE_DIR"/
    fi

    deactivate

    # Crear ZIP
    cd "$PACKAGE_DIR"
    zip -r9 "../../../$FUNC_NAME.zip" .
    cd - >/dev/null

    echo "$FUNC_NAME.zip creado correctamente"
  fi
done

echo "Empaquetado completo."
