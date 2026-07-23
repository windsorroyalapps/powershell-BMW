function Disconnect-BMWObd2 {
    <#
    .SYNOPSIS
        Safely disconnect from OBD2 adapter.
    #>
    [CmdletBinding()]
    param()

    if ($script:BMWState.SerialPort -and $script:BMWState.SerialPort.IsOpen) {
        try {
            $script:BMWState.SerialPort.WriteLine('ATPC')
            Start-Sleep -Milliseconds 200
            $script:BMWState.SerialPort.Close()
        }
        catch { }
    }

    $script:BMWState.Connected = $false
    $script:BMWState.SerialPort = $null
    $script:BMWState.Port = $null

    Write-BMWLog -Level Info -Message "Disconnected from OBD2 adapter."
}
