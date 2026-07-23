function Get-BMWEngineData {
    <#
    .SYNOPSIS
        Read engine-specific DME data (like AI Analysis screen).
    .DESCRIPTION
        Retrieves knock, AFR, boost, IAT, and timing data with severity classification.
    .EXAMPLE
        Get-BMWEngineData
    #>
    [CmdletBinding()]
    param()

    $engine = $script:BMWEngines[$script:BMWState.EngineType]
    $live = Get-BMWLiveData -Pids @('RPM','ECT','IAT','MAP','AFR','BOOST','TPS','KNOCK','OIL_TEMP','TIMING_ADV','MAF') -Count 1

    $data = $live.Data
    $analysis = @()

    # Knock analysis
    if ($data.KNOCK.Value -gt 5) {
        $analysis += [PSCustomObject]@{ Parameter = 'Knock'; Value = $data.KNOCK.Value; Severity = 'CRITICAL'; Action = 'Reduce timing immediately' }
    } elseif ($data.KNOCK.Value -gt 2) {
        $analysis += [PSCustomObject]@{ Parameter = 'Knock'; Value = $data.KNOCK.Value; Severity = 'WARNING'; Action = 'Monitor closely' }
    } else {
        $analysis += [PSCustomObject]@{ Parameter = 'Knock'; Value = $data.KNOCK.Value; Severity = 'OK'; Action = 'No action needed' }
    }

    # AFR analysis
    $afr = $data.AFR.Value
    if ($afr -lt 0.85 -or $afr -gt 1.15) {
        $analysis += [PSCustomObject]@{ Parameter = 'AFR'; Value = $afr; Severity = 'CRITICAL'; Action = 'Check fuel system' }
    } elseif ($afr -lt 0.90 -or $afr -gt 1.10) {
        $analysis += [PSCustomObject]@{ Parameter = 'AFR'; Value = $afr; Severity = 'WARNING'; Action = 'Tune fuel map' }
    } else {
        $analysis += [PSCustomObject]@{ Parameter = 'AFR'; Value = $afr; Severity = 'OK'; Action = 'No action needed' }
    }

    # Boost analysis
    $boost = $data.BOOST.Value
    $maxBoost = $engine.MaxBoost
    if ($boost -gt $maxBoost * 1.2) {
        $analysis += [PSCustomObject]@{ Parameter = 'Boost'; Value = $boost; Severity = 'CRITICAL'; Action = 'Reduce boost target' }
    } elseif ($boost -gt $maxBoost) {
        $analysis += [PSCustomObject]@{ Parameter = 'Boost'; Value = $boost; Severity = 'WARNING'; Action = 'Monitor boost control' }
    } else {
        $analysis += [PSCustomObject]@{ Parameter = 'Boost'; Value = $boost; Severity = 'OK'; Action = 'No action needed' }
    }

    # IAT analysis
    $iat = $data.IAT.Value
    if ($iat -gt 60) {
        $analysis += [PSCustomObject]@{ Parameter = 'IAT'; Value = $iat; Severity = 'WARNING'; Action = 'Check intercooler/ducting' }
    } else {
        $analysis += [PSCustomObject]@{ Parameter = 'IAT'; Value = $iat; Severity = 'OK'; Action = 'No action needed' }
    }

    # Oil temp analysis
    $oilTemp = $data.OIL_TEMP.Value
    if ($oilTemp -gt 130) {
        $analysis += [PSCustomObject]@{ Parameter = 'OilTemp'; Value = $oilTemp; Severity = 'CRITICAL'; Action = 'Cool down immediately' }
    } elseif ($oilTemp -gt 120) {
        $analysis += [PSCustomObject]@{ Parameter = 'OilTemp'; Value = $oilTemp; Severity = 'WARNING'; Action = 'Monitor oil cooling' }
    } else {
        $analysis += [PSCustomObject]@{ Parameter = 'OilTemp'; Value = $oilTemp; Severity = 'OK'; Action = 'No action needed' }
    }

    [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Engine = $engine
        LiveData = $data
        Analysis = $analysis
        OverallSeverity = ($analysis | Sort-Object @{Expression={
            switch ($_.Severity) { 'CRITICAL' {3} 'WARNING' {2} 'OK' {1} }
        }} -Descending | Select-Object -First 1).Severity
    }
}
