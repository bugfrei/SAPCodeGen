if (Test-Path $PROFILE) {
    $c = Get-Content $PROFILE -Raw
}
else {
    $c = ""
}

if ($c.Contains("#SAPCodeGen")) {
    Write-Host "SAPCodeGen already installed"
    return
}
$c += "#SAPCodeGen:`nInvoke-RestMethod https://raw.githubusercontent.com/bugfrei/SAPCodeGen/main/supacg.ps1 -OutVariable xxx | out-null; . ([scriptblock]::Create(`$xxx))`n"
Invoke-RestMethod https://raw.githubusercontent.com/bugfrei/SAPCodeGen/main/supacg.ps1 -OutVariable xxx | out-null; . ([scriptblock]::Create($xxx))

Set-Content $PROFILE $c -Force

Write-Host "Installiert und sofort nutzbar." -ForegroundColor Green
