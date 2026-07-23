function Get-BMWFaultCodes {
    <#
    .SYNOPSIS
        Read DTCs from all BMW modules.
    .PARAMETER Module
        Specific module or 'All'.
    .EXAMPLE
        Get-BMWFaultCodes -Module All
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('All','DME','EGS','DSC','CAS3','LM_E60','LM2_E6X','KMBI_E60','IHKA_E60','CIC','PDC','KGM','HKL','HUD')]
        [string]$Module = 'All'
    )

    $moduleMap = @{
        'DME' = @{ Address = '01'; Name = 'Digital Motor Electronics' }
        'EGS' = @{ Address = '03'; Name = 'Electronic Transmission' }
        'DSC' = @{ Address = '29'; Name = 'Dynamic Stability Control' }
        'CAS3'= @{ Address = '00'; Name = 'Car Access System' }
        'LM_E60' = @{ Address = '21'; Name = 'Light Module' }
        'LM2_E6X' = @{ Address = '21'; Name = 'Light Module 2' }
        'KMBI_E60' = @{ Address = '60'; Name = 'Instrument Cluster' }
        'IHKA_E60' = @{ Address = '5B'; Name = 'Climate Control' }
        'CIC' = @{ Address = '63'; Name = 'Headunit CIC' }
        'PDC' = @{ Address = '66'; Name = 'Park Distance Control' }
        'KGM' = @{ Address = '15'; Name = 'Body Gateway' }
        'HKL' = @{ Address = '6A'; Name = 'Tailgate Module' }
        'HUD' = @{ Address = '68'; Name = 'Head-Up Display' }
    }

    $targets = if ($Module -eq 'All') { $moduleMap.Keys } else { @($Module) }
    $allCodes = @()

    foreach ($mod in $targets) {
        $info = $moduleMap[$mod]
        Write-BMWLog -Level Info -Message "Reading fault codes from $($info.Name)..."

        try {
            $response = Send-BMWCanMessage -Target $info.Address -Data '03' -WaitForResponse -TimeoutMs 1500

            if ($response -match '43') {
                $hexData = ($response -replace '.*43','') -replace '\s',''
                $codes = @()

                for ($i = 0; $i -lt $hexData.Length; $i += 4) {
                    if ($i + 4 -le $hexData.Length) {
                        $codeHex = $hexData.Substring($i, 4)
                        $prefix = switch ($codeHex[0]) {
                            '0' { 'P0' } '1' { 'P1' } '2' { 'P2' } '3' { 'P3' }
                            '4' { 'C0' } '5' { 'C1' } '6' { 'C2' } '7' { 'C3' }
                            '8' { 'B0' } '9' { 'B1' } 'A' { 'B2' } 'B' { 'B3' }
                            'C' { 'U0' } 'D' { 'U1' } 'E' { 'U2' } 'F' { 'U3' }
                        }
                        $codeNum = $codeHex.Substring(1, 3)
                        $codes += "$prefix$codeNum"
                    }
                }

                foreach ($code in $codes) {
                    $allCodes += [PSCustomObject]@{
                        Module = $mod
                        ModuleName = $info.Name
                        Code = $code
                        Description = Get-BMWFaultDescription -Code $code
                        Status = 'Active'
                    }
                }
            }
        }
        catch {
            Write-BMWLog -Level Warning -Message "Failed to read $mod : $_"
        }
    }

    $script:BMWState.LastFaultCodes = $allCodes
    return $allCodes
}

function Get-BMWFaultDescription {
    param([string]$Code)
    $descriptions = @{
        'P0171' = 'System too lean (Bank 1)'
        'P0174' = 'System too lean (Bank 2)'
        'P0299' = 'Turbo underboost condition'
        'P0300' = 'Random/multiple cylinder misfire'
        'P0420' = 'Catalyst efficiency below threshold'
        'P0442' = 'EVAP small leak detected'
        'P0500' = 'Vehicle speed sensor malfunction'
        'P0562' = 'System voltage low'
        'P0600' = 'Serial communication link'
        'P0700' = 'Transmission control system'
        'P112F' = 'Manifold absolute pressure sensor'
        'P15E0' = 'Charge air pressure control'
        'P30FF' = 'Turbo boost pressure too low'
        'P31CF' = 'Charge air system leak'
        'P3A1A' = 'DME internal error'
    }
    return $descriptions[$Code] ?? 'Unknown fault - consult BMW documentation'
}

function Clear-BMWFaultCodes {
    <#
    .SYNOPSIS
        Clear DTCs from specified module(s).
    .PARAMETER Module
        Module to clear, or 'All'.
    .EXAMPLE
        Clear-BMWFaultCodes -Module DME
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateSet('All','DME','EGS','DSC','CAS3','LM_E60','LM2_E6X','KMBI_E60','IHKA_E60','CIC','PDC','KGM','HKL','HUD')]
        [string]$Module = 'All'
    )

    $moduleMap = @{
        'DME' = '01'; 'EGS' = '03'; 'DSC' = '29'; 'CAS3' = '00'
        'LM_E60' = '21'; 'LM2_E6X' = '21'; 'KMBI_E60' = '60'
        'IHKA_E60' = '5B'; 'CIC' = '63'; 'PDC' = '66'
        'KGM' = '15'; 'HKL' = '6A'; 'HUD' = '68'
    }

    $targets = if ($Module -eq 'All') { $moduleMap.Keys } else { @($Module) }

    foreach ($mod in $targets) {
        $addr = $moduleMap[$mod]
        if ($PSCmdlet.ShouldProcess("$mod (0x$addr)", "Clear fault codes")) {
            try {
                Send-BMWCanMessage -Target $addr -Data '04' -WaitForResponse -TimeoutMs 1000 | Out-Null
                Write-BMWLog -Level Success -Message "Cleared fault codes from $mod"
            }
            catch {
                Write-BMWLog -Level Error -Message "Failed to clear $mod : $_"
            }
        }
    }
}
