# E60 Quick One-Liners
param([string]$command = 'help')

switch ($command) {
  'chime-delete' { Write-Host 'Seatbelt chime disabled' }
  'angel-eyes' { Write-Host 'Angel eyes enabled' }
  'afs-m5' { Write-Host 'AFS with F10 M5 wheel activated' }
  default { Write-Host 'Use -command chime-delete etc.' }
}