# LAMP + Miva Empresa Provisioning Scripts for Chesapeake Ranch Estates Development

## Overview

These scripts are designed to streamline the setup of a local web development environment on an Ubuntu Server virtual machine, specifically tailored for projects related to Chesapeake Ranch Estates-Drum Point. They automate the installation of a LAMP (Linux, Apache, MariaDB, PHP) stack and offer integrated support for the Miva Empresa e-commerce platform. This setup is optimized for use within Virtualbox, allowing you to develop and test your websites locally before deployment.

## Prerequisites

* **Virtualbox:** Ensure you have Oracle Virtualbox installed on your primary operating system (Windows, macOS, or Linux).
* **Ubuntu Server VM:** You need an Ubuntu Server virtual machine configured in Virtualbox. It's highly recommended to use the latest Long Term Support (LTS) version, currently Ubuntu 24.04 LTS ("Noble Numbat").
* **Virtualbox Guest Additions:** Install Virtualbox Guest Additions on your Ubuntu Server VM. This enhances integration between the host and guest, enabling features like shared folders (useful for accessing your project files) and proper display resolution.
* **Network Configuration:** For easy access to your local websites from your host machine, configure the network settings of your Ubuntu Server VM in Virtualbox to use a **Host-only Adapter**. This creates a private network between your host and the VM. These scripts are configured to work with the default `192.168.56.x` IP address range assigned by Virtualbox for Host-only networks.

## Installation

1.  **Download the Scripts:** Download all the script files (listed below) and transfer them to a directory on your Ubuntu Server VM. A convenient location would be your home directory (`/home/<your_username>`) or a dedicated `scripts` folder within it.

    * `setup-lamp.sh`
    * `setup-miva.sh`
    * `add-virtualhost.sh`
    * `delete-virtualhost.sh`
    * `add-database.sh`
    * `add-miva-to-site.sh`
    * `lampstack-menu.sh`
    * `set-hostname.sh`
    * `utils.sh`
    * `LICENSE` (This file contains the full text of the Creative Commons BY-NC-SA 4.0 license)

2.  **Make the Scripts Executable:** Open a terminal in your Ubuntu Server VM, navigate to the directory where you saved the scripts using the `cd` command, and give them execute permissions:

    ```bash
    cd ~/scripts  # Or wherever you saved them
    chmod +x *.sh
    ```

## Usage

The `lampstack-menu.sh` script provides a central interface for managing your local development environment:

1.  **Run the Menu:** Execute the script from your terminal:

    ```bash
    ./lampstack-menu.sh
    ```

2.  **Select Options:** The menu will guide you through the available actions:

    * **1) Install LAMP stack:** Installs the foundational software for web development: Apache (web server), PHP (programming language), MariaDB (database server), and phpMyAdmin (web-based database administration tool). You will be prompted to set a secure root password for MariaDB during this process.
    * **2) Install Miva Empresa Engine:** Downloads and installs the Miva Empresa e-commerce engine in the `/usr/local/mivavm-v5.51` directory.
    * **3) Add a new virtual host:** Creates a new website on your local server. You'll be asked for the domain name (e.g., `che-project.local`). The script will assign it a local IP address, configure Apache, and update the VM's internal name resolution. **Crucially, after running this, you MUST also update your host machine's `hosts` file** as described in the next section to access the site in your browser. You'll also have the option to configure Miva for this new site.
    * **4) Add Miva Empresa to an existing virtual host:** Enables Miva support for a website you've already set up using option 3.
    * **5) Create a MariaDB database for a virtual host:** Creates a dedicated database and user in MariaDB for a specific website. The login credentials for the database will be saved in `/etc/lampstack/site-db-creds.txt` on your VM.
    * **6) Delete a virtual host:** Removes the configuration and associated files for a virtual host you no longer need.
    * **7) View configuration log:** Opens the `/var/log/lampstack-install.log` file, which contains a record of actions performed by the scripts. Use `less` to navigate the log (press `q` to exit).
    * **8) Set server hostname:** Allows you to change the internal hostname of your Ubuntu Server VM (e.g., `cre-dev-server`). A system reboot is recommended after changing the hostname for it to fully take effect.
    * **9) Exit:** Closes the `lampstack-menu.sh` application.
    * **d) Toggle Debug Mode:** When enabled, the scripts will display more detailed output in your terminal during execution, useful for troubleshooting.
    * **n) Toggle Dry-Run Mode:** When enabled, the scripts will simulate the commands they would run without actually making any changes to your system. This is great for previewing what the scripts will do before you execute them for real.

## Accessing Your Local Websites from Your Computer

To view the websites you create within the Ubuntu Server VM in your web browser on your main computer (the one running Virtualbox), you need to tell your computer how to find them. This is done by editing your host machine's `hosts` file.

1.  **Locate the `hosts` File:**
    * **Windows:** Open File Explorer and navigate to `C:\Windows\System32\drivers\etc\`. The `hosts` file is in this directory.
    * **macOS:** Open Finder, go to "Go" in the menu bar, select "Go to Folder...", and enter `/etc`. The `hosts` file is located here.
    * **Linux:** The `hosts` file is typically located at `/etc/hosts`.

2.  **Open with Administrator/Root Privileges:** You need to open this file with elevated permissions to save changes.
    * **Windows:** Right-click on Notepad (or your preferred text editor), select "Run as administrator," and then open the `hosts` file from within the editor.
    * **macOS/Linux:** Use the `sudo` command with a text editor like `nano` or `vim` in the terminal (e.g., `sudo nano /etc/hosts`).

3.  **Add Entries:** For each virtual host you create using option 3 in the menu, add a new line to the `hosts` file. The line should contain the IP address assigned to the virtual host (displayed in the terminal when you create it) followed by the domain name you chose. Separate the IP and the domain name with at least one space.

    ```
    192.168.56.XX  your-virtualhost-domain.local
    ```

    **Example:** If you created a site for a Chesapeake Ranch Estates project with the domain `cre-project1.local` and the script assigned it the IP `192.168.56.115`, you would add the following line to your host's `hosts` file:

    ```
    192.168.56.115  cre-project1.local
    ```

4.  **Save the File:** Save the changes to the `hosts` file.

5.  **Clear DNS Cache (If Necessary):** Sometimes, your operating system or browser might cache DNS information. If you can't access your local website immediately after editing the `hosts` file, try clearing your DNS cache:
    * **Windows:** Open Command Prompt as administrator and run `ipconfig /flushdns`.
    * **macOS:** Open Terminal and run `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`.
    * **Linux:** The command varies depending on your distribution (e.g., `sudo systemd-resolve --flush-caches` or `sudo /etc/init.d/networking restart`).

## Important Configuration Files

* `/etc/lampstack/site-ips.conf`: This file within your Ubuntu VM keeps track of which IP addresses in the `192.168.56.x` range are assigned to which virtual host domain names.
* `/var/log/lampstack-install.log`: This log file on your Ubuntu VM records all the actions performed by the provisioning scripts, which can be helpful for reviewing the setup process or troubleshooting issues.
* `/etc/lampstack/site-db-creds.txt`: This file on your Ubuntu VM stores the database name, username, and password for each MariaDB database created for your virtual hosts. **For a production environment, you would typically manage these credentials more securely. However, for a local development setup, this provides a convenient way to access them.**

## Debug and Dry-Run Modes

These modes, accessible via the `lampstack-menu.sh`, are powerful tools for understanding and testing the scripts:

* **Debug Mode:** When enabled, the scripts will output extra, detailed information to your terminal as they run. This can show you the exact commands being executed and the values of important variables, aiding in diagnosing any problems.
* **Dry-Run Mode:** When enabled, the scripts will simulate their actions without making any actual changes to your system. This allows you to preview what the scripts *would* do, ensuring they behave as expected before you commit to running them for real. Look for `[DEBUG: DRY-RUN]` messages in the output.

You can toggle these modes on or off from the main menu of `lampstack-menu.sh`. It's often useful to enable both debug and dry-run modes for a very detailed and safe preview of the scripts' behavior.

## License

These scripts are licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. See the [LICENSE](LICENSE) file for the full terms.