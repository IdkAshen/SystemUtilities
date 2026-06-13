# Set console appearance
$host.UI.RawUI.BackgroundColor = "Black"
$host.UI.RawUI.ForegroundColor = "White"
$Host.WindowStoreData = $null
Clear-Host

# Check for Administrator Access
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Administrative privileges required." -ForegroundColor Red
    Write-Host "Please re-run this script by right-clicking and selecting 'Run as administrator'."
    Write-Host ""
    Pause
    Exit
}

function Show-Menu {
    Clear-Host
    Write-Host "============================================================="
    Write-Host "               SYSTEM REPAIR AND DIAGNOSTIC TOOL"
    Write-Host "============================================================="
    Write-Host " 1. Restart Windows Explorer (Fixes frozen taskbar/desktop)"
    Write-Host " 2. Rebuild Icon Cache (Fixes blank file icons)"
    Write-Host " 3. Reset Windows Update Services (Fixes stuck downloads)"
    Write-Host " 4. Reset Print Spooler (Fixes stuck print queues)"
    Write-Host " 5. Backup Personal Folders (With dynamic progress bar)"
    Write-Host " 6. Uninstall Non-Essential Consumer Bloatware Apps"
    Write-Host " 7. Check Physical Hard Drive Health Status"
    Write-Host " 8. Exit"
    Write-Host "============================================================="
    Write-Host ""
}

do {
    Show-Menu
    $choice = Read-Host "Enter option number (1-8)"

    switch ($choice) {
        "1" {
            Clear-Host
            Write-Host "Restarting Windows Explorer..."
            Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
            Start-Process "explorer.exe"
            Write-Host "Process restarted.`n"
            Pause
        }
        "2" {
            Clear-Host
            Write-Host "Rebuilding icon and thumbnail cache..."
            Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
            
            $cachePath = "$env:USERPROFILE\AppData\Local\Microsoft\Windows\Explorer"
            Get-ChildItem -Path $cachePath -Filter "iconcache*" -ErrorAction SilentlyContinue | Remove-Item -Force
            Get-ChildItem -Path $cachePath -Filter "thumbcache*" -ErrorAction SilentlyContinue | Remove-Item -Force
            
            Start-Process "explorer.exe"
            Write-Host "Cache cleared and rebuilt.`n"
            Pause
        }
        "3" {
            Clear-Host
            Write-Host "Stopping Windows Update services..."
            Stop-Service -Name "wuauserv", "cryptSvc", "bits", "msiserver" -Force -ErrorAction SilentlyContinue

            Write-Host "Clearing temporary update download folders..."
            if (Test-Path "C:\Windows\SoftwareDistribution") {
                Rename-Item -Path "C:\Windows\SoftwareDistribution" -NewName "SoftwareDistribution.old" -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path "C:\Windows\System32\catroot2") {
                Rename-Item -Path "C:\Windows\System32\catroot2" -NewName "catroot2.old" -Force -ErrorAction SilentlyContinue
            }

            Write-Host "Restarting services..."
            Start-Service -Name "wuauserv", "cryptSvc", "bits", "msiserver" -ErrorAction SilentlyContinue
            Write-Host "Windows Update has been reset.`n"
            Pause
        }
        "4" {
            Clear-Host
            Write-Host "Stopping print spooler..."
            Stop-Service -Name "spooler" -Force -ErrorAction SilentlyContinue
            
            Write-Host "Clearing stuck print jobs..."
            Get-ChildItem -Path "$env:SystemRoot\System32\Spool\Printers\*" -ErrorAction SilentlyContinue | Remove-Item -Force
            
            Write-Host "Restarting print spooler..."
            Start-Service -Name "spooler"
            Write-Host "Print spooler reset complete.`n"
            Pause
        }
        "5" {
            Clear-Host
            Write-Host "============================================================="
            Write-Host "                      FILE BACKUP UTILITY"
            Write-Host "============================================================="
            Write-Host ""
            $targetDrive = Read-Host "Enter the target drive letter for your backup (e.g., E or F)"
            
            if (-not [string]::IsNullOrWhiteSpace($targetDrive)) {
                $targetDrive = $targetDrive.Substring(0,1)
                $folders = @("Desktop", "Documents", "Downloads", "Pictures")
                
                for ($i = 0; $i -lt $folders.Count; $i++) {
                    $folder = $folders[$i]
                    $percent = [int](($i / $folders.Count) * 100)
                    
                    Write-Progress -Activity "Backing Up User Files" -Status "Syncing folder: $folder" -PercentComplete $percent
                    
                    $src = "$env:USERPROFILE\$folder"
                    $dest = "$($targetDrive):\Backup\$folder"
                    Robocopy $src $dest /MIR /R:1 /W:1 /NDL /NFL /NJH /NJS
                }
                Write-Progress -Activity "Backing Up User Files" -Completed
                Write-Host "Backup sync complete.`n"
            } else {
                Write-Host "Invalid drive selection.`n"
            }
            Pause
        }
        "6" {
            Clear-Host
            Write-Host "Removing non-essential pre-installed consumer apps..."
            Write-Host "(Note: Essential apps like Microsoft Store are skipped)`n"
            
            $bloatApps = @(
                "*3dbuilder*", "*bingweather*", "*skypeapp*", "*getstarted*", 
                "*feedbackhub*", "*gethelp*", "*mixedreality*", "*oneconnect*", "*xbox*"
            )

            for ($i = 0; $i -lt $bloatApps.Count; $i++) {
                $app = $bloatApps[$i]
                $percent = [int](($i / $bloatApps.Count) * 100)
                
                Write-Progress -Activity "Removing Bloatware" -Status "Uninstalling: $app" -PercentComplete $percent
                Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
            }
            Write-Progress -Activity "Removing Bloatware" -Completed
            Write-Host "Bloatware removal tasks finished.`n"
            Pause
        }
        "7" {
            Clear-Host
            Write-Host "Checking Drive Hardware Health Status..."
            Write-Host "-------------------------------------------------------------"
            Get-StorageReliabilityCounter | Select-Object -Property DeviceId, Temperature, Wear, ReadErrorsTotal, WriteErrorsTotal | Format-Table
            Get-PhysicalDisk | Select-Object -Property DeviceId, FriendlyName, OperationalStatus, HealthStatus | Format-Table
            Write-Host "Storage diagnostics complete.`n"
            Pause
        }
        "8" {
            Clear-Host
            Exit
        }
    }
} while ($choice -ne "8")
