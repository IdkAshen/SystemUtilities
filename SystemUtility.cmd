@echo off
color 07
title Windows Maintenance and Diagnostic Utility

:: Check for Administrative Privileges
openfiles >nul 2>&1
if '%errorlevel%' NEQ '0' (
    echo Administrative privileges required.
    echo Please right-click this file and choose "Run as administrator".
    echo.
    pause
    exit /b
)

:MENU
cls
echo =============================================================
echo               SYSTEM REPAIR AND DIAGNOSTIC TOOL
echo =============================================================
echo  1. Restart Windows Explorer (Fixes frozen taskbar/desktop)
echo  2. Rebuild Icon Cache (Fixes blank file icons)
echo  3. Reset Windows Update Services (Fixes stuck downloads)
echo  4. Reset Print Spooler (Fixes stuck print queues)
echo  5. Backup Personal Folders (With Robocopy progress tracking)
echo  6. Uninstall Non-Essential Consumer Bloatware Apps
echo  7. Check Physical Hard Drive Health Status
echo  8. Exit
echo =============================================================
echo.
set /p "op=Enter option number (1-8): "

if "%op%"=="1" goto EXPLORER
if "%op%"=="2" goto ICONCACHE
if "%op%"=="3" goto WINUPDATE
if "%op%"=="4" goto PRINTER
if "%op%"=="5" goto BACKUP
if "%op%"=="6" goto DEBLOAT
if "%op%"=="7" goto HEALTHCHECK
if "%op%"=="8" goto EXIT
goto MENU

:EXPLORER
cls
echo Restarting Windows Explorer...
taskkill /f /im explorer.exe
start explorer.exe
echo.
echo Process restarted.
pause
goto MENU

:ICONCACHE
cls
echo Rebuilding icon and thumbnail cache...
taskkill /f /im explorer.exe
cd /d %userprofile%\AppData\Local\Microsoft\Windows
del /f /s /q Explorer\iconcache*
del /f /s /q Explorer\thumbcache*
start explorer.exe
echo.
echo Cache cleared and rebuilt.
pause
goto MENU

:WINUPDATE
cls
echo Stopping Windows Update services...
net stop wuauserv
net stop cryptSvc
net stop bits
net stop msiserver
echo.
echo Clearing temporary update download folders...
if exist C:\Windows\SoftwareDistribution (
    ren C:\Windows\SoftwareDistribution SoftwareDistribution.old
)
if exist C:\Windows\System32\catroot2 (
    ren C:\Windows\System32\catroot2 catroot2.old
)
echo.
echo Restarting services...
net start wuauserv
net start cryptSvc
net start bits
net start msiserver
echo.
echo Windows Update has been reset.
pause
goto MENU

:PRINTER
cls
echo Stopping print spooler...
net stop spooler
echo Clearing stuck print jobs...
del /q /f /s "%systemroot%\System32\Spool\Printers\*.*"
echo Restarting print spooler...
net start spooler
echo.
echo Print spooler reset complete.
pause
goto MENU

:BACKUP
cls
echo =============================================================
echo                      FILE BACKUP UTILITY
echo =============================================================
echo.
echo Enter the target drive letter for your backup.
echo Example: E or F
echo.
set /p "targetdrive=Drive Letter: "
if "%targetdrive%"=="" goto BACKUP

echo.
echo Starting backup sync...
echo [Robocopy will show live files and percentages below]
echo -------------------------------------------------------------
robocopy "%userprofile%\Desktop" "%targetdrive%:\Backup\Desktop" /MIR /R:1 /W:1
robocopy "%userprofile%\Documents" "%targetdrive%:\Backup\Documents" /MIR /R:1 /W:1
robocopy "%userprofile%\Downloads" "%targetdrive%:\Backup\Downloads" /MIR /R:1 /W:1
robocopy "%userprofile%\Pictures" "%targetdrive%:\Backup\Pictures" /MIR /R:1 /W:1
echo.
echo Backup sync complete.
pause
goto MENU

:DEBLOAT
cls
echo Removing non-essential pre-installed consumer apps...
echo (Note: Essential apps like Microsoft Store are skipped)
echo.
powershell -Command "Get-AppxPackage *3dbuilder* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *bingweather* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *skypeapp* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *getstarted* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *feedbackhub* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *gethelp* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *mixedreality* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *oneconnect* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *xbox* | Remove-AppxPackage"
echo.
echo Bloatware removal tasks finished.
pause
goto MENU

:HEALTHCHECK
cls
echo Querying physical storage drives via WMI...
echo [Status 'OK' means the drive hardware is reporting good health]
echo -------------------------------------------------------------
wmic diskdrive get model,status
echo.
echo S.M.A.R.T. health query finished.
pause
goto MENU

:EXIT
exit
