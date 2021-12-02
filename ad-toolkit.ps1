#Requires -RunAsAdministrator
$motd = Get-Content .\motd
$motd

Function WriteLogs{
    Param($x)
    switch ($x){
        1000 {Write-EventLog -LogName "AD-Toolkit" -Source "AD-Toolkit" -EventId $x -EntryType 8 -Message "AD-Toolkit application started by $env:username" -ComputerName "als-s02"}
        1001 {Write-EventLog -LogName "AD-Toolkit" -Source "AD-Toolkit" -EventId $x -EntryType 8 -Message "Organizational Unit variable set by $env:username" -ComputerName "als-s02"}
        1002 {Write-EventLog -LogName "AD-Toolkit" -Source "AD-Toolkit" -EventId $x -EntryType 8 -Message "Domain Controller variable set by $env:username" -ComputerName "als-s02"}
        1003 {Write-EventLog -LogName "AD-Toolkit" -Source "AD-Toolkit" -EventId $x -EntryType 8 -Message "User details were read by $env:username" -ComputerName "als-s02"}
        1004 {Write-EventLog -LogName "AD-Toolkit" -Source "AD-Toolkit" -EventId $x -EntryType 8 -Message "$env:username created Active Directory account $Global:SAMname" -ComputerName "als-s02"}
        1005 {Write-EventLog -LogName "AD-Toolkit" -Source "AD-Toolkit" -EventId $x -EntryType 8 -Message "$Global:SAMname was deleted by $env:username" -ComputerName "als-s02"}
        1006 {Write-EventLog -LogName "AD-Toolkit" -Source "AD-Toolkit" -EventId $x -EntryType 8 -Message "$env:username created Active Directory security group $Global:SAMname" -ComputerName "als-s02"}
        1007 {Write-EventLog -LogName "AD-Toolkit" -Source "AD-Toolkit" -EventId $x -EntryType 8 -Message "$Global:SAMname was deleted by $env:username" -ComputerName "als-s02"}
        1008 {Write-EventLog -LogName "AD-Toolkit" -Source "AD-Toolkit" -EventId $x -EntryType 8 -Message "$Global:SAMname groups were backed up by $env:username" -ComputerName "als-s02"}
        1009 {Write-EventLog -LogName "AD-Toolkit" -Source "AD-Toolkit" -EventId $x -EntryType 8 -Message "$Global:SAMname groups were restored by $env:username" -ComputerName "als-s02"}
        1010 {Write-EventLog -LogName "AD-Toolkit" -Source "AD-Toolkit" -EventId $x -EntryType 8 -Message "$Global:SAMname groups were copied to $Global:SAMname by $env:username" -ComputerName "als-s02"}
    }
}
WriteLogs(1000)

Function MainMenu{
    "1) Show all users              2) Create User(s)"
    "3) Delete User(s)              4) Create Group(s)"
    "5) Delete Group(s)             6) Backup User or Groups"
    "7) Restore User or Groups      8) Get Logs"
    "98) Set Object Path            99) Set Domain"
    ""
    $c = Read-Host "Select option"
    switch ($c){
        1 {ShowAll}
        2 {NewUser}
        3 {DeleteUser}
        4 {NewGroup}
        5 {UserGroupAdd}
        6 {DeleteGroup}
        7 {BackupUserGroups}
        8 {RestoreUserGroups}
        9 {GetLogs}
        98 {SetOU}
        99 {SetDC}
    }
}

Function SetOU{
    $Global:oupath = Read-Host "Enter OU Path"
    WriteLogs(1001)
}

Function SetDC{
    $domName = Read-Host "Enter domain"
    $splitDomName = $domName.Split(".")
    $dc1 = $splitDomName[0]
    $dc2 = $splitDomName[1]
    $Global:dcpath = "DC=$dc1,DC=$dc2"
    WriteLogs(1002)
}

Function ShowAll{ #Shows all users or shows specified user
    $searchUser = Read-Host "Search user"
    if ($searchUser -eq "*"){
        WriteLogs(1003)
        Get-ADUser -Filter *
    }
    else {
        $getDetailed = Read-Host "Get detailed info?(y/N)"
        switch ($getDetailed){
            "Y" {Get-ADUser -Identity $searchUser -Properties *}
            "" {Get-ADUser -Identity $searchUser}
            "N" {Get-ADUser -Identity $searchUser}
        }
        WriteLogs(1003)
    }
}

Function NewUser{ # Creates a new user
    # $Global:oupath = Read-Host "Enter 'Users and Groups' path"
    $fullname = Read-Host "Enter full name"
    $splitname = $fullname.Split(" ")
    $firstname = $splitname[0]
    $lastname = $splitname[1]
    if ($lastname.length -gt 7){
        $Global:username = $firstname.Substring(0,1) + $lastname.Substring(0,7)
    }
    else {
        $Global:username = $firstname.Substring(0,1) + $lastname.Substring(0,$lastname.length)
    }
    $Global:username = $Global:username.ToLower()
    $email = $Global:username + "@acme.com"
    $title = Read-Host "Enter job title"
    $depart = Read-Host "Enter department name"
    $company = Read-Host "Enter company name"
    $office = Read-Host "Enter office name"
    $telephone = Read-Host "Enter telephone number"
    $streetadd = Read-Host "Enter Street Address"
    $city = Read-Host "Enter city name"
    $stateprov = Read-Host "Enter state/province"
    $postal = Read-Host "Enter postal code"
    $country = Read-Host "Enter country (must be abbreviated, e.g 'CA')"
    $password = Read-Host -AsSecureString "Enter password for user"

    Write-Host ""
    New-ADUser -Name $fullname -GivenName $firstname -Surname $lastname -DisplayName $fullname -UserPrincipalName $Global:username -SamAccountName $Global:username -Title $title -Department $depart -Company $company -Office $office -OfficePhone $telephone -StreetAddress $streetadd -City $city -State $stateprov -PostalCode $postal -Country $country -EmailAddress $email -AccountPassword $password -Path "$Global:oupath,$Global:dcpath" -Confirm
    $Global:SAMname = $username
    WriteLogs(1004)
    $enable = Read-Host "Enable account?(Y\n)"
    $enable = $enable.toupper()
    if ($enable -eq "Y" -or $enable -eq "")
    {
        Enable-ADAccount -Identity $Global:username
    }

    $copyChoice = Read-Host "Copy groups from another user?(Y\n)"
    switch ($copyChoice) {
        "Y" {CopyUserGroup($Global:username)}
        "" {CopyUserGroup($Global:username)}
        "N" {continue}
    }
}
Function UserGroupAdd{
    $users = Read-Host "Enter name of user(s). Comma ',' separated"
    $users = $users.split(",").Replace(" ","")
    $groupName = Read-Host "Enter group name"
    foreach ($user in $users) {
        Add-ADGroupMember -Identity $groupName -Members $user
    }
}

Function CopyUserGroup{
    param ($user)
    $targetUser = Read-Host "Which user or group would you like to copy groups from?"
    $fpath = Read-Host "Enter restore location (DO NOT ENTER FILENAME)"

    $groups = Get-Content "$fpath\$targetUser.txt" | Where-Object {$_.trimend() -ne ""}
    $groups = $groups.trim()

    foreach ($group in $groups) {
        Add-ADGroupMember -Identity $group -Members $user
        $Global:SAMname = $group
        WriteLogs(1010)
    }
}

Function DeleteUser{
    $delUser = Read-Host "Enter user identity to remove"
    Remove-ADUser -Identity $delUser -Confirm
    $Global:SAMname = $delUser
    WriteLogs(1005)
}

Function NewGroup {
    # $Global:oupath = Read-Host "OU Path"
    $gName = Read-Host "Enter Group Name"
    $splitgName = $gName.split()
    $netgName = ""
    foreach ($word in $splitgName){
        $netgName = $netgName + $word.Substring(0,5)
    }
    "Group name is: $netgName"

    $desc = Read-Host "Description"
    $managedBy = Read-Host "Managed by"
    
    New-ADGroup -Name $gName -SamAccountName $netgName -GroupCategory Security -GroupScope Global -DisplayName $gName -ManagedBy $managedBy -Path "$Global:oupath,$Global:dcpath" -Description $desc
    $Global:SAMname = $netgName
    WriteLogs(1006)

    $copyChoice = Read-Host "Copy groups from another group?(Y\n)"
    switch ($copyChoice) {
        "Y" {CopyUserGroup($netgName)}
        "" {CopyUserGroup($netgName)}
        "N" {continue}
}}

Function DeleteGroup{
    $delGroup = Read-Host "Enter group SAM name to remove"
    Remove-ADGroup -Identity $delGroup -Confirm
    $Global:SAMname = $delGroup
    WriteLogs(1007)
}

Function BackupUserGroups{
    $users = read-host "Enter username or Group SAM name to backup"
    $fpath = Read-Host "Enter backup location (DO NOT ENTER FILENAME)"
    $users = $users.Split(",").Replace(" ","")

    foreach ($user in $users) {
        Get-ADPrincipalGroupMembership -Identity $user | Format-Table -HideTableHeaders -Property SamAccountName | Out-File "$fpath\$user.txt"  
    }
    
    $Global:SAMname = $user
    WriteLogs(1008)
}

Function RestoreUserGroups{
    $users = read-host "Enter username or Group SAM name to restore"
    $users = $users.split(",").Replace(" ","")
    $fpath = Read-Host "Enter restore location (DO NOT ENTER FILENAME)"

    foreach ($user in $users) {
        $groups = Get-Content "$fpath\$user.txt" | Where-Object {$_.trimend() -ne ""}
        $groups = $groups.trim()    
        foreach ($group in $groups) {
            Add-ADGroupMember -Identity $group -Members $user
            $Global:SAMname = $group
            WriteLogs(1009)
        }    
    }
}

Function GetLogs{
    $availLogs = Get-EventLog -ComputerName "als-s02" -list
    $logList = ""
    foreach ($_ in $availLogs) {
        $logList += $_.Log + ", "
    }
    $selectLog = Read-Host "Select a log to view. `"AD-Toolkit`" is selected by default.`n$loglist"
    if ($selectLog -eq ""){
        $selectLog = "AD-Toolkit"
    }
    $size = Read-Host "How many entries to display?"
    if ($size -eq ""){
        Get-EventLog -LogName $selectLog -ComputerName "als-s02"| more
    }
    else{
        Get-EventLog -LogName $selectLog -Newest $size -ComputerName "als-s02" | more
    }
}

SetOU
SetDC

$logFileExists = Get-EventLog -ComputerName "als-s02" -List | Where-Object {$_.logdisplayname -eq "AD-Toolkit"} 
if (! $logFileExists) {
    New-EventLog -LogName "AD-Toolkit" -Source "AD-Toolkit" -ComputerName "als-s02"
}

while ($isdone -ne 1){
    MainMenu
}