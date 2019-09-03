.PHONY: up down secret

export ANSIBLE_CONFIG=./ansible.cfg

up:
	cd ./ansible;\
	ansible-playbook cluster.yaml --extra-vars "state=present";\
	cd ..;

down:
	cd ./ansible;\
	ansible-playbook cluster.yaml --extra-vars "state=absent";\
	cd ..;

secret:
	cd ansible;\
	ansible-vault edit secret.yml;\
	cd ..;

inventory:
	cd ansible;\
	ansible-inventory --list;\
	cd ..;

bastion:
	cd ansible;\
	ansible-playbook bastion.yaml;\
	cd ..;