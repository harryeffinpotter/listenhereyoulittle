# ListenHereYouLittle

A PowerShell toolkit to enforce and maintain your preferred audio devices on Windows.

## Contents

* **init.ps1**: Installer and configuration script.
* **fix.ps1**: One-shot fixer to apply your preferences immediately.
* **watch.ps1**: Background watcher that re-applies preferences every 30 seconds.
* **kill-watch.ps1**: Stops and unregisters the background watcher.
* **run-init.bat**: Self-elevating batch wrapper to install and launch `init.ps1`.

## Installation

Run the installer directly via PowerShell:

```powershell
iex (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/harryeffinpotter/listenhereyoulittle/master/install.bat')
```

This will:

1. Elevate to administrator (if needed)
2. Install and configure via `init.ps1`
3. Create Start Menu shortcuts and scheduled tasks

## Usage

All shortcuts are placed in your Start Menu under **ListenHereYouLittle**:

* **Fix Audio**: Enforce your settings immediately.
* **Watch Audio**: Run the watcher manually (invisible) to auto-fix every 30s.
* **Kill Watcher**: Stop and unregister the watcher.

## Configuration

During installation you will be prompted for:

* Preferred **output** and **input** devices
* Whether to **force** default communication devices
* Whether to **disable** Wireless Controller audio devices
* Whether to install the background **watcher**
* Whether to enable **NUCLEAR** mode (disable all non-preferred devices)

Your choices are stored in:

```
%APPDATA%\listenhereyoulittle\defaults.json
```

## Uninstallation

1. Run **Kill Watcher** from the Start Menu to remove the scheduled task.
2. Delete `%APPDATA%\listenhereyoulittle`.
3. Delete **ListenHereYouLittle** from your Start Menu.

## Repository

[https://github.com/harryeffinpotter/listenhereyoulittle](https://github.com/harryeffinpotter/listenhereyoulittle)

## License

This project is licensed under the MIT License.

