These instructions detail the fulfillment for the ClamAV installation inject, detailing the steps for installation and configuration. Please note that these steps must be done using an **Administrator Command Prompt (CMD), NOT POWERSHELL**.

## ClamAV Installation and Configuration

| Step | Description |
| --- | --- |
| **1** | Navigate to [clamav.net/downloads](https://clamav.net/downloads) and select 'Windows' under 1.5.1. Download the **'clamav-1.5.1.win.x64.msi'** package. |
| **2** | Once downloaded, click on the **'clamav-1.5.1.win.x64.msi'** package and follow the instructions on the installer. |
| **3** | Using an Administrator CMD (NOT POWERSHELL), navigate to the directory: `cd C:\Program Files\ClamAV`. |
| **4** | Download and run the configuration script: `powershell -command "iwr https://tinyurl.com/byunccdc/injects/clamav.ps1 -o clamav.ps1"` followed by `powershell -command "./clamav.ps1"`. |
| **5** | Run `.\freshclam.exe`. **NOTE:** You may encounter an error; run it anyway to initialize the directory structure. If you run into an error, follow steps 5a and 5b. If no error occurs, skip to step 6. |
| **5a** | In your browser, download the database files from: [https://database.clamav.net/main.cvd](https://database.clamav.net/main.cvd), [https://database.clamav.net/daily.cvd](https://database.clamav.net/daily.cvd), and [(https://database.clamav.net/bytecode.cvd](https://database.clamav.net/bytecode.cvd). |
| **5b** | Copy those three files from your Downloads folder and paste them into: `C:\Program Files\ClamAV\database`. |
| **6** | Run `.\freshclam.exe` again to verify the database files are recognized. |
| **7** | Perform a sample scan of your current directory by running the command `clamscan`. |
| **8** | Open **Task Scheduler** to confirm that a task named **'Clam_30min_scan'** has been successfully created. |

---
