# Synology-Lenovo-SA120-Fanspeed

Control the fan speed on the Lenovo SA120 disk array through Synology/Xpenology DSM.

## Prerequisites

- Ensure that you have Python installed. You can check your Python version by running:
  ```bash
  python --version
  ```
  If your system defaults to Python 2 but you need Python 3, use `python3` instead.

- Verify that `sg3_utils` is installed:
  ```bash
  sg_inq --version
  ```
  If not installed, follow the installation steps below.

## System Requirements

- Synology NAS running DSM version 6.x or later.
- Lenovo SA120 Disk Array connected to your Synology NAS.
- Entware installed on your Synology NAS.

## Installation Steps

1. **SSH into your Synology/Xpenology DSM**.
2. **Install Entware** (Steps adapted from [Entware's Synology NAS installation guide](https://github.com/Entware/Entware/wiki/Install-on-Synology-NAS)). Because firmware updates may erase the `/opt` folder, Entware is deployed outside of rootfs with a "symlink" or "mount -o bind" to `/opt`.

    ```bash
    sudo mkdir -p /volume1/apps/@Entware/opt    # create a location for Entware packages
    sudo mv /opt /opt.bak                       # backup previous add-on application software packages
    sudo mkdir -p /opt                          # /opt is reserved by Linux for add-on application packages
    sudo mount -o bind "/volume1/apps/@Entware/opt" /opt
    # If bind fails, try:
    sudo ln -s /volume1/@Entware/opt/ /opt  
    ```

3. **Run processor-specific Entware installation script**:

    ```bash
    uname -m  # should output as "x86_64". Otherwise, use the appropriate installer at https://bin.entware.net/
    sudo wget --no-check-certificate -O - https://bin.entware.net/x64-k3.2/installer/generic.sh | /bin/sh
    ```

4. **Create Entware Autostart Task in DSM**:

   Go to **DSM > Control Panel > Task Scheduler > Create > Triggered Task > User Defined Script**.

   - **General:**
     - **Task:** `Entware`
     - **User:** `root`
     - **Event:** `Boot-up`
     - **Pretask:** `none`
     - **Enabled:** (Check this box)

   - **Task Settings > Run Command:**

     Enter the following script in the entry box:

     ```bash
     #!/bin/sh
     # Mount/Start Entware
     mkdir -p /opt
     mount -o bind "/volume1/apps/@Entware/opt" /opt
     /opt/etc/init.d/rc.unslung start

     # Add Entware Profile in Global Profile
     if grep -qF '/opt/etc/profile' /etc/profile; then
         echo "Confirmed: Entware Profile in Global Profile"
     else
         echo "Adding: Entware Profile in Global Profile"
         cat >> /etc/profile <<"EOF"

         # Load Entware Profile
         [ -r "/opt/etc/profile" ] && . /opt/etc/profile
         EOF
     fi

     # Update Entware List
     /opt/bin/opkg update
     ```

5. **Restart** your system.
6. **Install `sg3_utils`**:

    ```bash
    sudo /opt/bin/opkg update  
    sudo /opt/bin/opkg install sg3_utils  
    ```

7. **Fanspeed Script**: Create a shared folder for scripts and then "install" the script:

    ```bash
    sudo mkdir /volume1/apps/sa120  
    sudo curl https://raw.githubusercontent.com/ParkWardRR/Synology-Lenovo-SA120-Fanspeed/main/fanspeed.py | sudo tee /volume1/apps/sa120/fanspeed.py > /dev/null  
    sudo chmod +x /volume1/apps/sa120/fanspeed.py  # Ensure the script is executable  
    ```

8. **Set Correct Permissions for `/volume1/apps/sa120`**:
   Ensure that the folder and its contents have the correct permissions:

   ```bash
   # Set directory permissions to 755 (rwxr-xr-x)
   sudo chmod -R 755 /volume1/apps/sa120
   
   # Set file permissions to 644 (rw-r--r--)
   find /volume1/apps/sa120 -type f -exec chmod 644 {} \;
   
   # Ensure fanspeed.py remains executable:
   sudo chmod +x /volume1/apps/sa120/fanspeed.py
   ```

9. **Validate Folder Permissions**:
   Before proceeding, validate that the folder permissions are correctly set:

   ```bash
   stat -c "%a %n" /volume1/apps/sa120  # Should output 755 for directories and 644 for files.
   ```

## Usage

### Manual Operation

1. SSH into your Synology/Xpenology.
2. Run `fanspeed.py`. Adjust fan speed between levels 1-6:
   
   ```bash
   sudo python /volume1/apps/sa120/fanspeed.py <fan_speed>     # Replace <fan_speed> with a value between 1 and 6.
   ```

   **Note:** Ensure you provide a valid fan speed (between 1 and 6) when running the script.

### Scripted Operation

1. Create Bash scripts named `fanspeedX.sh` (where X = fan speed level between 1-6) using a one-liner command:

   ```bash
   for i in {1..6}; do sudo bash -c "echo '#!/bin/bash\npython /volume1/apps/sa120/fanspeed.py $i' > /volume1/apps/sa120/fanspeed$i.sh && chmod +x /volume1/apps/sa120/fanspeed$i.sh"; done
   ```

This command will automatically create six scripts (`fanspeed1.sh`, `fanspeed2.sh`, ..., `fanspeed6.sh`) in `/volume1/apps/sa120`, each setting a different fan speed level.

2. **Create Fanspeed Autostart Task**:

   Go to **DSM > Control Panel > Task Scheduler > Create > Triggered Task > User Defined Script**.

   - **General:**
     - **Task:** `fanspeed`
     - **User:** `root`
     - **Event:** `Boot-up`
     - **Pretask:** `Entware`
     - **Enabled:** (Check this box)

   - **Task Settings > Run Command:**

     ```bash 
     sudo -i bash /volume1/apps/sa120/fanspeedX.sh     # Adjust for desired fan speed level.
     ```

3. **Create Fanspeed Scheduled Tasks**:

   Go to **DSM > Control Panel > Task Scheduler > Create > Scheduled Task > User Defined Script**.

   - **General:**
     - **Task:** `fanspeedX` (... X = fan speed levels)
     - **User:** `root`

   - **Schedule:**
     Set frequency as needed (e.g., every hour).

   - **Task Settings > Run Command:**

     ```bash 
     sudo -i bash /volume1/apps/sa120/fanspeedX.sh     # Adjust X for each fan speed level.
     ```

## Customization

### Adjusting Fan Speed Levels

The fan speed levels in this script are set between 1 and 6. You can modify these levels directly in the script if needed.

To change the default fan speed level for autostart tasks, edit the `fanspeedX.sh` scripts accordingly:

```bash
sudo nano /volume1/apps/sa120/fanspeedX.sh

# Example content for fanspeed2.sh (sets fan speed to level 2)
#!/bin/bash
python /volume1/apps/sa120/fanspeed.py 2
```

### Modifying Script Behavior

If you'd like to modify how often the fan speeds are checked or adjusted, you can edit the scheduled tasks in DSM's Task Scheduler by adjusting the frequency of execution.

## Logging

To enable logging for debugging purposes, you can redirect the output of the script to a log file. For example:

```bash
sudo python /volume1/apps/sa120/fanspeed.py <fan_speed> >> /volume1/apps/sa120/fanspeed.log 2>&1
```

This will save both standard output and errors into `fanspeed.log`. You can review this file later to debug any issues.

## Troubleshooting

### Permission Denied Errors

If you encounter permission denied errors when trying to execute the script, ensure that:

- The script has executable permissions:
  
```bash
sudo chmod +x /volume1/apps/sa120/fanspeed.py
```

- You are running the script with `sudo` privileges:
  
```bash
sudo python /volume1/apps/sa120/fanspeed.py <fan_speed>
```

### Missing `sg_ses` Command

If you receive an error about the `sg_ses` command not being found, it means that `sg3_utils` is not properly installed. Reinstall it using:

```bash
sudo /opt/bin/opkg install sg3_utils
```

### IndexError: List Index Out of Range

This error occurs if you don't provide a valid argument (fan speed) when running the script. Ensure you're passing a number between 1 and 6:

```bash
sudo python /volume1/apps/sa120/fanspeed.py <fan_speed>
```

Replace `<fan_speed>` with a number between 1 and 6.

## Security Considerations

- Always ensure that you trust the source of any scripts or packages you're installing.
- This script requires `sudo` privileges because it interacts with system-level hardware (the Lenovo SA120). Be cautious when granting root access.
- It's recommended that you review any downloaded scripts before executing them on your system.

## Contributing

Contributions are welcome! If you'd like to improve this project, feel free to submit a pull request or open an issue on GitHub.

### How to Contribute:

1. Fork this repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Make your changes and commit them (`git commit -m 'Add new feature'`).
4. Push your branch (`git push origin feature-branch`).
5. Open a pull request and describe your changes.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Source

[Reddit Link](https://www.reddit.com/r/DataHoarder/comments/70z50k/lenovo_sa120_how_to_quieten/dn7465u/) 

---

This version includes all suggested sections such as troubleshooting, customization, logging, security considerations, contributing guidelines, license information, and most importantly, it now uses a one-liner command to create all six fanspeed scripts without needing manual editing via `nano`.
