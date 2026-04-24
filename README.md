# Synology-Lenovo-SA120-Fanspeed

Control the fan speed on the Lenovo SA120 disk array through Synology/Xpenology DSM.

## Overview

This project provides a **zero-dependency** Python script that directly interacts with the Linux SCSI generic (`SG_IO`) interface to control the Lenovo SA120 fan speed.

Unlike older methods, **this does not require installing Entware, `sg3_utils`, or any third-party packages.** It uses the native Python 3 installation included with DSM 7+.

## System Requirements

- Synology NAS running DSM version 7.x or later (includes Python 3 natively).
- Lenovo SA120 Disk Array connected to your Synology NAS.

## Installation Steps

1. **SSH into your Synology/Xpenology DSM** as a user with administrator privileges.

2. **Create a shared folder location for the script**:
   ```bash
   sudo mkdir -p /volume1/apps/sa120
   ```

3. **Download the script**:
   ```bash
   sudo curl -s https://raw.githubusercontent.com/ParkWardRR/Synology-Lenovo-SA120-Fanspeed/main/fanspeed.py | sudo tee /volume1/apps/sa120/fanspeed.py > /dev/null
   ```

4. **Make it executable**:
   ```bash
   sudo chmod +x /volume1/apps/sa120/fanspeed.py
   ```

## Usage

### Manual Operation

Run the script directly via SSH. Adjust fan speed between levels 1 (minimal) and 7 (maximum):

```bash
sudo /bin/python3 /volume1/apps/sa120/fanspeed.py 1
```

### Automating on Boot (Task Scheduler)

To ensure the fan speed is set automatically whenever your NAS restarts:

1. Go to **DSM > Control Panel > Task Scheduler > Create > Triggered Task > User Defined Script**.
2. **General Tab:**
   - **Task:** `SA120 Fan Control`
   - **User:** `root`
   - **Event:** `Boot-up`
   - **Enabled:** (Check this box)
3. **Task Settings Tab > Run Command:**
   ```bash
   /bin/python3 /volume1/apps/sa120/fanspeed.py 1
   ```
   *(Replace `1` with your desired fan speed level 1-7)*
4. Click **OK** to save.

## How it Works

1. The script scans `/sys/class/scsi_generic/sg*/device/model` to automatically discover the device node assigned to the `ThinkServerSA120` enclosure.
2. It issues a `RECEIVE DIAGNOSTIC RESULTS` SCSI command to fetch the Enclosure Control page (`0x2`).
3. It modifies the cooling element bits to set your desired fan speed.
4. It sends the modified payload back via a `SEND DIAGNOSTIC` SCSI command using Python's native `fcntl` and `ctypes` libraries.

## License

This project is licensed under the MIT License.
