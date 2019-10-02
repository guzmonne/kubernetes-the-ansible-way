.PHONY: up down secret tls kubeconfigs control_plane etcd inventory

export ANSIBLE_CONFIG=./ansible.cfg

cluster: up tls kubeconfigs etcd control_plane workers

up:
	ansible-playbook cluster.yaml --extra-vars "state=present" --skip-tags down

down:
	ansible-playbook cluster.yaml --extra-vars "state=absent" --skip-tags up

tls:
	ansible-playbook tls.yaml

kubeconfigs:
	ansible-playbook kubeconfigs.yaml

etcd:
	ansible-playbook etcd.yaml

control_plane:
	ansible-playbook control_plane.yaml

workers:
	ansible-playbook workers.yaml

secret:
	ansible-vault edit secret.yml

inventory:
	ansible-inventory --list