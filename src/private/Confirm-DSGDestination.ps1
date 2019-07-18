Function Confirm-DSGDestination {
    <#
    .SYNOPSIS
        Confirm that the destination OU and Group can be created in the Active Directory.
    .DESCRIPTION
        Confirm that the destination OU and Group can be created in the Active Directory.
    .PARAMETER DestOU
        The OU the DynamicSecurityGroup should exist in.
    .PARAMETER GroupName
        The DynamicSecurityGroup name to put members in.
    .EXAMPLE
        Confirm-DSGDestination -DestOU "OU=DynamicSecurityGroups,DC=ad,DC=SomeDomain,DC=tld" -GroupName "DynamicSecurityGroup-1"
    .NOTES

    #>
    [Cmdletbinding()]
    Param (
       [Parameter(Mandatory = $true, HelpMessage = 'The OU the DynamicSecurityGroup should exist in.')]
       $DestOU,
       [Parameter(Mandatory = $true, HelpMessage = 'The DynamicSecurityGroup name to put members in.')]
       $GroupName
    )
    Begin {
        if ($script:ThisModuleLoaded -eq $true) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    } Process {
        Try {
            Write-Debug -Message "$($FunctionName): Check that the destination OU exists, otherwise we won't be able to create the Dynamic Security Groups at all"
            Try {
                Get-ADOrganizationalUnit -Identity $DestOU -ErrorAction Continue | Out-Null
            }
            Catch {
                If ($_.Exception.GetType().Name -eq "ADIdentityNotFoundException") {
                    Write-Error -Message "$($FunctionName): Skipping sync of '$GroupName', following destination OU does not exist: '$DestOU'"
                    return $false
                }
                Else {
                  Write-Error -Message "$($FunctionName): $PSItem"
                }
            }
            Write-Debug -Message "$($FunctionName): Check that a group with the same sAMAccountName as our destination group does not exist Elsewhere in AD - this attribute must be unique within a the Active Directory."
            $ADGroup = Get-ADGroup -Filter {sAMAccountName -eq $GroupName} -ErrorAction Continue
            Write-Debug -Message "$($FunctionName): If group already exists ensure it's in the expected OU"
            If($ADGroup -and (([string]([ADSI]"LDAP://$ADGroup").PSBase.Parent.distinguishedName) -ne $DestOU)) {
                Write-Error -Message "$($FunctionName): Skipping sync of '$GroupName', a group with the same sAMAccountName already exists in a fifferent part of the hierarchy:'$($ADGroup.DistinguishedName)'"
                Return $false
            }
            Return $true
        } Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
    End {
        Write-Verbose "$($FunctionName): End."
    }
}