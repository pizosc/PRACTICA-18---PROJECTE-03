#!/bin/bash

readonly ARCHIVE_DIR='/archive'

usage() {
  echo >&2
  echo "Uso: ${0} [-dra] USER [USERN]..." >&2
  echo “Deshabilita una cuenta de Linux local.” >&2
  echo “  -d Elimina las cuentas en lugar de deshabilitarlas.” >&2
  echo “  -r Elimina la carpeta Home del usuario/s.” >&2
  echo “  -a Crea un archivo del directorio de inicio asociado con las cuentas y almacena el archivo en el directorio.” >&2
  exit 1
}

# Asegurate de estar ejecutando el script en modo super usuario.
if [[ "${UID}" != 0 ]]
then
  echo “Ejecuta como root or utiliza sudo?” >&2
  exit 1
fi

# Opciones
while getopts dra OPTION
do
  case ${OPTION} in
	d) DELETE_USER='true' ;;
	r) REMOVE_OPTION='true' ;;
	a) ARCHIVE='true' ;;
	?) usage ;;
  esac
done

# Elimina las opciones dejando los argumentos restantes.
shift "$(( OPTIND - 1 ))"

# Si el usuario no cumple aunque sea 1 argumento, dale ayuda.
if [[ "${#}" < 1 ]]
then
  usage
fi

# Recorra todos los nombres de usuario suministrados como argumentos.
for USERNAME in "${@}"
do
  echo "Procesando usuario: ${USERNAME}"

  # Asegurate de que el UID de la cuenta sea al menos 1000.
  USERID=$(id -u ${USERNAME})
  if [[ "${USERID}" -lt 1000 ]]
  then
	echo "Negando eliminar la cuenta ${USERNAME} con UID ${USERID}." >&2
	exit 1
  fi

  # Crear un archivo si lo solicita.
  if [[ "${ARCHIVE}" = 'true' ]]
  then
	# Asegurate de que el directorio ARCHIVE_DIR existe.
	if [[ ! -d "${ARCHIVE_DIR}" ]]
	then
  	echo "Creando el directorio ${ARCHIVE_DIR} ."
  	mkdir -p ${ARCHIVE_DIR}

  	if [[ "${?}" != 0 ]]
  	then
    	echo "El archivo directorio ${ARCHIVE_DIR} No puede crearse." >&2
    	exit 1
  	fi
	fi

	# Archive el directorio de inicio del usuario y muévalo a ARCHIVE_AIR
	HOME_DIR="/home/${USERNAME}"
	ARCHIVE_FILE="${ARCHIVE_DIR}-${USERNAME}.tgz"
	if [[ -d "${HOME_DIR}" ]]
	then
  	echo "Archivando ${HOME_DIR} a ${ARCHIVE_FILE}"
  	tar -zcf ${ARCHIVE_FILE} ${HOME_DIR} &> /dev/null
  	if [[ "${?}" != 0 ]]
  	then
    	echo "No pudo crearse ${ARCHIVE_FILE}." >&2
    	exit 1
  	fi
	else
   	echo "${HOME_DIR} No existe o no es un directorio." >&2
   	exit 1
	fi
  fi
#Borrar directorio
	if [[ "${REMOVE_OPTION}" = 'true' ]]
then
rm -r /home/${USERNAME}
echo "El directorio ha sido eliminado"
fi


  if [[ "${DELETE_USER}" = 'true' ]]
  then
	# Eliminar usuario.
	userdel ${REMOVE_OPTION} ${USERNAME}

	# Comprueba a ver si el comando fue exitoso.
	# No queremos decirle al usuario que una cuenta fue eliminada cuando no lo ha sido.
	if [[ "${?}" != 0 ]]
	then
  	echo "La cuenta ${USERNAME} NO fue eliminada." >&2
  	exit 1
	fi
	echo "La cuenta ${USERNAME} fue eliminada."


	# Comprueba a ver si el comando fue exitoso.
	# No queremos decirle al usuario que una cuenta fue deshabilitada cuando no lo ha sido.
	if [[ "${?}" != 0 ]]
	then
  	echo "La cuenta ${USERNAME} NO ha sido deshabilitada." >&2
  	exit 1
	fi
	echo "La cuenta ${USERNAME} fue deshabilitada."
  fi
done

exit 0

