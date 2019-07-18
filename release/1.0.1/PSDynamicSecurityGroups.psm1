## Pre-Loaded Module code ##

<#
 Put all code that must be run prior to function dot sourcing here.

 This is a good place for module variables as well. The only rule is that no 
 variable should rely upon any of the functions in your module as they 
 will not have been loaded yet. Also, this file cannot be completely
 empty. Even leaving this comment is good enough.
#>

## PRIVATE MODULE FUNCTIONS AND DATA ##

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

function Get-CallerPreference {
    <#
    .Synopsis
       Fetches "Preference" variable values from the caller's scope.
    .DESCRIPTION
       Script module functions do not automatically inherit their caller's variables, but they can be
       obtained through the $PSCmdlet variable in Advanced Functions.  This function is a helper function
       for any script module Advanced Function; by passing in the values of $ExecutionContext.SessionState
       and $PSCmdlet, Get-CallerPreference will set the caller's preference variables locally.
    .PARAMETER Cmdlet
       The $PSCmdlet object from a script module Advanced Function.
    .PARAMETER SessionState
       The $ExecutionContext.SessionState object from a script module Advanced Function.  This is how the
       Get-CallerPreference function sets variables in its callers' scope, even if that caller is in a different
       script module.
    .PARAMETER Name
       Optional array of parameter names to retrieve from the caller's scope.  Default is to retrieve all
       Preference variables as defined in the about_Preference_Variables help file (as of PowerShell 4.0)
       This parameter may also specify names of variables that are not in the about_Preference_Variables
       help file, and the function will retrieve and set those as well.
    .EXAMPLE
       Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

       Imports the default PowerShell preference variables from the caller into the local scope.
    .EXAMPLE
       Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -Name 'ErrorActionPreference','SomeOtherVariable'

       Imports only the ErrorActionPreference and SomeOtherVariable variables into the local scope.
    .EXAMPLE
       'ErrorActionPreference','SomeOtherVariable' | Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

       Same as Example 2, but sends variable names to the Name parameter via pipeline input.
    .INPUTS
       String
    .OUTPUTS
       None.  This function does not produce pipeline output.
    .LINK
       about_Preference_Variables
    #>

    [CmdletBinding(DefaultParameterSetName = 'AllVariables')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_.GetType().FullName -eq 'System.Management.Automation.PSScriptCmdlet' })]
        $Cmdlet,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SessionState]$SessionState,

        [Parameter(ParameterSetName = 'Filtered', ValueFromPipeline = $true)]
        [string[]]$Name
    )

    begin {
        $filterHash = @{}
    }
    
    process {
        if ($null -ne $Name)
        {
            foreach ($string in $Name)
            {
                $filterHash[$string] = $true
            }
        }
    }

    end {
        # List of preference variables taken from the about_Preference_Variables help file in PowerShell version 4.0

        $vars = @{
            'ErrorView' = $null
            'FormatEnumerationLimit' = $null
            'LogCommandHealthEvent' = $null
            'LogCommandLifecycleEvent' = $null
            'LogEngineHealthEvent' = $null
            'LogEngineLifecycleEvent' = $null
            'LogProviderHealthEvent' = $null
            'LogProviderLifecycleEvent' = $null
            'MaximumAliasCount' = $null
            'MaximumDriveCount' = $null
            'MaximumErrorCount' = $null
            'MaximumFunctionCount' = $null
            'MaximumHistoryCount' = $null
            'MaximumVariableCount' = $null
            'OFS' = $null
            'OutputEncoding' = $null
            'ProgressPreference' = $null
            'PSDefaultParameterValues' = $null
            'PSEmailServer' = $null
            'PSModuleAutoLoadingPreference' = $null
            'PSSessionApplicationName' = $null
            'PSSessionConfigurationName' = $null
            'PSSessionOption' = $null

            'ErrorActionPreference' = 'ErrorAction'
            'DebugPreference' = 'Debug'
            'ConfirmPreference' = 'Confirm'
            'WhatIfPreference' = 'WhatIf'
            'VerbosePreference' = 'Verbose'
            'WarningPreference' = 'WarningAction'
        }

        foreach ($entry in $vars.GetEnumerator()) {
            if (([string]::IsNullOrEmpty($entry.Value) -or -not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($entry.Value)) -and
                ($PSCmdlet.ParameterSetName -eq 'AllVariables' -or $filterHash.ContainsKey($entry.Name))) {
                
                $variable = $Cmdlet.SessionState.PSVariable.Get($entry.Key)
                
                if ($null -ne $variable) {
                    if ($SessionState -eq $ExecutionContext.SessionState) {
                        Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                    }
                    else {
                        $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                    }
                }
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'Filtered') {
            foreach ($varName in $filterHash.Keys) {
                if (-not $vars.ContainsKey($varName)) {
                    $variable = $Cmdlet.SessionState.PSVariable.Get($varName)
                
                    if ($null -ne $variable)
                    {
                        if ($SessionState -eq $ExecutionContext.SessionState)
                        {
                            Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                        }
                        else
                        {
                            $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                        }
                    }
                }
            }
        }
    }
}

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
        [Parameter(Mandatory = $false, HelpMessage = 'The Description of the DynamicSecurityGroup.')]
        $GroupDescription
    )
    Begin {
        if ($script:ThisModuleLoaded -eq $true) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        Try {
            $GroupCategory = $(Resolve-DSGGroupCategoryFriendlyName -GroupCategory $GroupCategory)
            Try {
                if ($null -eq $(Get-ADGroup -Filter { sAMAccountName -eq $GroupName } -Properties Description -SearchBase $DestOU -ErrorAction Stop)) {
                    Write-Error "$($FunctionName): Could not find a group with the name '$($GroupName)'" -ErrorAction Stop
                }
            } Catch {
                Try {
                    New-ADGroup -Name $GroupName -sAMAccountName $GroupName -Description $GroupDescription -Path $DestOU -GroupCategory $GroupCategory -GroupScope $GroupScope -ErrorAction Stop
                } Catch {
                    Write-Error "$($FunctionName): Could not create group a group named '$($GroupName)' - $($PSItem)" -ErrorAction Stop
                }
            }
        } Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    } Process {
        Try {
            $ADGroup = Get-ADGroup -Filter { sAMAccountName -eq $GroupName } -Properties Description -SearchBase $DestOU -ErrorAction Stop
            if ($null -eq $ADGroup) {
                Write-Error "$($FunctionName): Could not find a group with the name '$($GroupName)'" -ErrorAction Stop
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
        Write-Verbose "$($FunctionName): End."
    }
}


Function Get-DSGSourceObject {
    <#
    .SYNOPSIS
        Gets AD objects from the specIfied OU or OUs and returns the collection.
    .DESCRIPTION
        Gets AD objects from the specIfied OU or OUs and returns the collection.
    .PARAMETER SearchBase
        The base OU DistinguishedName of to search for objects.
    .PARAMETER Server
         Which domain controller/FQDN to query for source objects.
    .PARAMETER ADObjectType
        The ADObjectType to search for.
    .PARAMETER SearchScope
        The Scope of the search for objects.
    .EXAMPLE
        Get-DSGSourceObject -SearchBase "OU=SomeOU,DC=AD,DC=SomeDomain,DC=tld" -SearchScope SubTree -Server ad.SomeDomain.tld -ADObjectType computer
    #>
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true, HelpMessage = 'The base OU DistinguishedName of to search for objects. Multiples can be specIfied and chained together with a semicolon.')]
        $SearchBase,
        [Parameter(Mandatory = $true, HelpMessage = 'The Scope of the search for objects.')]
        [ValidateSet("Base","OneLevel","SubTree","0","1","2")]
        $SearchScope,
        [Parameter(Mandatory = $true, HelpMessage = 'Which domain controller/FQDN to query for source objects.')]
        $Server,
        [Parameter(Mandatory = $true, HelpMessage = 'The ADObjectType to search for.')]
        [ValidateSet("computer","user-mail-enabled","user","user-enabled","user-disabled")]
        $ADObjectType
    )
    Begin {
        if ($script:ThisModuleLoaded -eq $true) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        $SearchScope = $(Resolve-DSGSearchScopeFriendlyName -SearchScope $SearchScope)
    } Process {
        Try {
            $MultiObj = @()
            $Obj      = $null
            $Bases    = $SearchBase.Split(";")
            Write-Debug -Message "$($FunctionName): If the searchbase is an array of searchbases, recall the function, concatenate the results and pass back the complete set."
            If ($Bases.Count -gt 1) {
                 ForEach ($Base in $Bases) {
                     $MultiObj += Get-DSGSourceObject -SearchBase $SearchBase -SearchScope $SearchScope -Server $Server -ADObjectType $ADObjectType
                 }
                 Return $MultiObj
            } Else {
                Try {
                    $Obj = Switch ($ADObjectType) {
                        {($_ -eq "user") -or ($_ -eq "user-enabled")} {
                            Get-ADUser -Filter { Enabled -eq $true } -SearchBase $SearchBase -SearchScope $SearchScope -Server $Server -ErrorAction Stop
                        }
                        "user-disabled" {
                            Get-ADUser -Filter { Enabled -eq $false } -SearchBase $SearchBase -SearchScope $SearchScope -Server $Server -ErrorAction Stop
                        }
                        "user-mail-enabled" {
                            Get-ADUser -Filter { Mail -like '*' -and Enabled -eq $true } -SearchBase $SearchBase -SearchScope $SearchScope -Server $Server -ErrorAction Stop
                        }
                        "computer" {
                            Get-ADComputer -Filter { Enabled -eq $true } -SearchBase $SearchBase -SearchScope $SearchScope -Server $Server -ErrorAction Stop
                        }
                        default {
                            Write-Error -Message "$($FunctionName): Invalid ADObjectType specIfied: '$($ADObjectType)'" -ErrorAction Stop
                        }
                    }
                    Write-Debug "`$($FunctionName): $Obj must be a collection of AD objects with a Name and an ObjectGUID property: '$($Obj)'"
                } Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                    Write-Error "$($FunctionName): The OU '$SearchBase' does not appear to exist." -ErrorAction Stop
                } Catch {
                    Write-Error -Message "$($FunctionName): $PSItem" -ErrorAction Stop
                }
                Return $Obj
            }
        } Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    } End {
        Write-Verbose "$($FunctionName): End."
    }
}

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
        if ($script:ThisModuleLoaded -eq $true) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    } Process {
        Try {
            Try {
                if ($null -eq $($Member.Name)) {
                    Write-Verbose "$($FunctionName): Removing '$($Member)' from '$($GroupName)'"
                } Else {
                    Write-Verbose "$($FunctionName): Removing '$($Member.Name)' from '$($GroupName)'"
                }
                if ($PSCmdlet.ShouldProcess("Removing AD group member: '$Member'")) {
                    if ($null -eq $($Member.objectGUID)) {
                        Remove-ADGroupMember -Identity $GroupName -Members $Member -Confirm:$false -ErrorAction Stop
                    } Else {
                        Remove-ADGroupMember -Identity $GroupName -Members $Member.objectGUID -Confirm:$false -ErrorAction Stop
                    }
                }
            } Catch {
                Write-Warning "$($FunctionName): Failed to remove '$Member' from group '$GroupName'"
                Write-Error -Message "$($FunctionName): $PSItem"
            }
        } Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    } End {
        Write-Verbose "$($FunctionName): End."
    }
}

Function Resolve-DSGGroupCategoryFriendlyName {
    <#
    .SYNOPSIS
        Resolve the group category 'Friendly Name' to the appropriate interger.
    .DESCRIPTION
        Resolve the group category 'Friendly Name' to the appropriate interger, returns 1 if supplied value is unknown/undefined in switch block.
    .PARAMETER GroupCategory
        The DynamicSecurityGroup Group Category friendly name.
    .EXAMPLE
        Resolve-DSGGroupCategoryFriendlyName -GroupCategory "Security"
    .NOTES
        0 and 1 are added to the ValidateSet for function recalling/nested functions.
    #>
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true, HelpMessage = 'The DynamicSecurityGroup Group Category friendly name.')]
        [ValidateSet("Distribution","Security","0","1")]
        $GroupCategory
    )
    Begin {
        if ($script:ThisModuleLoaded -eq $true) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        $Category = @()
    } Process {
        Try {
            $Category = Switch ($GroupCategory) {
                { ($_ -eq "Distribution") -or ($_ -eq 0) } { 0 }
                { ($_ -eq "Security")     -or ($_ -eq 1) } { 1 }
                default                                    { 1 }
            }
        } Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    } End {
        Return $Category
        Write-Verbose "$($FunctionName): End."
    }
}

Function Resolve-DSGSearchScopeFriendlyName {
    <#
    .SYNOPSIS
        Resolve the search SearchScope 'Friendly Name' to the appropriate interger.
    .DESCRIPTION
        Resolve the search SearchScope 'Friendly Name' to the appropriate interger, returns 2 if supplied value is unknown/undefined in switch block.
    .PARAMETER SearchScope
        The SourceSearchScope 'Friendly Name'.
    .EXAMPLE
        Resolve-DSGSearchScopeFriendlyName -SearchScope "Subtree"
    .NOTES
        0, 1 and 2 are added to the ValidateSet for function recalling/nested functions.
    #>
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true, HelpMessage = 'The SearchScope friendly name.')]
        [ValidateSet("Base","OneLevel","Subtree","0","1","2")]
        $SearchScope
    )
    Begin {
        if ($script:ThisModuleLoaded -eq $true) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        $Scope = @()
    } Process {
        Try {
            $Scope = Switch ($SearchScope) {
                { ($_ -eq "Base")     -or ($_ -eq 0) } { 0 }
                { ($_ -eq "OneLevel") -or ($_ -eq 1) } { 1 }
                { ($_ -eq "Subtree")  -or ($_ -eq 2) } { 2 }
                default                                { 2 }
            }
        } Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    } End {
        Return $Scope
        Write-Verbose "$($FunctionName): End."
    }
}


## PUBLIC MODULE FUNCTIONS AND DATA ##

Function Update-DSG {
    <#
    .EXTERNALHELP PSDynamicSecurityGroups-help.xml
    .LINK
        https://github.com/GraficomGroup/PSDynamicSecurityGroup/tree/master/release/1.0.1/docs/Functions/Update-DSG.md
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


## Post-Load Module code ##

# Use this variable for any path-sepecific actions (like loading dlls and such) to ensure it will work in testing and after being built
$MyModulePath = $(
    Function Get-ScriptPath {
        $Invocation = (Get-Variable MyInvocation -Scope 1).Value
        if($Invocation.PSScriptRoot) {
            $Invocation.PSScriptRoot
        }
        Elseif($Invocation.MyCommand.Path) {
            Split-Path $Invocation.MyCommand.Path
        }
        elseif ($Invocation.InvocationName.Length -eq 0) {
            (Get-Location).Path
        }
        else {
            $Invocation.InvocationName.Substring(0,$Invocation.InvocationName.LastIndexOf("\"));
        }
    }

    Get-ScriptPath
)

# Load any plugins found in the plugins directory
if (Test-Path (Join-Path $MyModulePath 'plugins')) {
    Get-ChildItem (Join-Path $MyModulePath 'plugins') -Directory | ForEach-Object {
        if (Test-Path (Join-Path $_.FullName "Load.ps1")) {
            Invoke-Command -NoNewScope -ScriptBlock ([Scriptblock]::create(".{$(Get-Content -Path (Join-Path $_.FullName "Load.ps1") -Raw)}")) -ErrorVariable errmsg 2>$null
        }
    }
}

$ExecutionContext.SessionState.Module.OnRemove = {
    # Action to take if the module is removed
    # Unload any plugins found in the plugins directory
    if (Test-Path (Join-Path $MyModulePath 'plugins')) {
        Get-ChildItem (Join-Path $MyModulePath 'plugins') -Directory | ForEach-Object {
            if (Test-Path (Join-Path $_.FullName "UnLoad.ps1")) {
                Invoke-Command -NoNewScope -ScriptBlock ([Scriptblock]::create(".{$(Get-Content -Path (Join-Path $_.FullName "UnLoad.ps1") -Raw)}")) -ErrorVariable errmsg 2>$null
            }
        }
    }
}

$null = Register-EngineEvent -SourceIdentifier ( [System.Management.Automation.PsEngineEvent]::Exiting ) -Action {
    # Action to take if the whole pssession is killed
    # Unload any plugins found in the plugins directory
    if (Test-Path (Join-Path $MyModulePath 'plugins')) {
        Get-ChildItem (Join-Path $MyModulePath 'plugins') -Directory | ForEach-Object {
            if (Test-Path (Join-Path $_.FullName "UnLoad.ps1")) {
                Invoke-Command -NoNewScope -ScriptBlock [Scriptblock]::create(".{$(Get-Content -Path (Join-Path $_.FullName "UnLoad.ps1") -Raw)}") -ErrorVariable errmsg 2>$null
            }
        }
    }
}

# Use this in your scripts to check if the function is being called from your module or independantly.
# Call it immediately to avoid PSScriptAnalyzer 'PSUseDeclaredVarsMoreThanAssignments'
$ThisModuleLoaded = $true
$ThisModuleLoaded

# Non-function exported public module members might go here.
#Export-ModuleMember -Variable SomeVariable -Function  *


