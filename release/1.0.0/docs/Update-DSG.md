---
external help file: PSDynamicSecurityGroups-help.xml
Module Name: PSDynamicSecurityGroups
online version:
schema: 2.0.0
---

# Update-DSG

## SYNOPSIS
A PowerShell function that provides an easy way to create and manage Active Directory Dynamic Security Groups.

## SYNTAX

```
Update-DSG [-SearchBase] <Object> [-SearchScope] <Object> [-Server] <Object> [-ADObjectType] <Object>
 [-GroupName] <Object> [-DestOU] <Object> [-GroupCategory] <Object> [-GroupScope] <Object>
 [-GroupDescription] <Object> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
A PowerShell function that provides an easy way to manage Active Directory Dynamic Security Groups.
This function requires the PowerShell Active Directory module from Microsoft.
As you might have already guessed, when running this command it will replace all members of supplied group.
If the supplied group does not yet exsist this function will create the supplied group.

## EXAMPLES

### EXAMPLE 1
```
Update-DSG -SearchBase "OU=SomeOU,DC=ad,DC=SomeDomain,DC=tld" -SearchScope SubTree -Server 'ad.domain.tld' -ADObjectType computer -GroupName 'DynamicSecurityGroup-1' -DestOU "OU=SomeOtherOU,DC=ad,DC=SomeDomain,DC=tld" -GroupCategory Security -GroupScope Global -GroupDescription 'SomeDescription'
```

## PARAMETERS

### -SearchBase
The base OU DistinguishedName of to search for objects.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SearchScope
The Scope of the search for objects.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Server
Which domain controller/FQDN to query for source objects.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ADObjectType
The ADObjectType to search for.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GroupName
The DynamicSecurityGroup name to get members from.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DestOU
The OU the DynamicSecurityGroup exists in.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GroupCategory
The GroupCategory the DynamicSecurityGroup should be created as (If it doesnt exist)

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GroupScope
The GroupScope the DynamicSecurityGroup should be created as (If it doesnt exist)

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GroupDescription
The DynamicSecurityGroup Description

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Skip the confirmation before updating the DynamicSecurityGroup.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Based of https://github.com/davegreen/shadowGroupSync by David Green, http://www.tookitaway.co.uk

## RELATED LINKS
