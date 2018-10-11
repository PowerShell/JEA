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
    foreach ($Parameter in $object.PSObject.Properties.Where({$_.Value})) {
        $Parameters.Add($Parameter.Name,$Parameter.Value)
    }

    return $Parameters
}


function Compare-Hashtable($ActualValue, $ExpectedValue) {
    # Based on FindMisMatchedHashtableValue by Stuart Leeks
    # https://github.com/stuartleeks/PesterMatchHashtable
    foreach($expectedKey in $ExpectedValue.Keys) {
        if (-not($ActualValue.Keys -contains $expectedKey)){
            return "Expected key: {$expectedKey}, but missing in actual"
        }
        $expectedItem = $ExpectedValue[$expectedKey]
        $actualItem = $ActualValue[$expectedKey]
        if (-not ($actualItem -eq $expectedItem)) {
            return "Value differs for key {$expectedKey}. Expected value: {$expectedItem}, actual value: {$actualItem}"
        }
    }

    foreach($actualKey in $ActualValue.Keys) {
        if (-not($ExpectedValue.Keys -contains $actualKey)){
            return "Actual key: {$actualKey}, but missing in expected"
        }
        $expectedItem = $ExpectedValue[$actualKey]
        $actualItem = $ActualValue[$actualKey]
        if (-not ($actualItem -eq $expectedItem)) {
            return "Value differs for key {$actualKey}. Expected value: {$expectedItem}, actual value: {$actualItem}"
        }
    }
}
