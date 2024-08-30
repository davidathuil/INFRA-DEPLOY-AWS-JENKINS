#!/bin/bash

# Mettre à jour la liste des paquets
sudo apt update -y

# Installer fontconfig et Java (OpenJDK 17)
sudo apt install -y fontconfig openjdk-17-jre

# Ajouter la clé Jenkins et le dépôt à la liste des sources
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Mettre à jour la liste des paquets à nouveau
sudo apt-get update -y

# Installer Jenkins
sudo apt-get install -y jenkins unzip

# Ajouter l'utilisateur Jenkins au groupe sudo
sudo usermod -aG sudo jenkins

# Démarrer et activer Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Télécharger et installer AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Nettoyer les fichiers inutiles
rm awscliv2.zip
rm -rf aws

# Installer les bibliothèques Python boto3 et botocore
sudo apt install -y python3-boto3 python3-botocore

# Installer Ansible
sudo apt install -y ansible

# Vérifier les versions installées
echo "Jenkins version:"
sudo systemctl status jenkins | grep 'Active:'

echo "AWS CLI version:"
aws --version

echo "Ansible version:"
ansible --version

echo "Installation terminée."
sudo cat var/lib/jenkins/secrets/initialAdminPassword