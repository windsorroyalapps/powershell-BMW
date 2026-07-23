function Connect-BMWObd2 {
    <#
    .SYNOPSIS
        Connect to BMW E60 via USB OBD2 ELM327 adapter.
    .DESCRIPTION
        Initializes serial connection and sets up K-CAN or D-CAN bus mode.
    .PARAMETER Port
        COM port (e.g., COM3, /dev/ttyUSB0).
    .PARAMETER BusMode
        K-CAN or DCAN (default: DCAN for E60).
    .PARAMETER BaudRate
        Serial baud rate (default: 115200).
    .EXAMPLE
        Connect-BMWObd2 -Port COM3 -BusMode DCAN
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Port,

        [ValidateSet('KCAN','DCAN')]
        [string]$BusMode = 'DCAN',

        [int]$BaudRate = 115200
    )

    Write-BMWLog -Level Info -Message "Connecting to BMW E60 on $Port ($BusMode, $BaudRate baud)..."

    try {
        $serial = New-Object System.IO.Ports.SerialPort $Port, $BaudRate
        $serial.ReadTimeout = 2000
        $serial.WriteTimeout = 2000
        $serial.Open()

        # ELM327 initialization sequence
        $initCommands = @('ATZ','ATE0','ATL1','ATH1','ATSTFF')
        foreach ($cmd in $initCommands) {
            $serial.WriteLine($cmd)
            Start-Sleep -Milliseconds 300
        }

        # Set protocol
        if ($BusMode -eq 'DCAN') {
            $serial.WriteLine('ATSP6')  # CAN 11-bit 500kbaud
        } else {
            $serial.WriteLine('ATSP5')  # KWP2000 fast init
        }
        Start-Sleep -Milliseconds 200

        # Verify connection
        $serial.WriteLine('ATI')
        Start-Sleep -Milliseconds 200
        $id = ""
        $start = Get-Date
        while (((Get-Date) - $start).TotalMilliseconds -lt 1000) {
            if ($serial.BytesToRead -gt 0) {
                $id += $serial.ReadExisting()
            }
            Start-Sleep -Milliseconds 50
        }

        if ($id -match 'ELM|STN') {
            $script:BMWState.Connected = $true
            $script:BMWState.Port = $Port
            $script:BMWState.SerialPort = $serial
            $script:BMWState.BusMode = $BusMode
            $script:BMWState.BaudRate = $BaudRate

            Write-BMWLog -Level Success -Message "Connected to adapter: $($id.Trim())"

            # Try to read VIN
            try {
                $vin = Read-BMWVin
                if ($vin) {
                    Write-BMWLog -Level Success -Message "Vehicle VIN: $vin"
                    $script:BMWState.VehicleProfile['VIN'] = $vin
                }
            }
            catch { }

            return [PSCustomObject]@{
                Connected = $true
                Port = $Port
                Adapter = $id.Trim()
                BusMode = $BusMode
                VIN = $script:BMWState.VehicleProfile['VIN']
            }
        }
        else {
            $serial.Close()
            throw "No ELM327 response. Check wiring and ignition."
        }
    }
    catch {
        Write-BMWLog -Level Error -Message "Connection failed: $_"
        throw
    }
}

function Read-BMWVin {
    $response = Send-BMWCanMessage -Target '00' -Data '22F190' -WaitForResponse
    if ($response -match '62F190') {
        $vinHex = $response -replace '.*62F190','' -replace '\s',''
        $vin = ""
        for ($i = 0; $i -lt $vinHex.Length; $i += 2) {
            $vin += [char][Convert]::ToInt32($vinHex.Substring($i, 2), 16)
        }
        return $vin.Trim()
    }
    return $null
}
