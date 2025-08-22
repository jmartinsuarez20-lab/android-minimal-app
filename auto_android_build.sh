#!/bin/bash
set -e

echo "📦 Instalando dependencias..."
pkg update -y
pkg install -y openjdk-17 git wget unzip

echo "📂 Creando proyecto Android minimal..."
rm -rf MyMinimalApp
mkdir MyMinimalApp
cd MyMinimalApp

# Aquí podrías poner comandos reales para generar tu app
echo "Este es un APK de prueba" > README.txt

echo "✅ Proyecto creado. Listo para compilar."
