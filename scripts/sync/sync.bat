@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

goto :main

:: ============================================
:: Mini sincronización de repositorio Git
:: Versión para Windows (.bat)
:: ============================================

:ensure_repos_dir
if not exist "%repos_base%" (
    echo Creando carpeta predeterminada de repositorios en %repos_base%...
    mkdir "%repos_base%"
)
goto :eof

:detect_repository_location
if exist "%repos_base%\%nombre%\.git" (
    set "ubicacion=%repos_base%\%nombre%"
) else if exist "%old_location%\.git" (
    call :ensure_repos_dir
    if exist "%repos_base%\%nombre%" (
        echo Existe un repositorio en %old_location% y también en %repos_base%\%nombre%.
        echo Por favor mueve manualmente el contenido o elimina uno de ellos.
        exit /b 1
    )
    echo Moviendo repositorio existente de %old_location% a %repos_base%\%nombre%...
    move "%old_location%" "%repos_base%\"
    set "ubicacion=%repos_base%\%nombre%"
) else (
    set "ubicacion=%repos_base%\%nombre%"
)
goto :eof

:descargar
if not exist "%ubicacion%" (
    echo No se encontró la carpeta del repositorio.
    goto :eof
)
cd /d "%ubicacion%"
echo Obteniendo últimos cambios del repositorio...
git pull origin main --rebase
if errorlevel 1 (
    echo Error al obtener los cambios. Revisa tu conexión o posibles conflictos.
) else (
    echo Actualización exitosa.
)
goto :eof

:publicar
if not exist "%ubicacion%" (
    echo No se encontró la carpeta del repositorio.
    goto :eof
)
cd /d "%ubicacion%"

:: Comprobar si hay cambios
git status --porcelain | findstr "." >nul
if errorlevel 1 (
    echo No hay cambios para publicar. Ya está actualizado.
    goto :eof
)

git add .
set /p mensaje="    >> Introduce el mensaje del commit: "
if "%mensaje%"=="" (
    echo El mensaje no puede estar vacío. Cancelando publicación...
    goto :eof
)

git commit -m "%mensaje%"

git pull origin main --rebase
if errorlevel 1 (
    echo Error al obtener cambios remotos durante la publicación.
    goto :eof
)

git push origin main
if errorlevel 1 (
    echo Error al publicar. Revisa el mensaje de error y vuelve a intentarlo.
) else (
    echo Publicación exitosa.
)
goto :eof

:configurar
cls
echo === Clonar y Configurar Entorno de %nombre% ===
call :ensure_repos_dir

if not exist "%ubicacion%\.git" (
    echo.
    echo Descargando el código en %repos_base%...
    cd /d "%repos_base%"
    git clone %repo_url% "%nombre%"
    if errorlevel 1 (
        echo Error al clonar el repositorio.
        goto :eof
    )
) else (
    echo.
    echo La carpeta ya existe en %ubicacion%. Saltando la clonación...
)

cd /d "%ubicacion%"
if errorlevel 1 (
    echo Error al entrar a la carpeta.
    goto :eof
)

echo.
echo Configurando editor...
git config --global core.editor "notepad"

echo.
echo Entorno de %nombre% configurado y listo para programar.
echo Nota: Al hacer tu primer 'push', te pedirá credenciales.
echo Utiliza un Personal Access Token (PAT) de GitHub como contraseña.
goto :eof

:clonar
call :ensure_repos_dir

if exist "%ubicacion%\.git" (
    echo El repositorio ya está clonado en %ubicacion%.
    goto :eof
)

echo.
echo Clonando el repositorio en %repos_base%...
cd /d "%repos_base%"
git clone %repo_url% "%nombre%"
if errorlevel 1 (
    echo Error al clonar el repositorio.
) else (
    echo Clonación exitosa.
)
goto :eof

:press_any_key
echo.
pause
goto :eof

:show_menu
cls
echo     1^) Actualizar local (Pull)
echo     2^) Actualizar el repo (Push)
echo     0^) Configurar
echo     9^) Clonar
echo     X^) Salir
set /p choice="    >> Introduce tu elección: "
echo.
if /i "%choice%"=="1" (
    call :descargar
    call :press_any_key
) else if /i "%choice%"=="2" (
    call :publicar
    call :press_any_key
) else if /i "%choice%"=="0" (
    call :configurar
    call :press_any_key
) else if /i "%choice%"=="9" (
    call :clonar
    call :press_any_key
) else if /i "%choice%"=="X" (
    echo Saliendo...
    exit /b 0
) else (
    echo Opción inválida. Intenta de nuevo.
    timeout /t 2 >nul
)
goto :eof

:: ============================================
:: Programa principal
:: ============================================
:main
set "nombre=Mantenix-Windows-Edition"
set "repos_base=%USERPROFILE%\Repos"
set "old_location=%USERPROFILE%\%nombre%"
set "ubicacion="

set "repo_url=https://github.com/RichyKunBv/%nombre%.git"

call :detect_repository_location

:menu_loop
call :show_menu
if /i "%choice%"=="X" exit /b 0
goto menu_loop