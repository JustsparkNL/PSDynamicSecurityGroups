Function Update-DSG {
    <#
    .SYNOPSIS
        A PowerShell function that provides an easy way to create and manage Active Directory Dynamic Security Groups.
    .DESCRIPTION
        A PowerShell function that provides an easy way to manage Active Directory Dynamic Security Groups. This function requires the PowerShell Active Directory module from Microsoft.
        As you might have already guessed, when running this command it will replace all members of supplied group.
        If the supplied group does not yet exsist this function will create the supplied group.
    .PARAMETER SearchBase
        The base OU DistinguishedName of to search for objects.
    .PARAMETER SearchScope
        The Scope of the search for objects.
    .PARAMETER Server
        Which domain controller/FQDN to query for source objects.
    .PARAMETER ADObjectType
        The ADObjectType to search for.
    .PARAMETER GroupName
        The DynamicSecurityGroup name to get members from.
    .PARAMETER DestOU
        The OU the DynamicSecurityGroup exists in.
    .PARAMETER GroupCategory
        The GroupCategory the DynamicSecurityGroup should be created as (If it doesnt exist)
    .PARAMETER GroupScope
        The GroupScope the DynamicSecurityGroup should be created as (If it doesnt exist)
    .PARAMETER GroupDescription
        The DynamicSecurityGroup Description
    .PARAMETER Force
        Skip the confirmation before updating the DynamicSecurityGroup.
    .EXAMPLE
        Update-DSG -SearchBase "OU=SomeOU,DC=ad,DC=SomeDomain,DC=tld" -SearchScope SubTree -Server 'ad.domain.tld' -ADObjectType computer -GroupName 'DynamicSecurityGroup-1' -DestOU "OU=SomeOtherOU,DC=ad,DC=SomeDomain,DC=tld" -GroupCategory Security -GroupScope Global -GroupDescription 'SomeDescription'
    .NOTES
        Based of https://github.com/davegreen/shadowGroupSync by David Green, http://www.tookitaway.co.uk
    #>
    [Cmdletbinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory = $true, HelpMessage = 'The base OU DistinguishedName of to search for objects. Multiples can be specIfied and chained together with a semicolon.')]
        $SearchBase,
        [Parameter(Mandatory = $true, HelpMessage = 'The Scope of the search for objects.')]
        [ValidateSet("Base","OneLevel","SubTree")]
        $SearchScope,
        [Parameter(Mandatory = $true, HelpMessage = 'Which domain controller/FQDN to query for source objects.')]
        $Server,
        [Parameter(Mandatory = $true, HelpMessage = 'The ADObjectType to search for.')]
        [ValidateSet("computer","user-mail-enabled","user","user-enabled","user-disabled")]
        $ADObjectType,
        [Parameter(Mandatory = $true, HelpMessage = 'The DynamicSecurityGroup name to get members from.')]
        $GroupName,
        [Parameter(Mandatory = $true, HelpMessage = 'The OU the DynamicSecurityGroup exists in.')]
        $DestOU,
        [Parameter(Mandatory = $true, HelpMessage = 'The GroupCategory the DynamicSecurityGroup should be created as (If it doesnt exist)')]
        [ValidateSet("Distribution","Security")]
        $GroupCategory,
        [Parameter(Mandatory = $true, HelpMessage = 'The GroupScope the DynamicSecurityGroup should be created as (If it doesnt exist)')]
        [ValidateSet("Global","Universal")]
        $GroupScope,
        [Parameter(Mandatory = $true, HelpMessage = 'The DynamicSecurityGroup Description')]
        $GroupDescription,
        [Parameter(HelpMessage = 'Skip the confirmation before updating the DynamicSecurityGroup.')]
        [Switch]$Force
    )
    Begin {
        Try {
            if ($script:ThisModuleLoaded -eq $true) {
                Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
            }
            $FunctionName = $MyInvocation.MyCommand.Name
            Write-Verbose "$($FunctionName): Begin."
            If ( -not (Confirm-DSGDestination -DestOU $DestOU -GroupName $GroupName)) {
                continue
            }
        } Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    } Process {
    if ($PSCmdlet.ShouldProcess("Updating '$GroupName'")) {
        if ( -not ($Force -or $PSCmdlet.ShouldContinue("Running this command will update '$($GroupName)'. This will replace all members with objects listed in '$($SearchBase)' with the '$($ADObjectType)'-ADObjectType. Do you want to continue?", "This will replace all members of '$($GroupName)'"))) {
            return # user replied no
        }
        $Obj          = Get-DSGSourceObject -SearchBase $SearchBase -SearchScope $SearchScope -Server $Server -ADObjectType $ADObjectType
        $GroupMembers = Get-DSGMember -GroupName $GroupName -DestOU $DestOU -GroupCategory $GroupCategory -GroupScope $GroupScope -GroupDescription $GroupDescription
        If ( -not ($GroupMembers) -and ($Obj)) {
            Write-Debug "If the group is empty, populate the group."
            Write-Verbose "'$($GroupName)' is empty"
            ForEach ($o in $Obj) {
                Add-DSGMember -GroupName $GroupName -Member $o
            }
        } ElseIf (($null -eq $Obj) -and ($GroupMembers)) {
            Write-Debug "$($FunctionName): If there are no members in the sync source, empty the group."
            Write-Verbose "$($FunctionName): Emptying '$($GroupName)'"
            ForEach ($Member in $GroupMembers) {
                Remove-DSGMember -GroupName $GroupName -Member $Member
            }
        }
        ElseIf (($GroupMembers) -and ($Obj)) {
            Write-Debug "$($FunctionName) - If the group has members, get the group members to mirror the OU contents."
            Switch (Compare-Object -ReferenceObject $GroupMembers -DIfferenceObject $Obj -property objectGUID, Name) {
                { $_.SideIndicator -eq "=>" } { Add-DSGMember    $GroupName $_ }
                { $_.SideIndicator -eq "<=" } { Remove-DSGMember $GroupName $_ }
            }
        }
        Write-Verbose "$($FunctionName): The sync of group '$($GroupName)' has been completed."
    }
    } End {
        Write-Verbose "$($FunctionName): End."
    }
}