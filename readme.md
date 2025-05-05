# ListenHereYouLittle-

![Sheeeeeeeeeit](https://media1.giphy.com/media/FzXa3cs6ux2so/giphy.gif)

A PowerShell toolkit to enforce and maintain your preferred audio devices on Windows.

---

## Contents

* **init.ps1**: Installer and configuration script.
* **fix.ps1**: One-shot fixer to apply your preferences immediately.
* **watch.ps1**: Background watcher that re-applies preferences every 30 seconds.
* **kill-watch.ps1**: Stops all running watcher processes.
* **remove-task.ps1**: Unregisters the scheduled watcher task (requires elevation).
* **run-init.bat**: Self-elevating batch wrapper to launch `init.ps1`.

---

## Installation

### Option 1 (RECOMMENDED)

**Install with a non-admin PowerShell one-liner.**

Copy and paste into a PowerShell window, press Enter, then follow the on-screen prompts:

```powershell
iwr -UseBasicParsing https://raw.githubusercontent.com/harryeffinpotter/listenhereyoulittle/refs/heads/master/init.ps1 | iex
```

### Option 2 (Backup)

1. Download `init.ps1` and `run-init.bat` from the repo.
2. Right-click and **Run as administrator** (or double-click `run-init.bat`).
3. Follow the on-screen prompts.

Both options will:

1. Prompt for your preferences.
2. Elevate to administrator when scheduling the watcher.
3. Install and configure all scripts under `%APPDATA%\listenhereyoulittle`.
4. Create Start Menu shortcuts (see below).

---

## Usage

All shortcuts are placed in **Start Menu → Programs → ListenHereYouLittle**:

* **Fix Audio**: Apply your selected devices immediately.
* **Watch Audio**: Launch the 30-second background watcher (runs hidden).
* **Kill Watcher**: Stop any running `watch.ps1` instances.
* **Remove Scheduled Task**: Unregister the automatic watcher task (only if you chose to install it).

You can also run each script directly from `%APPDATA%\listenhereyoulittle`:

```powershell
& "$env:APPDATA\listenhereyoulittle\fix.ps1"
& "$env:APPDATA\listenhereyoulittle\watch.ps1"
& "$env:APPDATA\listenhereyoulittle\kill-watch.ps1"
& "$env:APPDATA\listenhereyoulittle\remove-task.ps1"
```

---

## Configuration

During installation, you will be prompted to choose:

* **Preferred output** and **input** devices
* **Force** default communication devices
* **Disable** Wireless Controller audio devices
* **Install** the 30s background watcher
* **Enable NUCLEAR mode** (disable all non-preferred devices)

Your settings are saved in:

```text
%APPDATA%\listenhereyoulittle\defaults.json
```

---

## Uninstallation

1. If you installed the watcher, run **Remove Scheduled Task** (Start Menu) or:

   ```powershell
   & "$env:APPDATA\listenhereyoulittle\remove-task.ps1"
   ```

2. Run **Kill Watcher** to stop any live watchers.

3. Delete the folder:

   ```powershell
   Remove-Item -Recurse -Force "%APPDATA%\listenhereyoulittle"
   ```

4. Remove **ListenHereYouLittle** from your Start Menu.

---

## Repository

[https://github.com/harryeffinpotter/listenhereyoulittle](https://github.com/harryeffinpotter/listenhereyoulittle)

---

## License

This project is licensed under the MIT License.

---

![Listen here you little....](https://external-preview.redd.it/1-b8ieJfbcQxNFx76wzuewNDD6IjunsgBe-V6PZYQoY.png?width=640\&crop=smart\&auto=webp\&s=67acf4cc695aa3920751b7fe902db3be9ae2e896)
