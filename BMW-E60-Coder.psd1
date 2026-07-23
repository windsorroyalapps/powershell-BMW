@{
    RootModule = 'BMW-E60-Coder.psm1'
    ModuleVersion = '2.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'windsorroyalapps'
    CompanyName = 'Windsor Royal Apps'
    Copyright = '(c) 2026 Windsor Royal Apps. MIT License.'
    Description = 'Complete BMW E60 tuning, diagnostics, and controller drive platform for PowerShell. Ports all features from BMW E60 Coder Pro Android app.'
    PowerShellVersion = '5.1'
    RequiredModules = @()
    FunctionsToExport = @(
        'Connect-BMWObd2',
        'Disconnect-BMWObd2',
        'Get-BMWLiveData',
        'Get-BMWEngineData',
        'Get-BMWFaultCodes',
        'Clear-BMWFaultCodes',
        'Set-BMWMap',
        'Get-BMWMap',
        'Get-BMWAvailableMaps',
        'Invoke-BMWDmeFlash',
        'Test-BMWDmeFlashSafety',
        'Start-BMWAiAnalysis',
        'Stop-BMWAiAnalysis',
        'Get-BMWInjectorSize',
        'Set-BMWVoOption',
        'Get-BMWVoOptions',
        'Start-BMWDataLog',
        'Stop-BMWDataLog',
        'Get-BMWDataLog',
        'Export-BMWDataLog',
        'Set-BMWControllerDrive',
        'Get-BMWControllerDriveStatus',
        'Invoke-BMWNfcPayment',
        'Set-BMWVehicleProfile',
        'Get-BMWVehicleProfile',
        'Get-BMWSupportedEngines',
        'Get-BMWSupportedInjectors',
        'Backup-BMWCoding',
        'Restore-BMWCoding',
        'Get-BMWModuleInfo',
        'Set-BMWTimingTable',
        'Set-BMWBoostTable',
        'Set-BMWThrottleTable',
        'Get-BMWGaugeLayout',
        'Set-BMWGaugeLayout'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('BMW','E60','OBD2','Tuning','Automotive','CAN-Bus')
            LicenseUri = 'https://github.com/windsorroyalapps/powershell-BMW/blob/main/LICENSE'
            ProjectUri = 'https://github.com/windsorroyalapps/powershell-BMW'
            ReleaseNotes = 'v2.0.0 - Full port of BMW E60 Coder Pro Android app features to PowerShell'
        }
    }
}
