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

tls:
	cd ansible;\
	ansible-playbook tls.yaml;\
	cd ..;

kubeconfigs:
	cd ansible;\
	ansible-playbook kubeconfigs.yaml;\
	cd ..;

encryption:
	cd ansible;\
	ansible-playbook encryption.yaml;\
	cd ..;