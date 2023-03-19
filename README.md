- Extraer IPV4 de una fuente de datos (texto, archivo, url)
- Extrar IPv6 (igual anterior)
- Geolocalizacion de las ips
- Opciones para remover duplicados, agrupar por region, veces que aparece la ip, etc
- Seleccion del reporte de datos en varios formatos: csv, json, texto...
- Escribir herramienta en bash y python

# Reglas para que una IPv4 sea valida

Any address that begins with a 0 is invalid (except as a default route).
Any address with a number above 255 in it is invalid.
Any address that has more than 3 dots is invalid.
Any address that begins with a number between 240 and 255 is reserved, and effectively invalid. (Theoretically, they’re usable, but I’ve never seen one in use.)
Any address that begins with a number between 224 and 239 is reserved for multicast, and probably invalid.
Any address that begins with one of the following, is private, and invalid in the public Internet, but you will frequently see them used for internal networks (Note: the \_s mean “anything between 0 & 255”) :

- 10._._.\_
- 172.16._._ through 172.31._._
- 192.168._._

# Tests

- Validar que puede recibir una cadena de texto
- Validar que puede recibir un archivo
- Validar que puede recibir una url y realizar peticion GET
- Comprobar que si se ejecuta sin argumentos se muestra un mensaje de error con la ayuda

# BUGS

Si se le pasa una fuente de datos ipv4 y usa el modo por defecto 'both' no se ejecuta el codigo despues de llamar a la funcion en el case 'both'
. WHAT THE HELL

# IMPROVEMENTS

    Añadir una comprobación de versión de bash. Si se usa una versión anterior a la requerida, se debe mostrar un mensaje de error.

    Incluir un control de errores más detallado y personalizado. En caso de que ocurra un error, se debe mostrar un mensaje de error explicando lo que sucedió y cómo solucionarlo.

    Añadir una opción para imprimir la versión del script.

    Incluir una opción para mostrar la licencia.

    Especificar las dependencias necesarias en el archivo README.

    Cambiar el nombre del comando para que sea más descriptivo y fácil de entender.

    Añadir más opciones de salida, como formato de archivo CSV y JSON.

    Utilizar un archivo de configuración para almacenar opciones comunes que se pueden reutilizar en diferentes ejecuciones del script.

    Utilizar la opción "-h" para mostrar la ayuda y "-v" para mostrar la versión del script.

    Agregar un mensaje de bienvenida y despedida para una mejor experiencia de usuario.

    Incluir una opción para habilitar o deshabilitar el color en la salida.

    Añadir una opción para especificar el nivel de verbosidad de la salida.

    Agregar más opciones de filtrado, como puerto, país, región, ciudad, proveedor de servicios de Internet, etc.
