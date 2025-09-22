@echo off
setlocal enabledelayedexpansion
title Mantenix v3.0 - por RichyKunBv
color 0A

REM --- ========================================================== ---
REM ---                 VARIABLE DE VERSI�N �NICA                  ---
REM --- ========================================================== ---
set "AppVersion=3.0"


REM --- ========================================================== ---
REM ---        COMPROBACI�N INICIAL DE PERMISOS (ADMIN)            ---
REM --- ========================================================== ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] ADVERTENCIA: Se requieren permisos de Administrador.
    echo     Intentando re-lanzar Mantenix...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit
)


REM --- ========================================================== ---
REM ---          OBTENCI�N DE INFORMACI�N DEL SISTEMA              ---
REM --- ========================================================== ---
set "osName="
for /f "tokens=3*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "ProductName"') do set "osName=%%a %%b"
set "winBuild="
for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "CurrentBuildNumber"') do set "winBuild=%%v"
if defined winBuild if %winBuild% GEQ 22000 set "osName=%osName:10=11%"


:MENU
cls
echo =============================================================
echo                       MANTENIX v%AppVersion%
echo =============================================================
echo.
echo   Editor: RichyKunBv
echo   Sistema: %osName% (Build %winBuild%)
echo   Pagina: https://github.com/RichyKunBv/Mantenix-Windows-Edition
echo.
echo -------------------- TAREAS PRINCIPALES ---------------------
echo.
echo   1. Revision del sistema
echo   2. Limpieza basica
echo   3. Limpieza completa
echo   4. Analisis completo
echo.
echo -------------------- NUEVAS FUNCIONES -----------------------
echo.
echo   5. Herramientas Avanzadas
echo.
echo -------------------------------------------------------------
echo.
echo   6. Actualizar Mantenix
echo   7. Salir
echo.
set /p opcion=Selecciona una opcion:

if "%opcion%"=="1" goto REVISION
if "%opcion%"=="2" goto LIMPIEZA_BASICA
if "%opcion%"=="3" goto LIMPIEZA_COMPLETA
if "%opcion%"=="4" goto ANALISIS_COMPLETO
if "%opcion%"=="5" goto HERRAMIENTAS_AVANZADAS
if "%opcion%"=="6" goto ACTUALIZAR
if "%opcion%"=="7" goto SALIR
goto MENU


:REVISION
cls
echo [TAREA] Revision del sistema: comprobando integridad...
sfc /scannow
echo Revisando imagen de Windows...
DISM /Online /Cleanup-Image /CheckHealth
DISM /Online /Cleanup-Image /RestoreHealth
echo. & echo [OK] Tarea de Revision completada. & pause & goto MENU


:LIMPIEZA_BASICA
cls
echo [TAREA] Limpieza basica: optimizando discos y checando errores...
echo.
set "drives_to_check=C D"
echo [INFO] Analizando tipos de unidad para optimizacion inteligente...
echo.
for %%d in (%drives_to_check%) do (
    if exist %%d:\ (
        echo [INFO] Comprobando unidad %%d:
        set "driveType=UNKNOWN"
        for /f "delims=" %%t in ('powershell -Command "try { Get-Partition -DriveLetter %%d | Get-PhysicalDisk | Select-Object -ExpandProperty MediaType } catch { Write-Host 'UNKNOWN' }"') do (
            set "driveType=%%t"
        )
        if /i "!driveType!"=="HDD" (
            echo [OK]   Unidad %%d: es un HDD. Se desfragmentara.
            defrag %%d: /O
        ) else if /i "!driveType!"=="SSD" (
            echo [OK]   Unidad %%d: es un SSD. Se optimizara con TRIM.
            defrag %%d: /L /O
        ) else (
            echo [WARN] No se pudo determinar el tipo de la unidad %%d:. Se omitira la optimizacion.
        )
        echo [INFO] Realizando chequeo de errores en la unidad %%d:...
        chkdsk %%d: /scan
        echo.
    )
)
echo. & echo [OK] Tarea de Limpieza Basica completada. & pause & goto MENU


:LIMPIEZA_COMPLETA
cls
echo [TAREA] Limpieza completa: temporales, red, firewall y mas...
echo.
REM --- Comprobaci�n Inteligente de Bater�a ---
echo [INFO] Verificando estado de la alimentacion electrica...
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue) { $chargeStatus = (Get-CimInstance -ClassName Win32_Battery).BatteryStatus; if ($chargeStatus -ne 2) { Write-Host '[!] ADVERTENCIA: La laptop esta funcionando con bateria.'; pause } else { Write-Host '[OK]   La laptop esta conectada a la corriente.' } } else { Write-Host '[OK]   PC de escritorio detectada.' }"
echo.
echo Restableciendo DNS y red...
ipconfig /flushdns & netsh int ip reset & netsh winsock reset & netsh advfirewall reset
echo Ejecutando Liberador de espacio...
cleanmgr /sagerun:1
echo Borrando temporales...
del /s /q %temp%\*.* 2>nul & del /s /q C:\Windows\Temp\*.* 2>nul
echo Creando punto de restauracion...
wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "Mantenix - Limpieza Completa", 100, 7
echo Verificando procesos y arranque...
tasklist | findstr /I /C:"malware" /C:"virus"
wmic startup get caption,command
echo Comprobando estado fisico del disco...
wmic diskdrive get status
echo. & echo [OK] Tarea de Limpieza Completa finalizada. & pause & goto MENU


:ANALISIS_COMPLETO
cls
echo [TAREA] Analisis completo: ejecutando TODO el mantenimiento...
echo.
call :REVISION
call :LIMPIEZA_BASICA
call :LIMPIEZA_COMPLETA
echo. & echo [OK] Analisis completo finalizado. & pause & goto MENU


:HERRAMIENTAS_AVANZADAS
cls
echo =============================================================
echo                       HERRAMIENTAS AVANZADAS
echo =============================================================
echo.
echo   1. Gestor de Programas de Arranque
echo   2. Limpieza de Drivers Antiguos
echo   3. Modulo de Privacidad
echo.
echo   4. Volver al Menu Principal
echo.
set /p "adv_opcion=Selecciona una opcion: "
if "%adv_opcion%"=="1" goto STARTUP_MANAGER
if "%adv_opcion%"=="2" goto DRIVER_CLEANER
if "%adv_opcion%"=="3" goto PRIVACY_MODULE
if "%adv_opcion%"=="4" goto MENU
goto HERRAMIENTAS_AVANZADAS

:STARTUP_MANAGER
cls
echo =============================================================
echo                GESTOR DE PROGRAMAS DE ARRANQUE
echo =============================================================
echo.
echo [!] ADVERTENCIA: Deshabilitar programas de arranque incorrectos
echo     puede afectar el funcionamiento de tu sistema o hardware.
echo.
echo [INFO] A continuacion se listan los programas que inician con Windows:
echo -------------------------------------------------------------
echo.
wmic startup get Caption, Command, User
echo.
echo -------------------------------------------------------------
echo.
echo [INFO] Para gestionar estos programas, puedes usar las siguientes
echo        herramientas de Windows:
echo.
echo   1. Abrir Administrador de Tareas (Pestana "Arranque") (Win 10/11)
echo   2. Abrir la Carpeta de Inicio del Usuario Actual
echo   3. Abrir la Carpeta de Inicio de Todos los Usuarios
echo.
echo   4. Volver al Menu Anterior
echo.
set /p "startup_opcion=Selecciona una opcion: "
if "%startup_opcion%"=="1" start ms-settings:startupapps
if "%startup_opcion%"=="2" explorer "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
if "%startup_opcion%"=="3" explorer "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Startup"
if "%startup_opcion%"=="4" goto HERRAMIENTAS_AVANZADAS
pause
goto STARTUP_MANAGER

:DRIVER_CLEANER
cls
echo =============================================================
echo                  LIMPIEZA DE DRIVERS ANTIGUOS
echo =============================================================
echo.
echo [!] ADVERTENCIA: Este proceso eliminara paquetes de controladores
echo     de dispositivos antiguos para liberar espacio en disco.
echo.
echo [INFO] Se utilizara la herramienta oficial de Windows para garantizar
echo        un proceso seguro.
echo.
set /p "doDriverClean=Deseas continuar? (S/N): "
if /i not "%doDriverClean%"=="S" goto HERRAMIENTAS_AVANZADAS
echo.
echo [INFO] Se abrira el Liberador de Espacio en Disco. Por favor,
echo        asegurate de marcar la casilla "Paquetes de controladores de dispositivo"
echo        y luego haz clic en Aceptar.
echo.
pause
cleanmgr /sageset:64
cleanmgr /sagerun:64
echo.
echo [OK]   Proceso iniciado. Windows limpiara los archivos en segundo plano.
echo.
pause
goto HERRAMIENTAS_AVANZADAS

:PRIVACY_MODULE
cls
echo =============================================================
echo                       MODULO DE PRIVACIDAD
echo =============================================================
echo.
echo [!] ADVERTENCIA: Este modulo aplicara cambios en el registro y
echo     servicios de Windows para reducir la recoleccion de datos
echo     (telemetria) por parte de Microsoft.
echo.
set /p "doPrivacy=Estas seguro de que deseas aplicar estos cambios? (S/N): "
if /i not "%doPrivacy%"=="S" goto HERRAMIENTAS_AVANZADAS
echo.
echo [INFO] Aplicando configuraciones de privacidad...
echo.
echo Deshabilitando Servicios de Telemetria...
sc config DiagTrack start= disabled >nul 2>&1
sc config dmwappushservice start= disabled >nul 2>&1
echo [OK]
echo.
echo Aplicando cambios en el Registro...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v CortanaEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK]
echo.
echo [OK]   �Configuraciones de privacidad aplicadas con exito!
echo [INFO] Se recomienda reiniciar el equipo para que todos los
echo        cambios surtan efecto.
echo.
pause
goto HERRAMIENTAS_AVANZADAS


:ACTUALIZAR
cls
echo =================================================
echo      BUSCANDO ACTUALIZACIONES PARA EL SCRIPT
echo =================================================
echo.
setlocal
set "localVersion=%AppVersion%"
set "repoUser=RichyKunBv"
set "repoName=Mantenix-Windows-Edition"
set "repoURL=https://raw.githubusercontent.com/%repoUser%/%repoName%/main"
set "versionFileURL=%repoURL%/version.txt"
set "scriptFileURL=%repoURL%/MantenixW.bat"
set "tempVersionFile=%temp%\latest_version.txt"
set "tempNewScriptFile=%temp%\MantenixW_new.bat"
echo [INFO] Comprobando conexion a internet...
ping -n 1 8.8.8.8 >nul 2>&1
if errorlevel 1 (echo [ERROR] No se detecto una conexion a internet. & goto EndUpdate)
echo [OK]   Conexion establecida.
echo.
echo [INFO] Version actual instalada: %localVersion%
echo [INFO] Obteniendo ultima version desde GitHub...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { (New-Object System.Net.WebClient).DownloadFile('%versionFileURL%', '%tempVersionFile%') } catch {}" >nul 2>&1
if not exist "%tempVersionFile%" (echo [ERROR] No se pudo obtener el archivo de version desde GitHub. & goto EndUpdate)
set /p latestVersion=<%tempVersionFile%
echo [INFO] Ultima version disponible: %latestVersion%
echo.
echo [INFO] Comparando versiones...
powershell -NoProfile -ExecutionPolicy Bypass -Command "if ([Version]'%latestVersion%' -gt [Version]'%localVersion%') { exit 1 } else { exit 0 }"
if not errorlevel 1 (echo [OK]   Ya tienes la ultima version o una superior. & goto EndUpdate)
echo [!] Se encontro una nueva version mas reciente (%latestVersion%)!
set /p "doUpdate=Deseas actualizar el script ahora? (S/N): "
if /i not "%doUpdate%"=="S" (echo [INFO] Actualizacion omitida por el usuario. & goto EndUpdate)
cls
echo =================================================
echo      ACTUALIZANDO SCRIPT...
echo =================================================
echo.
echo [+] Descargando script [%latestVersion%]...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { (New-Object System.Net.WebClient).DownloadFile('%scriptFileURL%', '%tempNewScriptFile%') } catch {}" >nul 2>&1
if not exist "%tempNewScriptFile%" (echo [ERROR] La descarga del script actualizado ha fallado. & goto EndUpdate)
echo [OK]   Descarga completada.
echo.
echo [INFO] La aplicacion se reiniciara para finalizar la actualizacion...
timeout /t 3 /nobreak >nul
(
    echo @echo off
    echo title Actualizando...
    echo echo Finalizando, por favor espera...
    echo timeout /t 1 /nobreak ^> nul
    echo copy /Y "%tempNewScriptFile%" "%~f0" ^> nul
    echo del "%tempNewScriptFile%" ^> nul
    echo del "%tempVersionFile%" ^> nul
    echo start "" "%~f0"
) > "%temp%\updater.bat"
start "" /B "%temp%\updater.bat"
exit
:EndUpdate
del "%tempVersionFile%" >nul 2>&1
echo.
pause
goto MENU


:SALIR
echo Saliendo del programa...
start https://github.com/RichyKunBv/Mantenix-Windows-Edition
timeout /t 2 >nul
exit