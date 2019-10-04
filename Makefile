.PHONY: up down secret 02_create_certificates 03_create_kubeconfigs 04_bootstrap_etcd 05_configure_masters 06_configure_workers inventory

export ANSIBLE_CONFIG=./ansible.cfg

up: 01_create_infraestructure 02_create_certificates 03_create_kubeconfigs 04_bootstrap_etcd 05_configure_masters 06_configure_workers

down:
	ansible-playbook 01_create_infraestructure.yaml --extra-vars "state=absent" --skip-tags up

01_create_infraestructure:
	ansible-playbook 01_create_infraestructure.yaml --extra-vars "state=present" --skip-tags down

02_create_certificates:
	ansible-playbook 02_create_certificates.yaml

03_create_kubeconfigs:
	ansible-playbook 03_create_kubeconfigs.yaml

04_bootstrap_etcd:
	ansible-playbook 04_bootstrap_etcd.yaml

05_configure_masters:
	ansible-playbook 05_configure_masters.yaml

06_configure_workers:
	ansible-playbook 06_configure_workers.yaml

secret:
	ansible-vault edit secret.yml

inventory:
	ansible-inventory --list