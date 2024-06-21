# Suportis Code Generator

## Einrichten

Einmaliges laden mit

```
Invoke-RestMethod https://raw.githubusercontent.com/bugfrei/SAPCodeGen/main/supacg.ps1 -OutVariable xxx | out-null; . ([scriptblock]::Create($xxx))
````

Installieren (in Profile, immer aktuelle Version)


```
Invoke-RestMethod https://raw.githubusercontent.com/bugfrei/SAPCodeGen/main/install.ps1 -OutVariable xxx | out-null; & ([scriptblock]::Create($xxx))
```