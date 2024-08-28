Voici le pipeline Jenkins mis à jour ainsi que la documentation complète reflétant les nouveaux playbooks Ansible pour la création et la suppression d'instances EC2.

### Pipeline Jenkins

Le pipeline ci-dessous est conçu pour exécuter les playbooks de création et de suppression d'instances EC2 en fonction du paramètre `ACTION` sélectionné dans Jenkins.

```groovy
pipeline {
    agent any
    
    parameters {
        choice(name: 'ACTION', choices: ['create', 'delete'], description: 'Choose to create or delete EC2 instances')
    }
    
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/your-repo/ec2-automation.git'
            }
        }
        
        stage('Run Ansible Playbook') {
            steps {
                script {
                    if (params.ACTION == 'create') {
                        ansiblePlaybook(
                            playbook: 'create_ec2.yml',
                            inventory: 'localhost',
                            credentialsId: 'aws-credentials'
                        )
                    } else if (params.ACTION == 'delete') {
                        ansiblePlaybook(
                            playbook: 'delete_ec2.yml',
                            inventory: 'localhost',
                            credentialsId: 'aws-credentials'
                        )
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline finished'
        }
        success {
            echo 'Successfully completed'
        }
        failure {
            echo 'Failed'
        }
    }
}
```

### Documentation Complète

#### 1. Introduction

##### Contexte
Ce projet met en place un pipeline Jenkins automatisé pour la gestion d'instances EC2 sur AWS. Le pipeline s'appuie sur Ansible pour la création et la suppression d'instances, permettant ainsi une gestion simplifiée des ressources cloud.

##### Objectifs
- **Automatisation** : Automatiser la création et la suppression d'instances EC2 avec Ansible.
- **Flexibilité** : Permettre la sélection entre création et suppression via Jenkins.
- **Documentation** : Fournir une documentation détaillée pour la configuration et l'exécution du pipeline.

#### 2. Prérequis

##### Environnement
- **AWS** : Instances EC2 situées dans la région `us-east-1`.
- **Jenkins** : Configuré pour exécuter des pipelines de type `Pipeline`.
- **Ansible** : Configuré sur le serveur Jenkins pour exécuter des playbooks.

##### Configuration Requise
1. **AWS Credentials** : Stockés dans Jenkins pour permettre l'accès aux API AWS.
2. **Ansible** : Installé et configuré sur le serveur Jenkins.
3. **Repository Git** : Le code du projet doit être stocké dans un repository Git, accessible par Jenkins.

#### 3. Configuration de Jenkins

##### Installation et Configuration
- **Plugins Jenkins** : Installer les plugins nécessaires (`AWS Credentials`, `Ansible`, `Pipeline`).
- **Credentials AWS** : Ajouter les credentials AWS dans Jenkins sous `Manage Jenkins` > `Manage Credentials`.

##### Création du Pipeline Jenkins
1. **Création du Job** :
   - Créer un nouveau job de type `Pipeline` dans Jenkins.
   - Nommer le job "EC2-Automation-Pipeline".
2. **Paramètres du Pipeline** :
   - Ajouter un paramètre `choice` nommé `ACTION` avec les options `create` et `delete`.

3. **Script du Pipeline** :
   - Utiliser le script de pipeline Jenkins ci-dessus.

#### 4. Playbooks Ansible

##### Playbook pour la Création d'Instances EC2

**Fichier : `create_ec2.yml`**

```yaml
---
- hosts: localhost
  connection: local
  gather_facts: false

  vars:
    region_1: "us-east-1"
    state_1: "present"
    instance_type_1: "t2.micro"
    security: "ansible-security-group"
    key_name: "key"

  tasks:
  - name: Generate an OpenSSH keypair
    community.crypto.openssh_keypair:
      path: "{{ key_name }}"
      state: "{{ state_1 }}"

  - name: Create security group
    amazon.aws.ec2_security_group:
      rules:
        - proto: tcp
          from_port: 8080
          to_port: 8080
          cidr_ip: "0.0.0.0/0"
        - proto: tcp
          from_port: 22
          to_port: 22
          cidr_ip: "0.0.0.0/0"
      rules_egress:
        - from_port: 0
          proto: tcp
          to_port: 0
          cidr_ip: 0.0.0.0/0
          group_name: "ansible group name"
          group_desc: EC2 group
      region: "{{ region_1 }}"
      state: "{{ state_1 }}"
      name: "{{ security }}"
      description: "ansible created this"

  - name: Get AMI ID
    amazon.aws.ec2_ami_info:
      owners: 099720109477
      filters:
        name: "ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"
      region: "{{ region_1 }}"
    register: result

  - name: Create EC2 key pair
    amazon.aws.ec2_key:
      name: "{{ key_name }}"
      region: "{{ region_1 }}"
      state: "{{ state_1 }}"
      key_material: "{{ lookup('file', '{{ key_name }}.pub') }}"
    no_log: true
    register: aws_ec2_key_pair

  - name: Create EC2 instance
    amazon.aws.ec2_instance:
      name: "Ansible-EC2"
      region: "{{ region_1 }}"
      image_id: "{{ result.images[-1].image_id }}"
      instance_type: "{{ instance_type_1 }}"
      key_name: "{{ key_name }}"
      security_group: "{{ security }}"
      state: "{{ state_1 }}"

  - name: Rename key
    shell: "mv {{ key_name }} {{ key_name }}.pem && chmod 400 {{ key_name }}.pem"
```

##### Playbook pour la Suppression d'Instances EC2

**Fichier : `delete_ec2.yml`**

```yaml
---
- hosts: localhost
  connection: local
  gather_facts: false

  vars:
    region_1: "us-east-1"
    state_1: "absent"
    instance_type_1: "t2.micro"
    security: "ansible-security-group"
    key_name: "key"

  tasks:
  - name: Remove OpenSSH keypair
    community.crypto.openssh_keypair:
      path: "{{ key_name }}"
      state: "{{ state_1 }}"

  - name: Get AMI ID
    amazon.aws.ec2_ami_info:
      owners: 099720109477
      filters:
        name: "ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"
      region: "{{ region_1 }}"
    register: result

  - name: Delete EC2 instance
    amazon.aws.ec2_instance:
      name: "Ansible-EC2"
      region: "{{ region_1 }}"
      image_id: "{{ result.images[-1].image_id }}"
      instance_type: "{{ instance_type_1 }}"
      key_name: "{{ key_name }}"
      security_group: "{{ security }}"
      state: "{{ state_1 }}"

  - name: Delete security group
    amazon.aws.ec2_security_group:
      rules:
        - proto: tcp
          from_port: 8080
          to_port: 8080
          cidr_ip: "0.0.0.0/0"
        - proto: tcp
          from_port: 22
          to_port: 22
          cidr_ip: "0.0.0.0/0"
      rules_egress:
        - from_port: 0
          proto: tcp
          to_port: 65535
          cidr_ip: 0.0.0.0/0
          group_name: "ansible group name"
          group_desc: EC2 group
      region: "{{ region_1 }}"
      state: "{{ state_1 }}"
      name: "{{ security }}"
      description: "ansible created this"

  - name: Remove PEM key
    shell: "rm -rf *pem"
```

#### 5. Exécution du Pipeline

1. **Exécution de la Création** :
   - Choisir l'option `create` dans Jenkins et exécuter le pipeline.
   - Vérifier sur AWS que l'instance EC2 et les ressources associées (groupe de sécurité, clé SSH) sont créées.

2. **Exécution de la Suppression** :
   - Choisir l'option `delete` dans Jenkins et exécuter le pipeline.
   - Vérifier sur AWS que l'instance EC2 et les ressources associées sont supprimées.

#### 6. Conclusion

Ce pipeline automatisé, associé à Ansible, permet une gestion simplifiée des instances EC2 sur AWS. En utilisant Jenkins, les administrateurs peuvent rapidement créer ou supprimer des instances en fonction de leurs besoins, tout en maintenant une trace des opérations grâce aux logs de Jenkins.
