
# Synology-Lenovo-SA120-Fanspeed
Control the fan speed on the Lenovo SA120 disk array through Synology/Xpenology DSM

## Requirements 
The Installation Steps will install the following prerequisites.
- [sg3-utils](http://sg.danny.cz/sg/sg3_utils.html). The sg3_utils package contains utilities that send SCSI commands to devices.    
- [Entware/opkg](https://github.com/Entware/Entware/wiki). Opkg is used to install sg3-utils.

## Installation Steps
1. SSH into your Synology/Xpenology DSM
2. Install Entware (Steps adapted from https://github.com/Entware/Entware/wiki/Install-on-Synology-NAS). Because firmware updates may erase the /opt folder, Entware is deployed outside of rootfs with a "symlink" or "mount -o bind" to /opt. 
    ``` 
    sudo mkdir -p /volume1/apps/@Entware/opt    # create a location for entware packages
    sudo mv /opt /opt.bak                       # backup previous add-on application software packages
    sudo mkdir -p /opt                          # /opt is reserved by Linux for add-on application packages
    sudo mount -o bind "/volume1/apps/@Entware/opt" /opt   
    # If bind fails, try sudo ln -s /volume1/@Entware/opt/ /opt  
    ```
3. Run processor-specific Entware installation script 
    ```
    uname -m	# shoulld output as "x86_64". Otherwise, use the appropriate installer at https://bin.entware.net/
    sudo wget --no-check-certificate -O - https://bin.entware.net/x64-k3.2/installer/generic.sh | /bin/sh
    ```
4. Create Entware Autostart Task in DSM

    DSM > Control Panel > Task Scheduler > Create > Triggered Task > User Defined Script

        General >
            Task: Entware
            User: root
            Event: Boot-up
            Pretask: none
            Enabled
        Task Settings > Run Command: (Enter the following script in the entry box)
    ```
        #!/bin/sh
        # Mount/Start Entware
        mkdir -p /opt
        mount -o bind "/volume1/apps/@Entware/opt" /opt
        /opt/etc/init.d/rc.unslung start

        # Add Entware Profile in Global Profile
        if grep  -qF  '/opt/etc/profile' /etc/profile; then
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
5. Restart
6. Install sg3_utils
``` 
    sudo opkg update
    sudo opkg install sg3_utils
```
7. Fanspeed Script. Create a Shared Folder for Scripts and then "insall" the script.
``` 
    sudo mkdir /volume1/apps/sa120
    sudo curl https://raw.githubusercontent.com/ParkWardRR/Synology-Lenovo-SA120-Fanspeed/main/fanspeed.py > /volume1/apps/sa120/fanspeed.py
    sudo chmod +x /volume1/apps/sa120/fanspeed.py
```
## Usage
### Manual Operation
1. SSH into your Synology/Xpenology
2. Run fanspeed.py (Adjust 1 - 6 for various levels)
```
    sudo python /volume1/apps/sa120/fanspeed.py 1
```
### Scripted Operation
1. Create Bash scripts named fanspeedx.sh (x = 1 to 6... one for each speed setting)
```
    sudo touch fanspeed1.sh
    sudo nano /volume1/apps/sa120/fanspeed1.sh
        #!/bin/bash
        python /volume1/apps/sa120/fanspeed.py 1
    Repeat script creation for settings 2-6
```
3. Create Fanspeed Autostart Task
   
    DSM > Control Panel > Task Scheduler > Create > Triggered Task > User Defined Script

        General >
            Task: fanspeed
            User: root
            Event: Boot-up
            Pretask: Entware
            Enabled
        Task Settings > Run Command: sudo -i bash /volume1/apps/sa120/fanspeed1.sh
4.  Create Fanspeed Scheduled Tasks
   
    DSM > Control Panel > Task Scheduler > Create > Scheduled Task > User Defined Script

        General
            Task: fanspeed1 (... 2,3,4,5,6)
            User: root
        Schedule
            Run on the following date: Daily
            Frequency: Every hour
            Disabled
        Task Settings > Run Command: sudo -i bash /volume1/apps/sa120/fanspeed1.sh (... 2,3,4,5,6)

## Source
 [Reddit Link](https://www.reddit.com/r/DataHoarder/comments/70z50k/lenovo_sa120_how_to_quieten/dn7465u/)

