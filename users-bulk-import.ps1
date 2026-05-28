<#
================================================================
  QVIS Technology Solutions
  Create the 10 launch users; commented stubs for the next 10.
  Run on DC1 after ou-and-groups.ps1, as Domain Admin.
================================================================
#>
Import-Module ActiveDirectory

$Root     = 'OU=QVIS,DC=qvis,DC=local'
$DefaultPw = ConvertTo-SecureString 'ChangeMe!Now2026' -AsPlainText -Force
$UPN       = 'qvis.local'

# --- helper -----------------------------------------------------
function New-QvisUser {
    param(
        [string]$First,
        [string]$Last,
        [string]$Sam,
        [string]$Title,
        [string]$Dept,
        [string]$OU,
        [string[]]$Groups
    )
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$Sam'" -ErrorAction SilentlyContinue)) {
        New-ADUser `
            -Name "$First $Last" `
            -GivenName $First -Surname $Last `
            -SamAccountName $Sam `
            -UserPrincipalName "$Sam@$UPN" `
            -EmailAddress "$Sam@qvistech.ca" `
            -DisplayName "$First $Last" `
            -Title $Title -Department $Dept -Company 'QVIS Technology Solutions' `
            -Path $OU `
            -AccountPassword $DefaultPw `
            -ChangePasswordAtLogon $true `
            -Enabled $true
        Write-Host "  + User $Sam created in $OU"
    } else {
        Write-Host "  = User $Sam already exists"
    }
    foreach ($g in $Groups) { Add-ADGroupMember -Identity $g -Members $Sam }
}

# ---------- PHASE 1 — 10 launch users ---------------------------
New-QvisUser -First Adaeze   -Last Okafor   -Sam adaeze.okafor   -Title 'Managing Director'  -Dept 'Executive'        -OU "OU=Executive,OU=Users,$Root"                  -Groups G_Exec_Users
New-QvisUser -First Marcus   -Last Lee      -Sam marcus.lee      -Title 'Operations Manager' -Dept 'Executive'        -OU "OU=Executive,OU=Users,$Root"                  -Groups G_Exec_Users
New-QvisUser -First Priya    -Last Sharma   -Sam priya.sharma    -Title 'Finance & HR Mgr'   -Dept 'Finance-HR'       -OU "OU=Finance-HR,OU=Users,$Root"                 -Groups G_FinanceHR_Users
New-QvisUser -First Daniel   -Last Chen     -Sam daniel.chen     -Title 'Sr Network Engineer'-Dept 'Technical'        -OU "OU=Network,OU=Technical,OU=Users,$Root"       -Groups G_Network_Engineers,G_NetAdmins
New-QvisUser -First Olumide  -Last Tunde    -Sam olumide.tunde   -Title 'Network Technician' -Dept 'Technical'        -OU "OU=Network,OU=Technical,OU=Users,$Root"       -Groups G_Network_Engineers,G_NetAdmins
New-QvisUser -First Aisha    -Last Mohamed  -Sam aisha.mohamed   -Title 'Sr Cloud/Sysadmin'  -Dept 'Technical'        -OU "OU=Cloud-Sysadmin,OU=Technical,OU=Users,$Root" -Groups G_Cloud_Admins,G_ServerAdmins
New-QvisUser -First Jordan   -Last Reyes    -Sam jordan.reyes    -Title 'Helpdesk T1'        -Dept 'Support'          -OU "OU=Support-Admin,OU=Users,$Root"              -Groups G_Helpdesk_T1
New-QvisUser -First Sofia    -Last Almeida  -Sam sofia.almeida   -Title 'Sales Lead'         -Dept 'Sales-Marketing'  -OU "OU=Sales-Marketing,OU=Users,$Root"            -Groups G_Sales_Users
New-QvisUser -First Liam     -Last "O'Connor" -Sam liam.oconnor  -Title 'Sales Rep'          -Dept 'Sales-Marketing'  -OU "OU=Sales-Marketing,OU=Users,$Root"            -Groups G_Sales_Users
New-QvisUser -First Emma     -Last Taylor   -Sam emma.taylor     -Title 'Office Administrator' -Dept 'Support'        -OU "OU=Support-Admin,OU=Users,$Root"              -Groups G_Office_Admin

Write-Host "`n[OK]  10 launch users provisioned.`n" -ForegroundColor Green

# ---------- PHASE 2 — uncomment as each hire is made ------------
<#
New-QvisUser -First Hannah   -Last Ng       -Sam hannah.ng       -Title 'CFO'                 -Dept 'Executive'        -OU "OU=Executive,OU=Users,$Root"                  -Groups G_Exec_Users
New-QvisUser -First Tomas    -Last Petrov   -Sam tomas.petrov    -Title 'HR Coordinator'      -Dept 'Finance-HR'       -OU "OU=Finance-HR,OU=Users,$Root"                 -Groups G_FinanceHR_Users
New-QvisUser -First Nadia    -Last Hassan   -Sam nadia.hassan    -Title 'Marketing Specialist'-Dept 'Sales-Marketing'  -OU "OU=Sales-Marketing,OU=Users,$Root"            -Groups G_Sales_Users
New-QvisUser -First Ben      -Last Murphy   -Sam ben.murphy      -Title 'Sales Rep'           -Dept 'Sales-Marketing'  -OU "OU=Sales-Marketing,OU=Users,$Root"            -Groups G_Sales_Users
New-QvisUser -First Yuki     -Last Tanaka   -Sam yuki.tanaka     -Title 'Sales Rep'           -Dept 'Sales-Marketing'  -OU "OU=Sales-Marketing,OU=Users,$Root"            -Groups G_Sales_Users
New-QvisUser -First Idris    -Last Bello    -Sam idris.bello     -Title 'Project Manager'     -Dept 'Technical'        -OU "OU=Technical,OU=Users,$Root"                  -Groups G_AllStaff
New-QvisUser -First Renata   -Last Costa    -Sam renata.costa    -Title 'Cybersecurity Analyst'-Dept 'Technical'       -OU "OU=Network,OU=Technical,OU=Users,$Root"       -Groups G_Network_Engineers,G_NetAdmins
New-QvisUser -First Kai      -Last Nguyen   -Sam kai.nguyen      -Title 'Jr Cloud Engineer'   -Dept 'Technical'        -OU "OU=Cloud-Sysadmin,OU=Technical,OU=Users,$Root" -Groups G_Cloud_Admins
New-QvisUser -First Maya     -Last Iyer     -Sam maya.iyer       -Title 'Helpdesk T2'         -Dept 'Support'          -OU "OU=Support-Admin,OU=Users,$Root"              -Groups G_Helpdesk_T2
New-QvisUser -First Eli      -Last Park     -Sam eli.park        -Title 'Helpdesk T1'         -Dept 'Support'          -OU "OU=Support-Admin,OU=Users,$Root"              -Groups G_Helpdesk_T1
#>
