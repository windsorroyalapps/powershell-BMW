function Write-BMWLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Info','Warning','Error','Success','Ai')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message
    )

    $colorMap = @{
        'Info' = 'White'
        'Warning' = 'Yellow'
        'Error' = 'Red'
        'Success' = 'Green'
        'Ai' = 'Magenta'
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $prefix = switch ($Level) {
        'Info'    { '[INFO]  ' }
        'Warning' { '[WARN]  ' }
        'Error'   { '[ERROR] ' }
        'Success' { '[OK]    ' }
        'Ai'      { '[AI]    ' }
    }

    Write-Host "$timestamp $prefix$Message" -ForegroundColor $colorMap[$Level]

    if ($script:BMWState.DataLogActive) {
        $script:BMWState.DataLogBuffer.Add([PSCustomObject]@{
            Timestamp = $timestamp
            Level = $Level
            Message = $Message
        }) | Out-Null
    }
}
