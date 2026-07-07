@echo off
setlocal enabledelayedexpansion
title Mantenix v3.1.1 Beta - por RichyKunBv
color 0A

REM --- ========================================================== ---
REM ---                 VARIABLE DE VERSION UNICA                  ---
REM --- ========================================================== ---
set "AppVersion=3.1.1"


REM --- ========================================================== ---
REM ---        COMPROBACION INICIAL DE PERMISOS (ADMIN)            ---
REM --- ========================================================== ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] ADVERTENCIA: Se requieren permisos de Administrador.
    echo     Intentando re-lanzar Mantenix...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit
)


REM --- ========================================================== ---
REM ---          OBTENCION DE INFORMACION DEL SISTEMA              ---
REM --- ========================================================== ---
set "osName="
for /f "tokens=3*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "ProductName"') do set "osName=%%a %%b"
set "winBuild="
for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "CurrentBuildNumber"') do set "winBuild=%%v"

REM --- Verificar que sea Windows 10 o superior (build 10240+) ---
if defined winBuild (
    if %winBuild% LSS 10240 (
        echo [ERROR] Mantenix v%AppVersion% solo es compatible con Windows 10 y Windows 11.
        echo         Se ha detectado: %osName% ^(Build %winBuild%^)
        echo         El programa se cerrara.
        pause
        exit /b 1
    )
)

REM --- Ajustar nombre para Windows 11 ---
if defined winBuild if %winBuild% GEQ 22000 set "osName=%osName:10=11%"


:MENU
cls
echo =============================================================
echo                  MANTENIX v%AppVersion% Beta
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
echo -------------------- FUNCIONES EXTRAS -----------------------
echo.
echo   5. Herramientas Avanzadas
echo.
echo -------------------------------------------------------------
echo.
echo   6. Actualizar Mantenix
echo   7. Acerca de
echo   8. Historial de actualizaciones
echo   9. Salir
echo.
set /p opcion=Selecciona una opcion:

if "%opcion%"=="1" (
    call :REVISION
    call :TAREA_FINALIZADA
    goto MENU
)
if "%opcion%"=="2" (
    call :LIMPIEZA_BASICA
    call :TAREA_FINALIZADA
    goto MENU
)
if "%opcion%"=="3" (
    call :LIMPIEZA_COMPLETA
    call :REINICIAR_WINUP
    call :TAREA_FINALIZADA --no-pause
    goto MENU
)
if "%opcion%"=="4" (
    call :ANALISIS_COMPLETO
    goto MENU
)
if "%opcion%"=="5" goto HERRAMIENTAS_AVANZADAS
if "%opcion%"=="6" goto ACTUALIZAR
if "%opcion%"=="7" goto ACERCA_DE
if "%opcion%"=="8" goto HISTORIAL_ACTUALIZACIONES
if "%opcion%"=="9" goto SALIR
goto MENU


:REVISION
cls
echo [TAREA] Revision del sistema: comprobando integridad...
sfc /scannow
echo Revisando imagen de Windows...
DISM /Online /Cleanup-Image /CheckHealth
DISM /Online /Cleanup-Image /RestoreHealth
exit /b

:REINICIAR_WINUP
echo [INFO] Reiniciando servicios de actualizacion de Windows...
net stop wuauserv
net stop cryptSvc
net stop bits
net stop msiserver

ren C:\Windows\SoftwareDistribution SoftwareDistribution.old
ren C:\Windows\System32\catroot2 catroot2.old

net start wuauserv
net start cryptSvc
net start bits
net start msiserver
exit /b         


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

        for /f "delims=" %%t in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Get-PhysicalDisk | Where-Object { $_.DeviceId -eq (Get-Partition -DriveLetter '%%d').DiskNumber } | Select-Object -ExpandProperty MediaType } catch { Write-Host 'UNKNOWN' }"') do (
            set "driveType=%%t"
        )

        if /i "!driveType!"=="SSD" (
            echo [OK]   Unidad %%d: es un SSD. Se optimizara con TRIM.
            defrag %%d: /L /O
        ) else if /i "!driveType!"=="HDD" (
            echo [OK]   Unidad %%d: es un HDD. Se desfragmentara.
            defrag %%d: /O
        ) else (
            echo [WARN] No se pudo determinar el tipo de la unidad %%d:. Se aplicara optimizacion generica.
            defrag %%d: /O
        )

        echo [INFO] Realizando chequeo de errores en la unidad %%d:...
        chkdsk %%d: /scan
        echo.
    )
)
exit /b


:LIMPIEZA_COMPLETA
cls
echo [TAREA] Limpieza completa: temporales, red, firewall y mas...
echo.
REM --- Comprobacion Inteligente de Bateria ---
echo [INFO] Verificando estado de la alimentacion electrica...
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue) { $chargeStatus = (Get-CimInstance -ClassName Win32_Battery).BatteryStatus; if ($chargeStatus -ne 2) { Write-Host '[!] ADVERTENCIA: La laptop esta funcionando con bateria.' } else { Write-Host '[OK]   La laptop esta conectada a la corriente.' } } else { Write-Host '[OK]   PC de escritorio detectada.' }"
echo.
echo Restableciendo DNS y red...
ipconfig /flushdns & netsh int ip reset & netsh winsock reset & netsh advfirewall reset
echo Ejecutando Liberador de espacio...
cleanmgr /sagerun:1
echo Borrando temporales...
del /s /q %temp%\*.* 2>nul & del /s /q C:\Windows\Temp\*.* 2>nul
echo Creando punto de restauracion...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Checkpoint-Computer -Description 'Mantenix - Limpieza Completa' -RestorePointType MODIFY_SETTINGS" >nul 2>&1
echo Verificando procesos y arranque...
tasklist | findstr /I /C:"malware" /C:"virus"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_StartupCommand | Select-Object Caption, Command, User | Format-Table -AutoSize"
echo Comprobando estado fisico del disco...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PhysicalDisk | ForEach-Object { Write-Host \"$($_.FriendlyName): $($_.OperationalStatus)\" }"
exit /b


:ANALISIS_COMPLETO
cls
echo [TAREA] Analisis completo: ejecutando TODO el mantenimiento...
echo.
call :REVISION
call :LIMPIEZA_BASICA
call :LIMPIEZA_COMPLETA
call :REINICIAR_WINUP
call :TAREA_FINALIZADA --no-pause
exit /b


:TAREA_FINALIZADA
echo.
echo [OK] Tarea finalizada.
if /i "%~1"=="--no-pause" (
    exit /b
)
pause
exit /b



:HERRAMIENTAS_AVANZADAS
cls
echo =============================================================
echo                       HERRAMIENTAS AVANZADAS
echo =============================================================
echo.
echo   1. Gestor de Programas de Arranque
echo   2. Limpieza de Drivers Antiguos
echo   3. Modulo de Privacidad
echo   4. Activar Maximo Rendimiento
echo.
echo   5. Volver al Menu Principal
echo.
set /p "adv_opcion=Selecciona una opcion: "
if "%adv_opcion%"=="1" goto STARTUP_MANAGER
if "%adv_opcion%"=="2" goto DRIVER_CLEANER
if "%adv_opcion%"=="3" goto PRIVACY_MODULE
if "%adv_opcion%"=="4" goto MAXIMO_RENDIMIENTO
if "%adv_opcion%"=="5" goto MENU
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
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_StartupCommand | Select-Object Caption, Command, User, Location | Format-Table -AutoSize"
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
if /i not "%doDriverClean%"=="S" (
    if /i not "%doDriverClean%"=="SI" goto HERRAMIENTAS_AVANZADAS
)
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
if /i not "%doPrivacy%"=="S" (
    if /i not "%doPrivacy%"=="SI" goto HERRAMIENTAS_AVANZADAS
)
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
echo [OK]   Configuraciones de privacidad aplicadas con exito!
echo [INFO] Se recomienda reiniciar el equipo para que todos los
echo        cambios surtan efecto.
echo.
pause
goto HERRAMIENTAS_AVANZADAS


:MAXIMO_RENDIMIENTO
cls
echo =============================================================
echo                ACTIVAR MAXIMO RENDIMIENTO
echo =============================================================
echo.
echo [INFO] Esta opcion ajustara la configuracion de energia de Windows
echo        al plan de "Maximo Rendimiento".
echo.
set /p "doRendimiento=Deseas continuar? (S/N): "
if /i not "%doRendimiento%"=="S" (
    if /i not "%doRendimiento%"=="SI" goto HERRAMIENTAS_AVANZADAS
)
echo.
echo [INFO] Intentando activar plan "Maximo Rendimiento"...
powercfg /setactive e9a42be2-d5df-448d-aa00-03f14749eb61 >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Plan Maximo Rendimiento activado.
    goto :RendimientoFin
)
echo [WARN] El plan Maximo Rendimiento no esta disponible. Intentando anadirlo...
powercfg -duplicatescheme e9a42be2-d5df-448d-aa00-03f14749eb61 >nul 2>&1
if %errorlevel% equ 0 (
    powercfg /setactive e9a42be2-d5df-448d-aa00-03f14749eb61 >nul 2>&1
    echo [OK] Plan Maximo Rendimiento anadido y activado.
    goto :RendimientoFin
)

echo [INFO] No se pudo habilitar Maximo Rendimiento.
echo        Activando plan "Alto Rendimiento" en su lugar...
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Plan Alto Rendimiento activado.
) else (
    echo [ERROR] No se pudo activar ningun plan de alto rendimiento.
)


:RendimientoFin
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
set "versionFileURL=%repoURL%/versionBETA.txt"
set "scriptFileURL=%repoURL%/MantenixWbeta.bat"
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


:ACERCA_DE
cls
echo =============================================================
echo                         ACERCA DE
echo =============================================================
echo.
echo   Mantenix v%AppVersion%
echo   Desarrollado por: RichyKunBv
echo   GitHub: https://github.com/RichyKunBv/Mantenix-Windows-Edition
echo.
echo   Mantenix es una suite de herramientas todo-en-uno para el
echo   mantenimiento de Windows, disenada para ser potente, inteligente
echo   y facil de usar. Agrupa multiples utilidades del sistema en un
echo   menu interactivo, ideal para limpiar, optimizar y asegurar 
echo   tu PC sin necesidad de instalar software adicional.
echo.
pause
goto MENU


:HISTORIAL_ACTUALIZACIONES
cls
echo =============================================================
echo                 HISTORIAL DE ACTUALIZACIONES
echo =============================================================
echo.
echo   v3.1 - Se mejoro la estructura y puedes activar el maxmio rendimiento
echo   v3.0 - Herramientas avanzadas y aplicacion mas inteligente
echo   v2.1 - Autoactualizacion de la aplicacion
echo   v2.0 - Se agrego el menu para facilitar el uso
echo   v1.2 - Mejorado y automatizado
echo.
echo   Consulta el registro completo en el repositorio oficial.
echo.
pause
goto MENU


:SALIR
echo Saliendo del programa...
start https://github.com/RichyKunBv/Mantenix-Windows-Edition
timeout /t 2 >nul
exit
