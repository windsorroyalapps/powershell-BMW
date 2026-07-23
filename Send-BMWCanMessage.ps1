function Send-BMWCanMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Target,

        [Parameter(Mandatory)]
        [string]$Data,

        [switch]$WaitForResponse,
        [int]$TimeoutMs = 2000
    )

    if (-not $script:BMWState.Connected) {
        throw "Not connected to OBD2 adapter. Use Connect-BMWObd2 first."
    }

    try {
        $hexData = $Data -replace '\s',''
        $cmd = "ST$Target$hexData"
        $script:BMWState.SerialPort.WriteLine($cmd)

        if ($WaitForResponse) {
            $start = Get-Date
            $response = ""
            while (((Get-Date) - $start).TotalMilliseconds -lt $TimeoutMs) {
                if ($script:BMWState.SerialPort.BytesToRead -gt 0) {
                    $response += $script:BMWState.SerialPort.ReadExisting()
                    if ($response -match '\r\n') { break }
                }
                Start-Sleep -Milliseconds 50
            }
            return $response.Trim()
        }
        return $null
    }
    catch {
        Write-Error "CAN message failed: $_"
        return $null
    }
}
