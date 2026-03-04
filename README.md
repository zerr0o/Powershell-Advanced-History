# Find-History

Recherche interactive plein ecran dans l'historique PowerShell.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![Windows Terminal](https://img.shields.io/badge/Windows%20Terminal-recommand%C3%A9-brightgreen)

## Fonctionnalites

- **Recherche en temps reel** avec support regex dans tout l'historique PSReadLine
- **Affichage plein ecran** via alternate screen buffer (comme `vim`, `less`, `htop`)
- **Navigation clavier** fluide avec fleches, PageUp/PageDown, Home/End
- **Injection directe** sur le prompt via `Ctrl+H` — pas besoin de copier-coller
- **Retour propre** : l'ecran precedent est restaure tel quel apres la recherche

## Installation

### Automatique

```powershell
git clone https://github.com/<votre-user>/Powershell-find-history.git
cd Powershell-find-history
.\Install.ps1
```

Le script d'installation :

1. Copie `Find-History.ps1` dans `~/Documents/PowerShell/Scripts/`
2. Ajoute le chargement automatique dans votre profil PowerShell
3. Disponible a chaque nouvelle session

### Manuelle

Ajoutez cette ligne a votre profil PowerShell (`$PROFILE`) :

```powershell
. "chemin\vers\Find-History.ps1"
```

## Utilisation

| Raccourci | Action |
|-----------|--------|
| `Ctrl+H` | Lance la recherche et **injecte la commande directement sur le prompt** |
| `fh` | Lance la recherche et **copie dans le presse-papier** (Ctrl+V pour coller) |

### Dans l'interface de recherche

| Touche | Action |
|--------|--------|
| Fleches haut/bas | Naviguer dans les resultats |
| PageUp / PageDown | Sauter de 10 en 10 |
| Home / End | Debut / fin de la liste |
| Entree | Selectionner la commande |
| Echap | Quitter sans rien selectionner |
| Suppr | Effacer la recherche |
| Backspace | Supprimer le dernier caractere |

Tapez directement pour filtrer — le filtre supporte les **expressions regulieres**.

## Pourquoi Ctrl+H et pas fh ?

`Ctrl+H` s'execute dans le contexte PSReadLine, ce qui permet d'**injecter** la commande directement sur la ligne de prompt. Vous n'avez qu'a appuyer sur Entree pour l'executer.

`fh` est une commande classique — une fois executee, PowerShell affiche un nouveau prompt vierge. Il est impossible d'ecrire sur ce nouveau prompt depuis la commande precedente, d'ou le fallback presse-papier.

## Compatibilite

- **PowerShell 5.1** (Windows PowerShell) et **PowerShell 7+**
- **Windows Terminal** recommande pour un rendu optimal
- Necessite le module **PSReadLine** (inclus par defaut)
