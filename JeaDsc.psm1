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
        if ($expectedItem -Is [Array] -or $actualItem -Is [Array]) {
            if ($result = Compare-ArrayValues -ActualValue $actualItem -ExpectedValue $expectedItem) {
                return $result
            }
        }
        elseif (-not ($actualItem -eq $expectedItem)) {
            return "Value differs for key {$expectedKey}. Expected value: {$expectedItem}, actual value: {$actualItem}"
        }
    }

    foreach($actualKey in $ActualValue.Keys) {
        if (-not($ExpectedValue.Keys -contains $actualKey)){
            return "Actual key: {$actualKey}, but missing in expected"
        }
        $expectedItem = $ExpectedValue[$actualKey]
        $actualItem = $ActualValue[$actualKey]
        if ($expectedItem -Is [Array] -or $actualItem -Is [Array]) {
            if ($result = Compare-ArrayValues -ActualValue $actualItem -ExpectedValue $expectedItem) {
                return $result
            }
        }
        elseif (-not ($actualItem -eq $expectedItem)) {
            return "Value differs for key {$actualKey}. Expected value: {$expectedItem}, actual value: {$actualItem}"
        }
    }
}

function Compare-ArrayValues {
    param (
        $ActualValue,
        $ExpectedValue
    )

    $ActualValue = @($ActualValue)
    $ExpectedGroups = $ExpectedValue | Group-Object | Sort-Object -Property Name
    $ActualGroups = $ActualValue | Group-Object | Sort-Object -Property Name
    for ($i = 0; $i -lt $ExpectedGroups.Length; $i++) {
        if ( ($i -ge $ActualGroups.Length) `
                -or (-not($ActualGroups[$i].Name -eq $ExpectedGroups[$i].Name))) {
            return "Expected: {$ExpectedValue}. Actual: {$ActualValue}. Actual is missing item: $($ExpectedGroups[$i].Name)"
        }
        if (-not($ActualGroups[$i].Count -eq $ExpectedGroups[$i].Count)) {
            return "Expected: {$ExpectedValue}. Actual: {$ActualValue}. Actual has $($ActualGroups[$i].Count) of item '$($ExpectedGroups[$i].Name)', expected $($ExpectedGroups[$i].Count)"
        }
    }
    for ($i = 0; $i -lt $ActualGroups.Length; $i++) {
        # check for items in actual not in expected
        if ( ($i -ge $ExpectedGroups.Length) `
                -or (-not($ExpectedGroups[$i].Name -eq $ActualGroups[$i].Name))) {
            return "Expected: {$ExpectedValue}. Actual: {$ActualValue}. Expected doesn't have item: $($ActualGroups[$i].Name)"
        }
    }
    if ($ActualValue.Length -ne $ExpectedValue.Length) {
        return "Lengths differ. Expected length $($ExpectedValue.Length). Actual length $($ActualValue.Length) ";
    }
    return $null;
}
