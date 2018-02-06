Run the following command with administrative user which have schema admin role.

The syntax format is:
```
ldifde -i -f <Path>\sshpublickey.ldif -b <username> <domain> <password> -k -j . -c "CN=schema,CN=Configuration,DC=X" #schemaNamingContext
```
e.g. when the logged user
```
ldifde -i -f  c:\scripts\sshpublickey.ldf -k -j . -c "CN=schema,CN=Configuration,DC=X" #schemaNamingContext
```
If something goes wrong take a look into the log file.