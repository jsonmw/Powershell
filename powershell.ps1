# CIS 360 - Jason Wild
# Assignment #4

# This Script helps view and manage information about users.

# Defines the menu items


# Creates a new user
function Create-NewUser {
    try {
        $newUser = Read-Host "Enter username"
        $fullName = Read-Host "Enter Full Name"
        $password = Read-Host "Enter password" -AsSecureString
        $description = Read-Host "Description of user"
        Start-Process powershell.exe -Verb RunAs -ArgumentList "New-LocalUser -Name $newUser -Password $password -FullName $fullName -Description $description -ErrorAction Stop"
        Write-Host "User $($newUser) has been created."
    }
    catch {
        Write-Host "Error creating user: $($_.Exception.Message)`n"
    }
    Read-Host "Press Enter to continue..."
}

# This function deletes all users that have not logged in in 30 days. It doesn't seem to work, but I still do NOT recommend trying it outside of a virtual machine.
# The logic of the code does work, though, and it will print out the users it finds.

function Remove-InactiveUsers {
    try {
        $thresholdDate = (Get-Date).AddDays(-30)
        $removedUsers = Get-LocalUser | Where-Object { $_.LastLogon -lt $thresholdDate } | ForEach-Object { $_.Name }
        Start-Process powershell.exe -Verb RunAs -ArgumentList "Get-LocalUser | Where-Object {\$_.LastLogon -lt \$($thresholdDate)} | Remove-LocalUser -Force -ErrorAction Stop"
        Write-Host "Inactive users have been deleted.`n"
        if ($removedUsers) {
            Write-Host "The following users were removed:`n"
            $removedUsers | ForEach-Object { Write-Host $_ }
        }
        else {
            Write-Host "No inactive users were found.`n"
        }
    }
    catch {
        Write-Host "Error deleting users: $($_.Exception.Message)`n"
    }
    Read-Host "Press Enter to continue..."
}

# This function prints information about all the users in the current system in a table, including last password change,
# whether or not their password is expired, and if their account is active or disabled.
function Get-LocalUsersInfo {
    $users = Get-LocalUser
    
    $userDetails = foreach ($user in $users) {
        $lastPasswordChange = if ($user.PasswordLastSet -eq $null) { "Never" } else { $user.PasswordLastSet }
        $changePasswordOnNextLogon = if ($user.PasswordExpired) { "Yes" } else { "No" }
        $accountStatus = if ($user.Enabled) { "Active" } else { "Disabled" }
        
        [PSCustomObject]@{
            "User Name" = $user.Name
            "Last Password Change" = $lastPasswordChange
            "Change Password on Login" = $changePasswordOnNextLogon
            "Account Status" = $accountStatus
        }
    }
    $userDetails | Format-Table -AutoSize
    Read-Host "Press Enter to continue..."
}

# This function forces a password change to all users by resetting the "PasswordExpired" field on User object.
# It doesn't seem to work but, again, I recommend care in testing.

function Force-PasswordChange {
    try {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "Get-LocalUser | Set-LocalUser -PasswordExpired \$true -ErrorAction Stop"
        Write-Host "All users have been set to change their password at the next logon."
    }
    catch {
        Write-Host "Error setting password change: $($_.Exception.Message)"
    }
    Read-Host "Press Enter to continue..."
}

# Displays the help screen.
function Show-Help {
    Clear-Host
    Write-Host "This script allows the user to view information or make changes to User accounts on the current system,"
    Write-Host "with the following options:`n"
    Write-Host "1. Create new user with default permissions"
    Write-Host "2. Remove all users that have not logged in within 30 days"
    Write-Host "3. View all users on the system"
    Write-Host "4. Force all users to change password"
    Write-Host "5. Help information"
    Write-Host "6. Display user information"
    Write-Host "7. Exit"
    Read-Host "`nPress Enter to continue..."
}

# Displays information about a specified user, either accepted as an argument or input in a prompt
function Display-UserInformation {
    Clear-Host

    if ($args.Count -gt 0) {
        $arguser = Get-LocalUser -Name $args[0]
        if ($arguser -eq $null) {
            Write-Host "User not found. Please try again."
            exit
        }
        $UserName = $user.Name
    }
    else {
        $UserName = Read-Host "Enter username"
    }
    
    try {
        try {
            $user = Get-LocalUser -Name $UserName
            $props = @{
                Name = $user.Name
                Description = $user.Description
                Enabled = $user.Enabled
                PasswordExpires = $user.PasswordExpires
                PasswordRequired = $user.PasswordRequired
                PasswordLastSet = $user.PasswordLastSet
                PasswordNeverExpires = $user.PasswordNeverExpires
                UserMayNotChangePassword = $user.UserMayNotChangePassword
                UserFlags = $user.UserFlags -join ', '
            }
            $table = New-Object psobject -Property $props
            $table | Format-Table
        }
        catch {
            Write-Host "Error displaying user information: $($_.Exception.Message)`n"
        }
    }
    catch {
        Write-Host "Error displaying user information: $($_.Exception.Message)`n"
    }
    Read-Host "`nPress Enter to continue..."
}

# Display the menu
do {
    Clear-Host
    Write-Host "Please select an option:`n"

    Write-Host "1. Create new user with default permissions"
    Write-Host "2. Remove all users that have not logged in within 30 days"
    Write-Host "3. View all users on the system"
    Write-Host "4. Force all users to change password"
    Write-Host "5. Help information"
    Write-Host "6. Display user information"
    Write-Host "7. Exit"

    # Get user input
    $choice = Read-Host "`nEnter choice (1-7)"
    switch ($choice) {
        "1" { Create-NewUser }
        "2" { Remove-InactiveUsers }
        "3" { Get-LocalUsersInfo }
        "4" { Force-PasswordChange }
        "5" { Show-Help }
        "6" { Display-UserInformation }
        "7" { break }

        default {
            # Handle invalid input
            Write-Host "Invalid choice. Please try again."
            Read-Host "Press Enter to continue..."
        }
    }
} while ($choice -ne "7")