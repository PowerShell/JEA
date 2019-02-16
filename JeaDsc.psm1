## Convert a string representing a Hashtable into a Hashtable
Function Convert-StringToHashtable($hashtableAsString)
{
    if ($hashtableAsString -eq $null)
    {
        $hashtableAsString = '@{}'
    }
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($hashtableAsString, [ref] $null, [ref] $null)
    $data = $ast.Find( { $args[0] -is [System.Management.Automation.Language.HashtableAst] }, $false )

    return [Hashtable] $data.SafeGetValue()
}

## Convert a string representing an array of Hashtables
Function Convert-StringToArrayOfHashtable($literalString)
{
    $items = @()

    if ($literalString -eq $null)
    {
        return $items
    }

    # match single hashtable or array of hashtables
    $predicate = {
        param($ast)

        if ($ast -is [System.Management.Automation.Language.HashtableAst])
        {
            return ($ast.Parent -is [System.Management.Automation.Language.ArrayLiteralAst]) -or `
                   ($ast.Parent -is [System.Management.Automation.Language.CommandExpressionAst])
        }

        return $false
    }

    $rootAst = [System.Management.Automation.Language.Parser]::ParseInput($literalString, [ref] $null, [ref] $null)
    $data = $rootAst.FindAll($predicate, $false)

    foreach ($datum in $data)
    {
        $items += $datum.SafeGetValue()
    }

    return $items
}

## Convert a string representing an array of strings or Hashtables into an array of objects
Function Convert-StringToArrayOfObject($literalString)
{
    $items = @()

    if ($literalString -eq $null)
    {
        return $items
    }

    # match:
    # 1. single string
    # 2. single hashtable
    # 3. array of strings and/or hashtables
    $predicate = {
        param($ast)

        if ($ast -is [System.Management.Automation.Language.HashtableAst])
        {
            # single hashtable or array item as hashtable
            return ($ast.Parent -is [System.Management.Automation.Language.ArrayLiteralAst]) -or `
                   ($ast.Parent -is [System.Management.Automation.Language.CommandExpressionAst])
        }
        elseif ($ast -is [System.Management.Automation.Language.StringConstantExpressionAst])
        {
            # array item as string
            if ($ast.Parent -is [System.Management.Automation.Language.ArrayLiteralAst])
            {
                return $true
            }

            do
            {
                if ($ast.Parent -is [System.Management.Automation.Language.HashtableAst])
                {
                    # string nested within a hashtable
                    return $false
                }

                $ast = $ast.Parent
            }
            while( $ast -ne $null )

            # single string
            return $true
        }

        return $false
    }

    $rootAst = [System.Management.Automation.Language.Parser]::ParseInput($literalString, [ref] $null, [ref] $null)
    $data = $rootAst.FindAll($predicate, $false)

    foreach ($datum in $data)
    {
        $items += $datum.SafeGetValue()
    }

    return $items
}

Function Convert-ObjectToHashtable($object) {
    $Parameters = @{}
    foreach ($Parameter in $object.PSObject.Properties.Where( {$_.Value})) {
        $Parameters.Add($Parameter.Name, $Parameter.Value)
    }

    return $Parameters
}


Function Compare-JeaConfiguration {
    [cmdletbinding()]
    param (
        [parameter(Mandatory)]
        [hashtable]$ReferenceObject,

        [parameter(Mandatory)]
        [hashtable]$DifferenceObject
    )

    $ReferenceObjectordered = [System.Collections.Specialized.OrderedDictionary]@{}
    $ReferenceObject.Keys |
        Sort-Object -Descending |
        ForEach-Object {
        $ReferenceObjectordered.Insert(0, $_, $ReferenceObject["$_"])
    }

    $DifferenceObjectordered = [System.Collections.Specialized.OrderedDictionary]@{}
    $DifferenceObject.Keys |
        Sort-Object -Descending |
        ForEach-Object {
        $DifferenceObjectordered.Insert(0, $_, $DifferenceObject["$_"])
    }

    if ($ReferenceObjectordered.FunctionDefinitions) {
        foreach ($FunctionDefinition in $ReferenceObjectordered.FunctionDefinitions) {
            $FunctionDefinition.ScriptBlock = $FunctionDefinition.ScriptBlock.Ast.ToString().Replace(' ', '')
        }
    }

    if ($DifferenceObjectordered.FunctionDefinitions) {
        foreach ($FunctionDefinition in $DifferenceObjectordered.FunctionDefinitions) {
            $FunctionDefinition.ScriptBlock = $FunctionDefinition.ScriptBlock.Ast.ToString().Replace(' ', '')
        }
    }

    $ReferenceJson = ConvertTo-Json -InputObject $ReferenceObjectordered -Depth 100
    $DifferenceJson = ConvertTo-Json -InputObject $DifferenceObjectordered -Depth 100

    if ($ReferenceJson -ne $DifferenceJson) {
        Write-Verbose "Existing Configuration: $ReferenceJson"
        Write-Verbose "New COnfiguration: $DifferenceJson"

        return $false
    }

}
