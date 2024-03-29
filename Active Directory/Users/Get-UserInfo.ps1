Import-Module ActiveDirectory
function Get-UserInfo
{
    <# 
    .SYNOPSIS 
        This function will get information about user account.
 
    .DESCRIPTION 
        This function will get information about user password expiration date or last password change.

    .PARAMETER Username
         Specifies the username.
  
    .EXAMPLE 
        PS C:\> Get-UserPasswordInfo -Username foo
        This command gets basic and password information for 'foo' user.
 
    .NOTES
        Author:       Daniel Schwitzgebel
        Created:      07/08/2014
        Modified:     18/03/2022
        Version:      2.1.0
#>

    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()] 
    param ( 
        [Parameter(Mandatory)] 
        [String]
        $Username
    )
    
    process
    {
        try
        {
            $getADUserProperties = @(
                'PasswordExpired',
                'PasswordNeverExpires',
                'BadPwdCount',
                'PasswordLastSet',
                'lastBadPasswordAttempt',
                'LockedOut',
                'Enabled',
                'LastLogon',
                'SID',
                'l',
                'Comment',
                'manager',
                'extensionAttribute3'
            )

            $usrInfo = Get-ADUser -Identity $Username -Properties $getADUserProperties
        }
        catch
        {
            throw 'User not found in Active Directory.'
        }

        $maxPswAgeTime = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
        $minPswAgeTime = (Get-ADDefaultDomainPasswordPolicy).MinPasswordAge
        $pswLockoutThreshold = (Get-ADDefaultDomainPasswordPolicy).LockoutThreshold
        $usrLastLogon = [DateTime]::FromFileTime($usrInfo.LastLogon)
        $manager = (Get-ADUser -Identity $usrInfo.manager -Properties displayName).displayName
      
        [PSCustomObject]@{
            Username     = $Username
            Name         = "$($usrInfo.GivenName) $($usrInfo.Surname)"
            OU           = ($usrInfo.DistinguishedName -split ',', 2)[1]
            SID          = $usrInfo.SID
            Location     = $usrInfo.l
            Department   = $usrInfo.Comment
            Manager      = $manager
            'Last logon' = $usrLastLogon
            'Locked out' = $usrInfo.LockedOut
            Enabled      = $usrInfo.Enabled
        }

        [PSCustomObject]@{
            'Password Last Set'         = $usrInfo.PasswordLastSet
            'Password expired'          = $usrInfo.PasswordExpired
            'Password expiration date'  = ($usrInfo.PasswordLastSet + $maxPswAgeTime)
            'Last bad password attempt' = $usrInfo.lastBadPasswordAttempt
            'Password changeable'       = ($usrInfo.PasswordLastSet).AddDays($minPswAgeTime.TotalDays)
            'Password bad count'        = "$($usrInfo.BadPwdCount) of $pswLockoutThreshold"
            'Password never expires'    = $usrInfo.PasswordNeverExpires
        }

        [PSCustomObject]@{
            'Badge number' = $usrInfo.extensionAttribute3
        }
    }
}