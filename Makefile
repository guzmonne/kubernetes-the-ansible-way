export ANSIBLE_CONFIG=./ansible.cfg

secret:
	ansible-vault edit secret.yml

inventory:
	ansible-inventory --list

up:
	ansible-playbook up.yaml

down:
	ansible-playbook down.yaml

.PHONY: secret inventory up down