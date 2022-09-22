## Bootstrap VyOS
Required manual initial configuration on VyOS:
```
set interfaces ethernet eth1 address 192.168.178.2/24
set service ssh
```
First time run without SSH key:
```
ansible-playbook site.yaml --ask-pass
```
