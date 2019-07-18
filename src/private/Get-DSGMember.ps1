Function Get-DSGMember {
    <#
    .SYNOPSIS
        Gets the members from the Dynamic Security Group. If the group does not exist, create it.
    .DESCRIPTION
        Gets the members from the Dynamic Security Group. If the group does not exist, create it.
    .PARAMETER GroupName
        The DynamicSecurityGroup name to get members from.
    .PARAMETER DestOU
         The OU where the DynamicSecurityGroup exists (or should exists) in.
    .PARAMETER GroupCategory
        The GroupCategory the DynamicSecurityGroup should be created as (if it doesnt exist).
    .PARAMETER GroupScope
        The GroupScope the DynamicSecurityGroup should be created as (if it doesnt exist).
    .PARAMETER GroupDescription
        The description of the DynamicSecurityGroup.
    .EXAMPLE
        Get-DSGMember -GroupName "DynamicSecurityGroup" -DestOU "OU=SomeOU,DC=AD,DC=SomeDomain,DC=tld" -GroupCategory "Security" -GroupScope "Global" -GroupDescription "DynamicSecurityGroup"
    .NOTES
        For use with Fine Grained Password Policies, the GroupScope should be set to Global.
        If you are using this script with child domains, the GroupScope may need to be set to Universal.
    #>
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true, HelpMessage = 'The DynamicSecurityGroup name to get members from.')]
        $GroupName,
        [Parameter(Mandatory = $true, HelpMessage = 'The OU the DynamicSecurityGroup exists in.')]
        $DestOU,
        [Parameter(Mandatory = $true, HelpMessage = 'The GroupCategory the DynamicSecurityGroup should be created as (If it doesnt exist)')]
        [ValidateSet("Distribution","Security","0","1")]
        $GroupCategory,
        [Parameter(Mandatory = $true, HelpMessage = 'The GroupScope the DynamicSecurityGroup should be created as (If it doesnt exist)')]
        [ValidateSet("Global","Universal","0","1")]
        $GroupScope,
        [Parameter(Mandatory = $true, HelpMessage = 'The Description of the DynamicSecurityGroup.')]
        $GroupDescription
    )
    Begin {
        Try {        
            $GroupCategory = $(Resolve-DSGGroupCategoryFriendlyName -GroupCategory $GroupCategory)
            Try {
                if ($null -eq $(Get-ADGroup -Filter { sAMAccountName -eq $GroupName } -Properties Description -SearchBase $DestOU -ErrorAction Stop)) {
                    Write-Error "Could not find a group with the name '$($GroupName)'" -ErrorAction Stop
                }
            } Catch {
                Try {
                    New-ADGroup -Name $GroupName -sAMAccountName $GroupName -Description $GroupDescription -Path $DestOU -GroupCategory $GroupCategory -GroupScope $GroupScope -ErrorAction Stop
                } Catch {
                    Write-Error "Could not create group a group named '$($GroupName)' - $($PSItem)" -ErrorAction Stop
                }
            }
        } Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }            
    } Process {
        Try {
            $ADGroup = Get-ADGroup -Filter { sAMAccountName -eq $GroupName } -Properties Description -SearchBase $DestOU -ErrorAction Stop
            if ($null -eq $ADGroup) {
                Write-Error "Could not find a group with the name '$($GroupName)'" -ErrorAction Stop
            }                     
            $GroupMembers = Get-ADGroupMember -Identity $GroupName -ErrorAction Stop
            If ($ADGroup.Description -ne $GroupDescription) {
                Set-ADGroup -Identity $ADGroup -Description $GroupDescription -ErrorAction Stop
            }               
        } Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    } End {
        Return $GroupMembers
    }
}
