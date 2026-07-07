# 🧰 Mantenix v3.1

**Autor:** [RichyKunBv](https://github.com/RichyKunBv)  
**Repositorio:** `Mantenix-Windows-Edition`  
**Versión Actual:** 3.1

---

### 🖥️ ¿Qué es Mantenix?

**Mantenix** es una suite de herramientas todo-en-uno para el mantenimiento de Windows, diseñada para ser potente, inteligente y fácil de usar. Agrupa múltiples utilidades del sistema en un menú interactivo, ideal para limpiar, optimizar y asegurar tu PC sin necesidad de instalar software adicional.

---

### ✨ Características Principales de la v3.1

* **Optimización Inteligente:** Mantenix detecta automáticamente si tus unidades de almacenamiento son **HDD o SSD**. Aplica la desfragmentación tradicional a los discos duros y la optimización TRIM (más segura y recomendada) a las unidades de estado sólido.
* **Ejecución Segura:** Comprueba si tiene permisos de administrador al inicio y, si no, intenta re-lanzarse para asegurar que todas las funciones operen correctamente.
* **Herramientas Avanzadas:** Incluye un módulo con herramientas para gestionar programas de arranque, limpiar drivers antiguos, mejorar tu privacidad y activar el plan de máximo rendimiento.
* **Actualizador Integrado:** Revisa si hay nuevas versiones en GitHub y te permite actualizar la aplicación fácilmente.
* **Experiencia Mejorada:** Añade secciones para revisión del sistema, limpieza básica, limpieza completa, análisis completo y un historial de actualizaciones más completo.

---

### 🚀 Instrucciones de Uso

1.  Ve a la sección de **[Releases](https://github.com/RichyKunBv/Mantenix-Windows-Edition/releases/latest)** y descarga la última versión disponible. El script original está en `MantenixW.bat` y, cuando se publique, también encontrarás el archivo compilado `Mantenix.exe` en las Releases.
2.  Tu navegador podría mostrar una advertencia de seguridad por ser un archivo poco común. Simplemente haz clic en los tres puntos y selecciona "Conservar". ¡Es seguro!

    ![Advertencia de descarga del navegador](https://github.com/user-attachments/assets/8ab94073-82e5-4c8f-8468-c8b43dbb173a)

3.  Haz clic derecho en el archivo descargado y selecciona **"Ejecutar como administrador"**.
4.  Si aparece la pantalla de seguridad de Windows, haz clic en "Más información" y luego en "Ejecutar de todas formas".

    ![Advertencia de Windows SmartScreen](https://github.com/user-attachments/assets/bb2ebf9f-cb0d-44e8-ab16-d6dfedcac843)
5.  ¡Listo! Navega por el menú usando los números y sigue las instrucciones en pantalla.

---

### 📋 Opciones del Menú v3.1

<img width="591" height="508" alt="image" src="https://github.com/user-attachments/assets/4a3f1967-acda-4cbc-a348-4ec2a8f129c6" />


#### 1. ✅ Revisión del sistema
Ejecuta `sfc /scannow` y `DISM` para analizar y reparar la integridad de los archivos esenciales de Windows.

#### 2. 🔧 Limpieza básica
Realiza una optimización inteligente de tus discos (Defrag para HDD, TRIM para SSD) y una comprobación de errores del sistema de archivos con `chkdsk`.

#### 3. 🧼 Limpieza completa
Una rutina más profunda que elimina archivos temporales, restablece la configuración de red (DNS, Firewall, etc.) y crea un punto de restauración para mayor seguridad.

#### 4. 🔍 Análisis completo
Ejecuta de forma secuencial y automatizada todas las tareas de revisión y limpieza (1, 2 y 3).

#### 5. 🛠️ Herramientas Avanzadas
Abre un sub-menú con nuevas y potentes utilidades:
* **Gestor de Arranque:** Lista los programas que inician con Windows y te da acceso a las herramientas del sistema para gestionarlos.
* **Limpieza de Drivers:** Lanza la utilidad de Windows para eliminar de forma segura paquetes de controladores antiguos y liberar espacio.
* **Módulo de Privacidad:** Aplica cambios para reducir la telemetría y recolección de datos de Windows.
* **Máximo Rendimiento:** Activa el plan de energía de alto rendimiento para mejorar el comportamiento del sistema.

#### 6. ⬆️ Actualizar Mantenix
Comprueba si hay una nueva versión en GitHub y te guía en el proceso de actualización.

#### 7. ℹ️ Acerca de
Muestra información básica del proyecto y del autor.

#### 8. 📝 Historial de actualizaciones
Muestra los cambios más relevantes de cada versión.

#### 9. 🚪 Salir
Cierra el programa y abre la página del proyecto en GitHub.

<img width="576" height="332" alt="image" src="https://github.com/user-attachments/assets/9fdefb35-1869-4131-8d54-d592ac695942" />


#### 7. 🚪 Salir
Cierra el programa y abre la página del proyecto en GitHub.

---

### ⚠️ Notas Importantes

* **Ejecutar como Administrador:** Es crucial para que las herramientas de sistema funcionen correctamente.
* **Puntos de Restauración:** La limpieza completa crea un punto de restauración, pero siempre es buena idea tener un respaldo de tus datos importantes.
* **Diferencia entre `.bat` y `.exe`:**
    * `MantenixW.bat`: Es el script de código abierto. Su actualizador es **totalmente automático** (se reemplaza a sí mismo).
    * `Mantenix.exe`: Es el archivo compilado para mayor comodidad. Se publica en las **Releases** del repositorio y, por seguridad y para evitar falsos positivos de antivirus, su actualizador **descarga la nueva versión** en tu carpeta de "Descargas" y te avisa para que tú la reemplaces manualmente.
* **Conexión a Internet:** La función de actualizar necesita conexión a internet para contactar con GitHub.

---

<details>
<summary>TESTS</summary>

## Entornos de Prueba

Este proyecto ha sido probado y verificado en las siguientes configuraciones de hardware y software:

| Sistema Operativo | Arquitectura / CPU | Memoria RAM | Notas |
| :--- | :--- | :--- | :--- |
| Windows 11 Home | x86_64 / i7-1255U | 16 GB |   |
| Windows 10 Pro | x86_64 / i5-4200M | 16 GB | Actualizaciones de Seguridad Extendidas |
| Windows 10 Pro | x86_64 / i5-3230M | 12 GB | Actualizaciones de Seguridad Extendidas |
| Windows 11 Pro | ARM / M1 | 4 GB | Maquina virtual VMware Fusion |

</details>