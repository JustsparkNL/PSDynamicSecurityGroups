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
    }
}
