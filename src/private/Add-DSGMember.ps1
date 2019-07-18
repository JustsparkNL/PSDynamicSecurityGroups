Function Add-DSGMember {
    <#
    .SYNOPSIS
        Adds members to the Dynamic Security Group.
    .DESCRIPTION
        Adds members to the Dynamic Security Group.
    .PARAMETER GroupName
        The DynamicSecurityGroup name to get members from.
    .PARAMETER Member
        The member to add to the Dynamic Security Group, can be a sAMAccountName, ObjectGUID or an AD user object.
    .EXAMPLE
        Add-DSGMember -GroupName "DynamicSecurityGroup" -Member "sAMAccountName"
    .NOTES

    #>
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true, HelpMessage = 'The Dynamic Security Group to add the member to.')]
        $GroupName,
        [Parameter(Mandatory = $true, HelpMessage = 'The member to add to the Dynamic Security Group, can be a sAMAccountName, ObjectGUID or an AD user object.')]
        $Member
    )
    Begin {
        if ($script:ThisModuleLoaded -eq $true) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    } Process {
        Try {
            Try {
                if ($null -eq $($Member.Name)) {
                    Write-Verbose "$($FunctionName): Adding '$($Member)' to '$($GroupName)'"
                } Else {
                    Write-Verbose "$($FunctionName): Adding '$($Member.Name)' to '$($GroupName)'"
                }
                if ($null -eq $($Member.objectGUID)) {
                    Add-ADGroupMember -Identity $GroupName -Members $Member -ErrorAction Stop
                } Else {
                    Add-ADGroupMember -Identity $GroupName -Members $Member.objectGUID -ErrorAction Stop
                }
            } Catch {
                Write-Warning -Message "$($FunctionName): Failed to add '$Member' to group '$GroupName'"
                Write-Error -Message "$($FunctionName): $PSItem"
            }
        } Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    } End {
        Write-Verbose "$($FunctionName): End."
    }
}