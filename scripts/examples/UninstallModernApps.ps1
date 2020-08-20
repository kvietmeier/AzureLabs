return
### Uninstall Modern apps
# https://www.askvg.com/guide-how-to-remove-all-built-in-apps-in-windows-10/

Get-AppxPackage -allusers *3dbuilder* | Remove-AppxPackage
Get-AppxPackage -allusers *windowscommunicationsapps* | Remove-AppxPackage
Get-AppxPackage -allusers *solitairecollection* | Remove-AppxPackage
Get-AppxPackage -allusers *bingfinance* | Remove-AppxPackage
Get-AppxPackage -allusers *windowsstore* | Remove-AppxPackage

# To uninstall Messaging and Skype Video apps together:
get-appxpackage -allusers *messaging* | remove-appxpackage
Get-AppxPackage -allusers *Skype* | Remove-AppxPackage
Get-AppxPackage -allusers *Xbox* | Remove-AppxPackage

Get-AppxPackage | Select Name, Skype
Get-AppxPackage


# To uninstall Skype:
get-appxpackage -allusers *skypeapp* | remove-appxpackage

# To uninstall Paid Wi-Fi & Cellular:
get-appxpackage -allusers *oneconnect* | remove-appxpackage

# To uninstall Money:
get-appxpackage -allusers *bingfinance* | remove-appxpackage

# To uninstall Microsoft Wallet:
get-appxpackage -allusers *wallet* | remove-appxpackage


# To uninstall SkypeForBus:
Get-AppxPackage *Skype.for.Business* | Remove-AppxPackage


# To uninstall 3D Builder:
get-appxpackage *3dbuilder* | remove-appxpackage

# To uninstall Alarms & Clock:
get-appxpackage *alarms* | remove-appxpackage

# To uninstall App Connector:
get-appxpackage *appconnector* | remove-appxpackage

# To uninstall App Installer:
get-appxpackage *appinstaller* | remove-appxpackage

# To uninstall Calendar and Mail apps together:
get-appxpackage *communicationsapps* | remove-appxpackage

# To uninstall Calculator:
get-appxpackage *calculator* | remove-appxpackage

# To uninstall Camera:
get-appxpackage *camera* | remove-appxpackage

# To uninstall Feedback Hub:
get-appxpackage *feedback* | remove-appxpackage

# To uninstall Get Office:
get-appxpackage *officehub* | remove-appxpackage

# To uninstall Get Started or Tips:
get-appxpackage *getstarted* | remove-appxpackage

# To uninstall Groove Music:
get-appxpackage *zunemusic* | remove-appxpackage

# To uninstall Groove Music and Movies & TV apps together:
get-appxpackage *zune* | remove-appxpackage

# To uninstall Maps:
get-appxpackage *maps* | remove-appxpackage



# To uninstall Microsoft Solitaire Collection:
get-appxpackage *solitaire* | remove-appxpackage

# To uninstall Microsoft Wi-Fi:
get-appxpackage *connectivitystore* | remove-appxpackage


# To uninstall Money, News, Sports and Weather apps together:
get-appxpackage *bing* | remove-appxpackage

# To uninstall Movies & TV:
get-appxpackage *zunevideo* | remove-appxpackage

# To uninstall News:
get-appxpackage *bingnews* | remove-appxpackage

# To uninstall OneNote:
get-appxpackage *onenote* | remove-appxpackage


# To uninstall Paint 3D:
get-appxpackage *mspaint* | remove-appxpackage

# To uninstall People:
get-appxpackage *people* | remove-appxpackage

# To uninstall Phone:
get-appxpackage *commsphone* | remove-appxpackage

# To uninstall Phone Companion:
get-appxpackage *windowsphone* | remove-appxpackage

# To uninstall Phone and Phone Companion apps together:
get-appxpackage *phone* | remove-appxpackage

# To uninstall Photos:
get-appxpackage *photos* | remove-appxpackage

# To uninstall Sports:
get-appxpackage *bingsports* | remove-appxpackage

# To uninstall Sticky Notes:
get-appxpackage *sticky* | remove-appxpackage

# To uninstall Sway:
get-appxpackage *sway* | remove-appxpackage

# To uninstall View 3D:
get-appxpackage *3d* | remove-appxpackage

# To uninstall Voice Recorder:
get-appxpackage *soundrecorder* | remove-appxpackage

# To uninstall Weather:
get-appxpackage *bingweather* | remove-appxpackage

# To uninstall Windows Holographic:
get-appxpackage *holographic* | remove-appxpackage

# To uninstall Windows Store: (Be very careful!)
get-appxpackage *windowsstore* | remove-appxpackage

# To uninstall Xbox:
get-appxpackage *xbox* | remove-appxpackage
