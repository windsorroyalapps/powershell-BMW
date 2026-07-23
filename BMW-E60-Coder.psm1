#Requires -Version 5.1
<#
.SYNOPSIS
    BMW E60 Coder Pro - PowerShell Edition
    Complete port of the Android app features to PowerShell for Termux/Desktop use.
#>

# --- Module State ---
$script:BMWState = [hashtable]::Synchronized(@{
    Connected = $false
    Port = $null
    SerialPort = $null
    BusMode = 'DCAN'
    BaudRate = 115200
    VehicleProfile = @{}
    CurrentMap = 'Stock'
    DataLogActive = $false
    DataLogBuffer = [System.Collections.ArrayList]::new()
    AiAnalysisActive = $false
    ControllerDriveActive = $false
    EngineType = 'N54'
    InjectorType = 'Bosch'
    LastFaultCodes = @()
    GaugeLayout = 'Circular'
})

# --- Load Private Functions ---
$PrivatePath = Join-Path $PSScriptRoot 'Private'
if (Test-Path $PrivatePath) {
    Get-ChildItem -Path $PrivatePath -Filter '*.ps1' | ForEach-Object {
        . $_.FullName
    }
}

# --- Load Public Functions ---
$PublicPath = Join-Path $PSScriptRoot 'Public'
if (Test-Path $PublicPath) {
    Get-ChildItem -Path $PublicPath -Filter '*.ps1' | ForEach-Object {
        . $_.FullName
    }
}

# --- Constants ---
$script:BMWEngines = @{
    N54 = @{ Name = 'N54'; Type = 'Twin-Turbo'; Cylinders = 6; Displacement = 3.0; Fuel = 'Petrol'; MaxBoost = 18.0; StockHP = 306 }
    N52 = @{ Name = 'N52'; Type = 'NA'; Cylinders = 6; Displacement = 3.0; Fuel = 'Petrol'; MaxBoost = 0.0; StockHP = 258 }
    M54 = @{ Name = 'M54'; Type = 'NA'; Cylinders = 6; Displacement = 3.0; Fuel = 'Petrol'; MaxBoost = 0.0; StockHP = 231 }
    M57 = @{ Name = 'M57'; Type = 'Turbo-Diesel'; Cylinders = 6; Displacement = 3.0; Fuel = 'Diesel'; MaxBoost = 22.0; StockHP = 218 }
}

$script:BMWMaps = @(
    @{ Name = 'Stock'; Description = 'Factory calibration'; TimingOffset = 0; BoostOffset = 0; ThrottleOffset = 0; FuelOffset = 0 }
    @{ Name = 'Stage1'; Description = 'Mild increase (+40hp)'; TimingOffset = 2; BoostOffset = 3; ThrottleOffset = 5; FuelOffset = 8 }
    @{ Name = 'Stage2'; Description = 'Moderate increase (+70hp)'; TimingOffset = 4; BoostOffset = 6; ThrottleOffset = 10; FuelOffset = 15 }
    @{ Name = 'Stage3'; Description = 'Maximum safe increase (+100hp)'; TimingOffset = 6; BoostOffset = 9; ThrottleOffset = 15; FuelOffset = 22 }
    @{ Name = 'Economy'; Description = 'Fuel efficiency focus'; TimingOffset = -1; BoostOffset = -2; ThrottleOffset = -5; FuelOffset = -10 }
    @{ Name = 'Valet'; Description = 'Restricted power mode'; TimingOffset = -4; BoostOffset = -5; ThrottleOffset = -20; FuelOffset = -15 }
    @{ Name = 'Custom'; Description = 'User-defined parameters'; TimingOffset = 0; BoostOffset = 0; ThrottleOffset = 0; FuelOffset = 0 }
    @{ Name = 'AntiTheft'; Description = 'Engine immobilizer'; TimingOffset = -10; BoostOffset = -10; ThrottleOffset = -50; FuelOffset = -50 }
    @{ Name = 'Track'; Description = 'Track-optimized aggressive map'; TimingOffset = 5; BoostOffset = 8; ThrottleOffset = 12; FuelOffset = 18 }
)

$script:BMWInjectors = @{
    'Bosch_550cc' = @{ Brand = 'Bosch'; Flow = 550; Impedance = 'High'; Type = 'EV1' }
    'Bosch_630cc' = @{ Brand = 'Bosch'; Flow = 630; Impedance = 'High'; Type = 'EV1' }
    'Bosch_1000cc' = @{ Brand = 'Bosch'; Flow = 1000; Impedance = 'High'; Type = 'EV1' }
    'EV14_550cc' = @{ Brand = 'EV14'; Flow = 550; Impedance = 'High'; Type = 'EV14' }
    'EV14_650cc' = @{ Brand = 'EV14'; Flow = 650; Impedance = 'High'; Type = 'EV14' }
    'EV14_850cc' = @{ Brand = 'EV14'; Flow = 850; Impedance = 'High'; Type = 'EV14' }
    'EV14_1000cc' = @{ Brand = 'EV14'; Flow = 1000; Impedance = 'High'; Type = 'EV14' }
    'EV14_1300cc' = @{ Brand = 'EV14'; Flow = 1300; Impedance = 'High'; Type = 'EV14' }
    'ID_725cc' = @{ Brand = 'Injector Dynamics'; Flow = 725; Impedance = 'High'; Type = 'ID' }
    'ID_1000cc' = @{ Brand = 'Injector Dynamics'; Flow = 1000; Impedance = 'High'; Type = 'ID' }
    'ID_1050cc' = @{ Brand = 'Injector Dynamics'; Flow = 1050; Impedance = 'High'; Type = 'ID' }
    'ID_1300cc' = @{ Brand = 'Injector Dynamics'; Flow = 1300; Impedance = 'High'; Type = 'ID' }
    'ID_1700cc' = @{ Brand = 'Injector Dynamics'; Flow = 1700; Impedance = 'High'; Type = 'ID' }
    'ID_2000cc' = @{ Brand = 'Injector Dynamics'; Flow = 2000; Impedance = 'High'; Type = 'ID' }
    'Siemens_Deka_630cc' = @{ Brand = 'Siemens Deka'; Flow = 630; Impedance = 'Low'; Type = 'Deka' }
    'Siemens_Deka_875cc' = @{ Brand = 'Siemens Deka'; Flow = 875; Impedance = 'Low'; Type = 'Deka' }
    'Siemens_Deka_1000cc' = @{ Brand = 'Siemens Deka'; Flow = 1000; Impedance = 'Low'; Type = 'Deka' }
    'Siemens_Deka_1200cc' = @{ Brand = 'Siemens Deka'; Flow = 1200; Impedance = 'Low'; Type = 'Deka' }
}

$script:BMWVoOptions = @{
    '2VB' = @{ Name = 'Adaptive Front Lighting (AFS)'; Description = 'Adaptive headlights with cornering function'; Module = 'LM2_E6X' }
    '2VC' = @{ Name = 'LED Daytime Running Lights'; Description = 'LED DRL instead of halogen'; Module = 'LM2_E6X' }
    '2VA' = @{ Name = 'Bi-Xenon Headlights'; Description = 'Xenon headlights with adaptive range'; Module = 'LM2_E6X' }
    '403' = @{ Name = 'Sunroof'; Description = 'Electric glass sunroof'; Module = 'KGM' }
    '417' = @{ Name = 'Rear Sunblind'; Description = 'Electric rear window roller blind'; Module = 'KGM' }
    '431' = @{ Name = 'Interior Mirror Auto-Dim'; Description = 'Auto-dimming interior mirror'; Module = 'KGM' }
    '459' = @{ Name = 'Seat Adjustment Memory'; Description = 'Driver seat memory function'; Module = 'SMFA' }
    '488' = @{ Name = 'Lumbar Support Driver'; Description = 'Driver seat lumbar support'; Module = 'SMFA' }
    '494' = @{ Name = 'Seat Heating Driver/Passenger'; Description = 'Front seat heating'; Module = 'IHKA_E60' }
    '508' = @{ Name = 'Park Distance Control (PDC)'; Description = 'Front and rear parking sensors'; Module = 'PDC' }
    '521' = @{ Name = 'Rain Sensor'; Description = 'Automatic wiper control'; Module = 'KGM' }
    '522' = @{ Name = 'Xenon Lights'; Description = 'Xenon headlight system'; Module = 'LM2_E6X' }
    '524' = @{ Name = 'Adaptive Headlights'; Description = 'Dynamic headlight range adjustment'; Module = 'LM2_E6X' }
    '534' = @{ Name = 'Automatic Air Conditioning'; Description = 'Climate control with auto mode'; Module = 'IHKA_E60' }
    '540' = @{ Name = 'Cruise Control'; Description = 'Speed control system'; Module = 'KGM' }
    '563' = @{ Name = 'Lights Package'; Description = 'Interior ambient lighting'; Module = 'LM2_E6X' }
    '609' = @{ Name = 'Navigation System Professional'; Description = 'Professional navigation with HDD'; Module = 'CIC' }
    '620' = @{ Name = 'Voice Control'; Description = 'Voice command system'; Module = 'CIC' }
    '639' = @{ Name = 'BMW Assist'; Description = 'Telematics and emergency call'; Module = 'TCU' }
    '644' = @{ Name = 'Bluetooth Phone Prep'; Description = 'Bluetooth hands-free system'; Module = 'MULF' }
    '676' = @{ Name = 'HiFi Speaker System'; Description = 'Premium audio system'; Module = 'AMP' }
    '677' = @{ Name = 'Harman Kardon Logic7'; Description = 'Logic7 surround sound'; Module = 'AMP' }
    '697' = @{ Name = 'USB Audio Interface'; Description = 'USB port for media playback'; Module = 'CIC' }
    '6AA' = @{ Name = 'BMW TeleServices'; Description = 'Remote vehicle diagnostics'; Module = 'TCU' }
    '6AB' = @{ Name = 'BMW Online'; Description = 'Internet connectivity'; Module = 'TCU' }
    '6FL' = @{ Name = 'USB/Smartphone Integration'; Description = 'USB and iPod connectivity'; Module = 'CIC' }
    '6NF' = @{ Name = 'Smartphone Integration Extended'; Description = 'Extended smartphone features'; Module = 'CIC' }
    '6NR' = @{ Name = 'BMW Apps'; Description = 'Third-party app integration'; Module = 'CIC' }
    '6UH' = @{ Name = 'Traffic Information'; Description = 'Real-time traffic data'; Module = 'CIC' }
    '6VC' = @{ Name = 'ConnectedDrive Services'; Description = 'Connected services package'; Module = 'TCU' }
}

Write-Host "BMW E60 Coder Pro v2.0.0 loaded. Use Get-Command -Module BMW-E60-Coder to see available commands." -ForegroundColor Cyan
