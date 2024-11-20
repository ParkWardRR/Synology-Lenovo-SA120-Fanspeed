# Synology-Lenovo-SA120-Fanspeed

Control the fan speed on the Lenovo SA120 disk array through Synology/Xpenology DSM.

## Requirements

The Installation Steps will install the following prerequisites:

- [sg3-utils](http://sg.danny.cz/sg/sg3_utils.html). The `sg3_utils` package contains utilities that send SCSI commands to devices.
- [Entware/opkg](https://github.com/Entware/Entware/wiki). `opkg` is used to install `sg3_utils`.

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

    DSM > Control Panel > Task Scheduler > Create > Triggered Task > User Defined Script.

        General >
            Task: Entware  
            User: root  
            Event: Boot-up  
            Pretask: none  
            Enabled  

        Task Settings > Run Command (Enter the following script in the entry box):

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

1. Create Bash scripts named `fanspeedX.sh` (where X = fan speed level between 1-6):

   ```bash
   sudo touch fanspeedX.sh  
   sudo nano /volume1/apps/sa120/fanspeedX.sh  

       #!/bin/bash  
       python /volume1/apps/sa120/fanspeed.py X      # Replace X with fan speed level (e.g., fanspeed2.sh sets speed level to 2)
   
   Repeat for settings from speeds 2-6.
   ```

2. **Create Fanspeed Autostart Task**:

    DSM > Control Panel > Task Scheduler > Create > Triggered Task > User Defined Script.

        General >
            Task: fanspeed  
            User: root  
            Event: Boot-up  
            Pretask: Entware  
            Enabled  

        Task Settings > Run Command:
        
        ```bash 
        sudo -i bash /volume1/apps/sa120/fanspeedX.sh     # Adjust for desired fan speed level.
        ```

4. **Create Fanspeed Scheduled Tasks**:

    DSM > Control Panel > Task Scheduler > Create > Scheduled Task > User Defined Script.

        General >
            Task: fanspeedX (... X = fan speed levels)  
            User: root  

        Schedule >
            Frequency: Every hour (or as needed)  

        Task Settings >
            Run Command:
        
        ```bash 
        sudo -i bash /volume1/apps/sa120/fanspeedX.sh     # Adjust X for each fan speed level.
        ```

## Source

[Reddit Link](https://www.reddit.com/r/DataHoarder/comments/70z50k/lenovo_sa120_how_to_quieten/dn7465u/)
