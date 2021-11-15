$motd = Get-Content .\motd
$motd

Function MainMenu{
    "1) Show all users              2) Create User(s)"
    "3) Delete User(s)              4) Create Group(s)"
    "5) Delete Group(s)"
    $c = Read-Host
    if ($c -eq "1") {
        ShowAll
    }
}

Function ShowAll{
    $suser = Read-Host "Search user"
    if ($suser -eq "*"){
        Get-ADUser -Filter *
    }
    else {
        Get-ADUser -Identity $suser
    }
}

MainMenu