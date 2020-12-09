# Synology-Lenovo-SA120-Fanspeed
Control the fan speed on the Lenovo SA120 disk array through Synology/Xpenology DSM



## Requirements 
Still requires the sg3-utils install  

 1. SSH into your Synology/Xpenology
 2. Install oPKG - [Tutorial](https://medium.com/@yehia2amer/how-to-install-a-package-manager-on-a-synology-nas-router-ipkg-opkg-c620890e4c77)
 3. Switch to root "sudo -i" 
 4. Install sg3-utils "opkg install sg3-utils"

## Usage

 1. SSH into your Synology/Xpenology
 2. Switch to root "sudo -i" 
 3. Navigate to the python file 
 4. Make it executable "chmod +x fanspeed.py" 
 5. Run the script

    python fanspeed.py 1

Adjusting 1 - 3 for various levels 

## Source
 [Reddit Link](https://www.reddit.com/r/DataHoarder/comments/70z50k/lenovo_sa120_how_to_quieten/dn7465u/)
