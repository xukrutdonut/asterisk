# Guía de Inicio Rápido para Raspberry Pi 5

Esta guía te ayudará a instalar y ejecutar Asterisk en tu Raspberry Pi 5 usando Docker.

## Requisitos Previos

1. Raspberry Pi 5 con Raspberry Pi OS instalado
2. Docker instalado en tu Raspberry Pi 5

### Instalar Docker

Si aún no tienes Docker instalado, ejecuta:

```bash
# Descargar e instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Agregar tu usuario al grupo docker
sudo usermod -aG docker $USER

# Cerrar sesión y volver a iniciar sesión para que los cambios surtan efecto
```

## Instalación de Asterisk

### Método 1: Instalación con un Solo Comando (Recomendado)

Este es el método más simple. Solo necesitas ejecutar:

```bash
# Clonar el repositorio
git clone https://github.com/xukrutdonut/asterisk.git
cd asterisk

# Construir y ejecutar Asterisk
docker compose up -d --build
```

¡Eso es todo! Docker construirá la imagen de Asterisk y la ejecutará en segundo plano.

**Nota:** La primera construcción puede tardar entre 15-30 minutos dependiendo de tu Raspberry Pi 5.

### Verificar la Instalación

```bash
# Verificar que el contenedor está ejecutándose
docker ps | grep asterisk

# Ver los registros
docker logs asterisk

# Acceder a la CLI de Asterisk
docker exec -it asterisk asterisk -rvvv
```

## Comandos Básicos

### Gestión del Contenedor

```bash
# Detener Asterisk
docker compose down

# Iniciar Asterisk (después de construirlo)
docker compose up -d

# Reiniciar Asterisk
docker compose restart

# Ver registros en tiempo real
docker compose logs -f
```

### Acceder a Asterisk

```bash
# Acceder a la CLI de Asterisk
docker exec -it asterisk asterisk -rvvv

# Una vez dentro de la CLI, puedes usar comandos como:
# - core show version
# - core show channels
# - core show help
# - Para salir: exit
```

### Acceder al contenedor

```bash
# Obtener una shell dentro del contenedor
docker exec -it asterisk bash

# Navegar a los archivos de configuración
cd /etc/asterisk
```

## Configuración

Los archivos de configuración se almacenan en volúmenes Docker persistentes:

- **Configuración:** `/etc/asterisk` (dentro del contenedor)
- **Sonidos:** `/var/lib/asterisk/sounds`
- **Spool/Buzón de voz:** `/var/spool/asterisk`
- **Registros:** `/var/log/asterisk`

Para editar la configuración:

```bash
# Acceder al contenedor
docker exec -it asterisk bash

# Editar archivos de configuración
cd /etc/asterisk
vi pjsip.conf
vi extensions.conf

# Salir del contenedor
exit

# Reiniciar Asterisk para aplicar cambios
docker compose restart
```

## Puertos

Asterisk expone los siguientes puertos:

- **5060/udp, 5060/tcp:** SIP
- **5061/tcp:** SIP sobre TLS
- **8088/tcp, 8089/tcp:** HTTP/HTTPS
- **4569/udp:** IAX2
- **10000-20000/udp:** RTP (para audio/video)

Nota: Usando `network_mode: host` en docker-compose.yml, el contenedor tiene acceso directo a todos los puertos del host.

## Solución de Problemas

### Ver registros detallados

```bash
docker logs -f asterisk
```

### Verificar la versión de Asterisk

```bash
docker exec asterisk asterisk -V
```

### Verificar módulos cargados

```bash
docker exec asterisk asterisk -rx "module show"
```

### Problemas comunes

1. **El contenedor no inicia:**
   ```bash
   docker logs asterisk
   ```
   Revisa los registros para ver errores específicos.

2. **No se puede acceder a la CLI:**
   ```bash
   docker ps
   ```
   Asegúrate de que el contenedor esté ejecutándose.

3. **Reconstruir desde cero:**
   ```bash
   docker compose down
   docker compose up -d --build --force-recreate
   ```

## Próximos Pasos

1. **Configurar extensiones SIP:** Edita `/etc/asterisk/pjsip.conf`
2. **Configurar el plan de marcación:** Edita `/etc/asterisk/extensions.conf`
3. **Revisar ejemplos:** Consulta `contrib/docker/examples/` para configuraciones de ejemplo

## Recursos Adicionales

- [README.rpi5.md](contrib/docker/README.rpi5.md) - Guía completa de Docker
- [QUICKSTART.rpi5.md](contrib/docker/QUICKSTART.rpi5.md) - Referencia rápida
- [Documentación de Asterisk](https://docs.asterisk.org)

## Soporte

Si encuentras problemas, revisa:
- [Foro de la Comunidad de Asterisk](https://community.asterisk.org)
- [Documentación oficial](https://docs.asterisk.org)
- Los archivos README en `contrib/docker/`

---

¡Bienvenido a la comunidad de Asterisk!
