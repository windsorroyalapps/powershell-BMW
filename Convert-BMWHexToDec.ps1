function Convert-BMWHexToDec {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Hex)
    try {
        return [Convert]::ToInt32($Hex, 16)
    }
    catch {
        return 0
    }
}

function Convert-BMWDecToHex {
    [CmdletBinding()]
    param([Parameter(Mandatory)][int]$Value, [int]$Length = 2)
    return $Value.ToString("X$Length")
}

function Convert-BMWHexToBytes {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Hex)
    $clean = $Hex -replace '\s',''
    $bytes = @()
    for ($i = 0; $i -lt $clean.Length; $i += 2) {
        $bytes += [Convert]::ToByte($clean.Substring($i, 2), 16)
    }
    return $bytes
}
