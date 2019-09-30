.PHONY: up down secret tls kubeconfigs kubernetes_control_plane etcd inventory

export ANSIBLE_CONFIG=./ansible.cfg

cluster: up tls kubeconfigs etcd kubernetes_control_plane

up:
	cd ./ansible;\
	ansible-playbook cluster.yaml --extra-vars "state=present" --skip-tags down;\
	cd ..;

down:
	cd ./ansible;\
	ansible-playbook cluster.yaml --extra-vars "state=absent" --skip-tags up;\
	cd ..;

tls:
	cd ansible;\
	ansible-playbook tls.yaml;\
	cd ..;

kubeconfigs:
	cd ansible;\
	ansible-playbook kubeconfigs.yaml;\
	cd ..;

etcd:
	cd ansible;\
	ansible-playbook etcd.yaml;\
	cd ..;

control_plane:
	cd ansible;\
	ansible-playbook control_plane.yaml;\
	cd ..;

secret:
	cd ansible;\
	ansible-vault edit secret.yml;\
	cd ..;

inventory:
	cd ansible;\
	ansible-inventory --list;\
	cd ..;