rem Turn off Windows 10 taskbar stuff
rem Tray search bar
reg add hkcu\software\microsoft\windows\currentversion\search /v TraySearchVisible /t reg_dword /d 0 /f
reg add hkcu\software\microsoft\windows\currentversion\search /v SearchboxTaskbarMode /t reg_dword /d 0 /f

rem Cortana
reg add hkcu\software\microsoft\windows\currentversion\explorer\advanced /v  showcortanabutton /t reg_dword /d 0 /f

rem Task View button
reg add hkcu\software\microsoft\windows\currentversion\explorer\advanced /v  showtaskviewbutton /t reg_dword /d 0 /f
