# Find-History.ps1
# Outil de recherche interactive dans l'historique PowerShell
# Utilise l'alternate screen buffer pour un affichage plein ecran propre
#
# Utilisation :
#   - Ctrl+R : lance la recherche et injecte la commande directement sur le prompt
#   - fh     : lance la recherche et copie la commande dans le presse-papier

function Invoke-HistorySearch {
    param([int]$MaxCommands = 1000)

    # Importer PSReadLine si necessaire
    if (-not (Get-Module PSReadLine)) {
        Import-Module PSReadLine -ErrorAction SilentlyContinue
    }

    # Obtenir le chemin de l'historique
    try {
        $historyPath = [Microsoft.PowerShell.PSConsoleReadLine]::GetHistorySavePath()
    } catch {
        $historyPath = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
    }

    if (-not (Test-Path $historyPath)) {
        return $null
    }

    $allHistory = Get-Content $historyPath -Tail $MaxCommands -Encoding UTF8 | Where-Object { $_.Trim() }

    if ($allHistory.Count -eq 0) {
        return $null
    }

    $esc = [char]0x1b

    # Basculer vers l'alternate screen buffer
    [Console]::Write("$esc[?1049h")
    # Masquer le curseur
    [Console]::Write("$esc[?25l")

    $searchTerm = ""
    $selectedIndex = 0
    $filtered = $allHistory
    $selected = $null

    try {
        do {
            $width = [Console]::WindowWidth
            $height = [Console]::WindowHeight

            # Filtrer
            if ($searchTerm -eq "") {
                $filtered = $allHistory
            } else {
                try {
                    $filtered = @($allHistory | Where-Object { $_ -match $searchTerm })
                } catch {
                    $filtered = @($allHistory | Where-Object { $_ -like "*$searchTerm*" })
                }
            }

            if ($selectedIndex -ge $filtered.Count) {
                $selectedIndex = [Math]::Max(0, $filtered.Count - 1)
            }

            # Construire le contenu de l'ecran dans un buffer
            $buf = [System.Text.StringBuilder]::new()

            # Repositionner en haut a gauche
            $null = $buf.Append("$esc[H")

            # Ligne 1 : Titre
            $title = " RECHERCHE D'HISTORIQUE POWERSHELL "
            $pad = [Math]::Max(0, $width - $title.Length)
            $leftPad = [Math]::Floor($pad / 2)
            $rightPad = $pad - $leftPad
            $null = $buf.Append("$esc[46;30m$(' ' * $leftPad)$title$(' ' * $rightPad)$esc[0m`n")

            # Ligne 2 : vide
            $null = $buf.Append("$esc[K`n")

            # Ligne 3 : Barre de recherche
            $searchDisplay = "  Recherche : ${searchTerm}_"
            if ($searchDisplay.Length -lt $width) {
                $searchDisplay = $searchDisplay + (' ' * ($width - $searchDisplay.Length))
            }
            $null = $buf.Append("$esc[33m$searchDisplay$esc[0m`n")

            # Ligne 4 : Info resultats
            $infoLine = "  $($filtered.Count) / $($allHistory.Count) commandes"
            if ($infoLine.Length -lt $width) { $infoLine = $infoLine + (' ' * ($width - $infoLine.Length)) }
            $null = $buf.Append("$esc[90m$infoLine$esc[0m`n")

            # Ligne 5 : Separateur
            $sepLen = [Math]::Min($width - 4, 60)
            $sep = "  " + ('-' * $sepLen)
            if ($sep.Length -lt $width) { $sep = $sep + (' ' * ($width - $sep.Length)) }
            $null = $buf.Append("$esc[90m$sep$esc[0m`n")

            # Zone de resultats
            $headerLines = 5
            $footerLines = 2
            $availableLines = $height - $headerLines - $footerLines

            # Fenetre de scroll
            $displayCount = [Math]::Min($filtered.Count, $availableLines)
            $startIdx = 0
            if ($selectedIndex -ge $displayCount) {
                $startIdx = $selectedIndex - $displayCount + 1
            }

            $resultLines = 0
            for ($i = $startIdx; $i -lt ($startIdx + $displayCount) -and $i -lt $filtered.Count; $i++) {
                $cmd = $filtered[$i]
                $maxCmdLen = $width - 6
                if ($cmd.Length -gt $maxCmdLen) { $cmd = $cmd.Substring(0, $maxCmdLen - 3) + "..." }

                if ($i -eq $selectedIndex) {
                    $line = "  > $cmd"
                    if ($line.Length -lt $width) { $line = $line + (' ' * ($width - $line.Length)) }
                    $null = $buf.Append("$esc[30;42m$line$esc[0m`n")
                } else {
                    $line = "    $cmd"
                    if ($line.Length -lt $width) { $line = $line + (' ' * ($width - $line.Length)) }
                    $null = $buf.Append("$esc[37m$line$esc[0m`n")
                }
                $resultLines++
            }

            if ($filtered.Count -eq 0) {
                $noResult = "    (aucun resultat)"
                if ($noResult.Length -lt $width) { $noResult = $noResult + (' ' * ($width - $noResult.Length)) }
                $null = $buf.Append("$esc[90m$noResult$esc[0m`n")
                $resultLines++
            }

            # Remplir les lignes vides restantes
            $emptyLine = ' ' * $width
            for ($i = $resultLines; $i -lt $availableLines; $i++) {
                $null = $buf.Append("$emptyLine`n")
            }

            # Ligne vide avant le footer
            $null = $buf.Append("$esc[K`n")

            # Footer
            $footer = "  [^/v] Naviguer   [Entree] Selectionner   [Echap] Quitter   [PgUp/PgDn] Page   [Suppr] Effacer"
            if ($footer.Length -gt $width) { $footer = $footer.Substring(0, $width) }
            if ($footer.Length -lt $width) { $footer = $footer + (' ' * ($width - $footer.Length)) }
            $null = $buf.Append("$esc[46;30m$footer$esc[0m")

            # Envoyer tout d'un coup
            [Console]::Write($buf.ToString())

            # Lire la touche
            $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

            switch ($key.VirtualKeyCode) {
                38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }
                40 { if ($selectedIndex -lt ($filtered.Count - 1)) { $selectedIndex++ } }
                33 { $selectedIndex = [Math]::Max(0, $selectedIndex - $availableLines) }
                34 { $selectedIndex = [Math]::Min($filtered.Count - 1, $selectedIndex + $availableLines) }
                36 { $selectedIndex = 0 }
                35 { $selectedIndex = [Math]::Max(0, $filtered.Count - 1) }
                13 { # Entree
                    if ($filtered.Count -gt 0) {
                        $selected = $filtered[$selectedIndex]
                    }
                    break
                }
                27 { break } # Echap
                8 { # Backspace
                    if ($searchTerm.Length -gt 0) {
                        $searchTerm = $searchTerm.Substring(0, $searchTerm.Length - 1)
                        $selectedIndex = 0
                    }
                }
                46 { # Delete
                    $searchTerm = ""
                    $selectedIndex = 0
                }
                default {
                    $char = $key.Character
                    if ([int]$char -ge 32 -and [int]$char -le 126) {
                        $searchTerm += [string]$char
                        $selectedIndex = 0
                    }
                }
            }

            # Sortir si Entree ou Echap
            if ($key.VirtualKeyCode -eq 13 -or $key.VirtualKeyCode -eq 27) { break }

        } while ($true)
    }
    finally {
        # Toujours restaurer l'ecran principal
        [Console]::Write("$esc[?25h")   # Re-afficher le curseur
        [Console]::Write("$esc[?1049l") # Revenir au screen buffer principal
    }

    return $selected
}

# Fonction standalone (fh) : copie dans le presse-papier
function Find-History {
    param([int]$MaxCommands = 1000)
    $result = Invoke-HistorySearch -MaxCommands $MaxCommands
    if ($result) {
        Set-Clipboard -Value $result
        Write-Host "Commande copiee : " -ForegroundColor DarkGray -NoNewline
        Write-Host $result -ForegroundColor Green
        Write-Host "(Ctrl+V pour coller)" -ForegroundColor DarkGray
    }
}

# Binding Ctrl+H : injecte directement sur le prompt
if (Get-Module PSReadLine) {
    Set-PSReadLineKeyHandler -Chord 'Ctrl+h' -ScriptBlock {
        $result = Invoke-HistorySearch
        if ($result) {
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($result)
        }
    } -Description "Recherche interactive dans l'historique"
}

Set-Alias -Name fh -Value Find-History -Scope Global -Force
