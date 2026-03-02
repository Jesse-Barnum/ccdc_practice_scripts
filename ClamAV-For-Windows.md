These instructions detail the fulfillment for the ClamAV installation inject, detailing the steps for installation and configuration. Please note that these steps must be done using an **Administrator Command Prompt (CMD), NOT POWERSHELL**.

## ClamAV Installation and Configuration

| Step | Description |
| --- | --- |
| **1** | Navigate to [clamav.net/downloads](https://clamav.net/downloads) and select 'Windows' under 1.5.1. Download the **'clamav-1.5.1.win.x64.msi'** package. |
| **2** | Once downloaded, click on the **'clamav-1.5.1.win.x64.msi'** package and follow the instructions on the installer. |
| **3** | Using an Administrator CMD (NOT POWERSHELL), navigate to the directory: `cd C:\Program Files\ClamAV`. |
| **4** | Download and run the configuration script: `powershell -command "iwr https://tinyurl.com/byunccdc/injects/clamav.ps1 -o clamav.ps1"` followed by `powershell -command "./clamav.ps1"`. |
| **5** | Run `.\freshclam.exe`. **NOTE:** You may encounter an error; run it anyway to initialize the directory structure. If you run into an error, follow steps 5a, 5b, and 5c. If no error occurs, skip to step 6. |
| **5a** | In your browser, download the database files from: [https://database.clamav.net/main.cvd](https://database.clamav.net/main.cvd), [https://database.clamav.net/daily.cvd](https://database.clamav.net/daily.cvd), and [(https://database.clamav.net/bytecode.cvd](https://database.clamav.net/bytecode.cvd). |
| **5b** | Copy those three files from your Downloads folder and paste them into: `C:\Program Files\ClamAV\database`. |
| **5c** | Run `.\freshclam.exe` again to verify the database files are recognized. |
| **6** | Perform a sample scan of your current directory by running the command `clamscan`. |
| **7** | Open **Task Scheduler** to create a new task for clamscan. To create a new task, follow these steps: <br> 1. Select "Create Task" from the 'Actions' option on the right side of the application. <br> 2. Under the "General" tab, add a title to the task: 'ClamAV_Hourly_Scan'. <br> 3. Under the "Trigger" tab, select 'new'. Under the 'advanced setting' section of this task creation popup, select the checkbox next to 'Repeat Task Every'and set it to repeat every '1 hour' for the duration of 'indefinitely'. <br> 4. Under the "Actions" tab, select 'New'. Set the action to 'Start a Program' and set the program file path to "C:\Program Files\ClamAV\clamscan.exe". <br> 5. Select 'OK' to save the task.|
| **8** | Show that the 'Scheduled Task' was created by running this command on Powershell:. |

---
