function Test-BMWConnection {
    [CmdletBinding()]
    param()

    if (-not $script:BMWState.Connected -or -not $script:BMWState.SerialPort -or -not $script:BMWState.SerialPort.IsOpen) {
        return $false
    }

    try {
        $script:BMWState.SerialPort.WriteLine("ATI")
        Start-Sleep -Milliseconds 200
        $response = ""
        $start = Get-Date
        while (((Get-Date) - $start).TotalMilliseconds -lt 1000) {
            if ($script:BMWState.SerialPort.BytesToRead -gt 0) {
                $response += $script:BMWState.SerialPort.ReadExisting()
                if ($response -match 'ELM|OK') { return $true }
            }
            Start-Sleep -Milliseconds 50
        }
        return $false
    }
    catch {
        return $false
    }
}
