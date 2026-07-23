function Get-BMWLiveData {
    <#
    .SYNOPSIS
        Read live OBD2 data from BMW E60 (like Gauges screen).
    .PARAMETER Pids
        Specific PIDs to read. Defaults to common E60 parameters.
    .PARAMETER RefreshRate
        Milliseconds between readings.
    .PARAMETER Count
        Number of readings (0 = infinite).
    .EXAMPLE
        Get-BMWLiveData -RefreshRate 500 -Count 10
    #>
    [CmdletBinding()]
    param(
        [string[]]$Pids = @('RPM','ECT','IAT','MAP','AFR','BOOST','TPS','KNOCK','OIL_TEMP','BAT_VOLTAGE'),
        [int]$RefreshRate = 500,
        [int]$Count = 1
    )

    $pidMap = @{
        'RPM'        = @{ Mode = '01'; PID = '0C'; Formula = { param($a,$b) ($a * 256 + $b) / 4 }; Unit = 'rpm' }
        'ECT'        = @{ Mode = '01'; PID = '05'; Formula = { param($a) $a - 40 }; Unit = '°C' }
        'IAT'        = @{ Mode = '01'; PID = '0F'; Formula = { param($a) $a - 40 }; Unit = '°C' }
        'MAP'        = @{ Mode = '01'; PID = '0B'; Formula = { param($a) $a }; Unit = 'kPa' }
        'AFR'        = @{ Mode = '01'; PID = '24'; Formula = { param($a,$b) (2 / 65536) * ($a * 256 + $b) }; Unit = 'lambda' }
        'BOOST'      = @{ Mode = '01'; PID = '70'; Formula = { param($a,$b) (($a * 256 + $b) - 32768) / 128 }; Unit = 'psi' }
        'TPS'        = @{ Mode = '01'; PID = '11'; Formula = { param($a) ($a * 100) / 255 }; Unit = '%' }
        'KNOCK'      = @{ Mode = '01'; PID = '3D'; Formula = { param($a) $a }; Unit = 'count' }
        'OIL_TEMP'   = @{ Mode = '01'; PID = '5C'; Formula = { param($a) $a - 40 }; Unit = '°C' }
        'BAT_VOLTAGE'= @{ Mode = '01'; PID = '42'; Formula = { param($a,$b) ($a * 256 + $b) / 1000 }; Unit = 'V' }
        'SPEED'      = @{ Mode = '01'; PID = '0D'; Formula = { param($a) $a }; Unit = 'km/h' }
        'LOAD'       = @{ Mode = '01'; PID = '04'; Formula = { param($a) ($a * 100) / 255 }; Unit = '%' }
        'TIMING_ADV' = @{ Mode = '01'; PID = '0E'; Formula = { param($a) ($a / 2) - 64 }; Unit = '°' }
        'MAF'        = @{ Mode = '01'; PID = '10'; Formula = { param($a,$b) ($a * 256 + $b) / 100 }; Unit = 'g/s' }
    }

    $counter = 0
    while ($Count -eq 0 -or $counter -lt $Count) {
        $counter++
        $results = @{}
        $timestamp = Get-Date -Format 'HH:mm:ss.fff'

        foreach ($pidName in $Pids) {
            if (-not $pidMap.ContainsKey($pidName)) { continue }
            $pid = $pidMap[$pidName]

            try {
                $cmd = "$($pid.Mode)$($pid.PID)"
                $response = Send-BMWCanMessage -Target '01' -Data $cmd -WaitForResponse -TimeoutMs 500

                if ($response -match "$($pid.Mode)$($pid.PID)") {
                    $hexData = ($response -split '\s+' | Select-Object -Skip 2) -join ''
                    $bytes = Convert-BMWHexToBytes -Hex $hexData

                    $value = if ($bytes.Count -ge 2) {
                        & $pid.Formula $bytes[0] $bytes[1]
                    } else {
                        & $pid.Formula $bytes[0]
                    }

                    $results[$pidName] = [PSCustomObject]@{
                        Name = $pidName
                        Value = [math]::Round($value, 2)
                        Unit = $pid.Unit
                        Raw = $hexData
                    }
                }
            }
            catch {
                $results[$pidName] = [PSCustomObject]@{
                    Name = $pidName
                    Value = $null
                    Unit = $pidMap[$pidName].Unit
                    Raw = 'ERROR'
                }
            }
        }

        [PSCustomObject]@{
            Timestamp = $timestamp
            Data = $results
            Engine = $script:BMWState.EngineType
            Map = $script:BMWState.CurrentMap
        }

        if ($Count -ne 1 -and ($Count -eq 0 -or $counter -lt $Count)) {
            Start-Sleep -Milliseconds $RefreshRate
        }
    }
}
