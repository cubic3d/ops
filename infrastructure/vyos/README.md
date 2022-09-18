## Required manual config after installtion on VyOS
```
set interfaces ethernet eth1 address 192.168.178.2/24
set service https api keys id tf key [insert key from secrets]
```

## Required manual imports of resources to initial state
Run `initial_import.sh` after installing VyOS to import resources into terraform state.
