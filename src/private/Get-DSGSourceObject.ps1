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
        $SearchScope = $(Resolve-DSGSearchScopeFriendlyName -SearchScope $SearchScope)   
    } Process {
        Try {
            $MultiObj = @()
            $Obj      = $null
            $Bases    = $SearchBase.Split(";")
            Write-Debug "If the searchbase is an array of searchbases, recall the function, concatenate the results and pass back the complete set."
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
                            Write-Error "Invalid ADObjectType specIfied: '$($ADObjectType)'" -ErrorAction Stop
                        }
                    }
                    Write-Debug "`$Obj must be a collection of AD objects with a Name and an ObjectGUID property: '$($Obj)'"
                } Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                    Write-Error "The OU '$SearchBase' does not appear to exist." -ErrorAction Stop
                } Catch {
                    Write-Error $PSItem -ErrorAction Stop
                }
                Return $Obj
            }
        } Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    } End {

    }
}