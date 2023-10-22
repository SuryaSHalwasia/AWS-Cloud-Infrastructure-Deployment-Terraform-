add-content -path C:\Users\shalw\.ssh\config -Value @"
Host ${hostname}
    HostName ${hostname}
    User ${user}
    IdentityFile ${identityFile}
"@
