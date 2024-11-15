#!/bin/bash

# Variables para los nodos
WORKER_NODES=("ec2-34-203-246-128.compute-1.amazonaws.com" "ec2-44-211-192-37.compute-1.amazonaws.com")

# Obtener la IP pública del nodo principal
MANAGER_PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)  # Obtener la IP pública del nodo
MANAGER_IP=$(hostname -I | awk '{print $1}')  # Obtener la IP privada
echo "IP pública del nodo principal: $MANAGER_PUBLIC_IP"
echo "IP privada del nodo principal: $MANAGER_IP"

# Actualizar apiUrl en los archivos React con la IP pública
APP_JS_PATH="react/MiProyecto/App.js"
DETAIL_SCREEN_PATH="react/MiProyecto/DetailScreen.js"

echo "Actualizando apiUrl en $APP_JS_PATH con la IP pública..."
sed -i "s|const apiUrl = 'http://ec2-18-204-207-102.compute-1.amazonaws.com:5000';|const apiUrl = 'http://$MANAGER_PUBLIC_IP:5000';|g" $APP_JS_PATH

echo "Actualizando apiUrl en $DETAIL_SCREEN_PATH con la IP pública..."
sed -i "s|const apiUrl = 'http://ec2-18-204-207-102.compute-1.amazonaws.com:5000';|const apiUrl = 'http://$MANAGER_PUBLIC_IP:5000';|g" $DETAIL_SCREEN_PATH

# Inicializar Docker Swarm
if ! sudo docker info | grep -q 'Swarm: active'; then
    echo "Inicializando Docker Swarm en el nodo principal..."
    sudo docker swarm init
else
    echo "Docker Swarm ya está activo."
fi

WORKER_TOKEN=$(sudo docker swarm join-token -q worker)
echo "Token de trabajador: $WORKER_TOKEN"

# Unir los nodos trabajadores al Swarm y construir las imágenes en cada nodo
for NODE in "${WORKER_NODES[@]}"; do
    echo "Uniendo el nodo $NODE al Swarm..."
    ssh root@$NODE "sudo docker swarm join --token $WORKER_TOKEN $MANAGER_IP:2377"

    echo "Copiando archivos al nodo $NODE..."
    scp -r ./app ./react/MiProyecto root@$NODE:/tmp/

    echo "Construyendo la imagen para el servicio web en $NODE..."
    ssh root@$NODE "sudo docker build -t myapp_web -f /tmp/app/Dockerfile /tmp/app"

    echo "Construyendo la imagen para el servicio frontend en $NODE..."
    ssh root@$NODE "sudo docker build -t myapp_frontend -f /tmp/react/MiProyecto/Dockerfile /tmp/react/MiProyecto"
done

# Construir las imágenes en el nodo principal
echo "Construyendo la imagen para el servicio web en el nodo principal..."
sudo docker build -t myapp_web -f app/Dockerfile ./app

echo "Construyendo la imagen para el servicio frontend en el nodo principal..."
sudo docker build -t myapp_frontend -f react/MiProyecto/Dockerfile ./react/MiProyecto

# Desplegar la pila de servicios con Docker Stack en el nodo principal
echo "Desplegando servicios con Docker Stack..."
sudo docker stack deploy -c docker-compose.yml sistemaR

echo "Despliegue completo."
