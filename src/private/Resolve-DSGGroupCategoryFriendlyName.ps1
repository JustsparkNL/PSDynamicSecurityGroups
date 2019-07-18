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