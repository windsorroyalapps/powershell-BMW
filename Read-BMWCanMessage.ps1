function Read-BMWCanMessage {
    [CmdletBinding()]
    param(
        [int]$TimeoutMs = 2000
    )

    if (-not $script:BMWState.Connected) {
        throw "Not connected to OBD2 adapter."
    }

    $start = Get-Date
    $buffer = ""
    while (((Get-Date) - $start).TotalMilliseconds -lt $TimeoutMs) {
        if ($script:BMWState.SerialPort.BytesToRead -gt 0) {
            $buffer += $script:BMWState.SerialPort.ReadExisting()
            if ($buffer -match '\r\n') { break }
        }
        Start-Sleep -Milliseconds 50
    }
    return $buffer.Trim()
}
