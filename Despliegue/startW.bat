@echo off

echo echo "Conectado a la instancia EC2" > temp_script.sh
echo git clone https://github.com/NicolasPalma0511/recomendacionProyecto >> temp_script.sh
echo cd recomendacionProyecto >> temp_script.sh
echo chmod +x run.sh >> temp_script.sh
echo ./run.sh ec2-35-175-138-126.compute-1.amazonaws.com ec2-34-227-161-84.compute-1.amazonaws.com >> temp_script.sh

REM Copiar el script temporal al servidor remoto
scp -i docker.pem temp_script.sh ubuntu@ec2-3-89-21-194.compute-1.amazonaws.com:~/

REM Ejecutar el script remoto en la instancia EC2
ssh -i docker.pem ubuntu@ec2-3-89-21-194.compute-1.amazonaws.com "dos2unix ~/temp_script.sh"
ssh -i docker.pem ubuntu@ec2-3-89-21-194.compute-1.amazonaws.com "bash ~/temp_script.sh"

REM Limpiar el archivo temporal local
del temp_script.sh

pause