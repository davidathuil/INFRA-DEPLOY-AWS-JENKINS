#!/bin/bash

# Définir les variables pour réutiliser dans le script
KEY_NAME="my-key-pair"
SECURITY_GROUP_NAME="my-security-group"
VPC_CIDR="10.0.0.0/16"
SUBNET_CIDR="10.0.1.0/24"
INSTANCE_TYPE="t2.micro"
AMI_ID="ami-0e86e20dae9224db8"  # Remplacez ceci par l'ID de l'AMI Ubuntu
TAG_NAME="MyUbuntuEC2Instance"

# Étape 1 : Créer une paire de clés SSH
echo "Création de la paire de clés SSH..."
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_NAME.pem
chmod 400 $KEY_NAME.pem
echo "Paire de clés créée et sauvegardée dans $KEY_NAME.pem"

# Étape 2 : Créer un groupe de sécurité
echo "Création du groupe de sécurité..."
SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name $SECURITY_GROUP_NAME --description "Security group for my EC2 instance" --query 'GroupId' --output text)
echo "Groupe de sécurité créé avec l'ID $SECURITY_GROUP_ID"

# Étape 3 : Autoriser le trafic SSH et HTTP/HTTPS dans le groupe de sécurité
echo "Ajout des règles de sécurité au groupe de sécurité..."
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 443 --cidr 0.0.0.0/0
echo "Règles de sécurité ajoutées."

# Étape 4 : (Optionnel) Créer un VPC, sous-réseau, et une passerelle Internet
echo "Création du VPC..."
VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --query 'Vpc.VpcId' --output text)
echo "VPC créé avec l'ID $VPC_ID"

echo "Création du sous-réseau..."
SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET_CIDR --query 'Subnet.SubnetId' --output text)
echo "Sous-réseau créé avec l'ID $SUBNET_ID"

echo "Création de la passerelle Internet et association au VPC..."
INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $INTERNET_GATEWAY_ID
echo "Passerelle Internet créée et attachée avec l'ID $INTERNET_GATEWAY_ID"

echo "Création de la table de routage et association au sous-réseau..."
ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $INTERNET_GATEWAY_ID
aws ec2 associate-route-table --subnet-id $SUBNET_ID --route-table-id $ROUTE_TABLE_ID
echo "Table de routage créée et associée au sous-réseau."

# Étape 5 : Lancer l'instance EC2
echo "Lancement de l'instance EC2..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP_ID \
    --subnet-id $SUBNET_ID \
    --associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$TAG_NAME}]" \
    --query 'Instances[0].InstanceId' --output text)
echo "Instance EC2 Ubuntu lancée avec l'ID $INSTANCE_ID"

# Fin du script
echo "Script terminé. Votre instance EC2 Ubuntu est en cours de lancement."