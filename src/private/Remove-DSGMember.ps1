Function Remove-DSGMember {
    <#
    .SYNOPSIS
        Removes members from the Dynamic Security Group. 
    .DESCRIPTION
        Removes members from the Dynamic Security Group. 
    .PARAMETER GroupName
        The DynamicSecurityGroup name to remove members from.
    .PARAMETER Member
        The member to remove to the Dynamic Security Group, can be a sAMAccountName, ObjectGUID or an AD user object.
    .EXAMPLE
        Remove-DSGMember -GroupName "DynamicSecurityGroup" -Member "sAMAccountName"
    .NOTES

    #>
    [Cmdletbinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory = $true, HelpMessage = 'The DynamicSecurityGroup to remove the member from')]
        $GroupName,
        [Parameter(Mandatory = $true, HelpMessage = 'The member to remove from the DynamicSecurityGroup, can be a sAMAccountName, ObjectGUID or an AD user object.')]
        $Member
    )
    Begin {
    
    } Process {
        Try {
            Try {
                if ($null -eq $($Member.Name)) {
                    Write-Verbose "Removing '$($Member)' from '$($GroupName)'"
                } Else {
                    Write-Verbose "Removing '$($Member.Name)' from '$($GroupName)'"
                }
                if ($PSCmdlet.ShouldProcess("Removing AD group member: '$Member'")) {
                    if ($null -eq $($Member.objectGUID)) {
                        Remove-ADGroupMember -Identity $GroupName -Members $Member -Confirm:$false -ErrorAction Stop
                    } Else {
                        Remove-ADGroupMember -Identity $GroupName -Members $Member.objectGUID -Confirm:$false -ErrorAction Stop
                    }
                }
            } Catch {
                Write-Warning "Failed to remove '$Member' from group '$GroupName'"
                Write-Error $PSItem
            }
        } Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    } End { 
    
    }
}