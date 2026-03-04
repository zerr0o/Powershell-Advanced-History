# Install.ps1
# Installe Find-History dans le profil PowerShell

$scriptName = "Find-History.ps1"
$scriptSource = Join-Path $PSScriptRoot "PowerShell\$scriptName"

if (-not (Test-Path $scriptSource)) {
    Write-Host "Erreur : $scriptSource introuvable." -ForegroundColor Red
    Write-Host "Lancez ce script depuis la racine du depot." -ForegroundColor Red
    exit 1
}

# Dossier d'installation
$installDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) "PowerShell\Scripts"
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# Copier le script
$installPath = Join-Path $installDir $scriptName
Copy-Item -Path $scriptSource -Destination $installPath -Force
Write-Host "Script copie dans : $installPath" -ForegroundColor Green

# Ajouter au profil PowerShell
$profilePath = $PROFILE.CurrentUserCurrentHost

if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
    Write-Host "Profil PowerShell cree : $profilePath" -ForegroundColor Yellow
}

$sourceLine = ". `"$installPath`""

$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
if ($profileContent -and $profileContent.Contains($sourceLine)) {
    Write-Host "Deja present dans le profil. Rien a ajouter." -ForegroundColor DarkGray
} else {
    Add-Content -Path $profilePath -Value "`n# Find-History : recherche interactive dans l'historique (Ctrl+H)`n$sourceLine"
    Write-Host "Ligne ajoutee au profil : $profilePath" -ForegroundColor Green
}

Write-Host ""
Write-Host "Installation terminee !" -ForegroundColor Cyan
Write-Host "Redemarrez PowerShell ou tapez :" -ForegroundColor Gray
Write-Host "  . `"$installPath`"" -ForegroundColor White
Write-Host ""
Write-Host "Utilisation :" -ForegroundColor Cyan
Write-Host "  Ctrl+H  -  Recherche interactive (injection directe sur le prompt)" -ForegroundColor White
Write-Host "  fh      -  Recherche interactive (copie dans le presse-papier)" -ForegroundColor White
