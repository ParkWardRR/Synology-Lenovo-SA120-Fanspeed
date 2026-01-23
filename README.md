# SA120 Fan Speed Controller

Control fan speed on Lenovo ThinkServer SA120 disk shelves via Synology DSM.

Works with DSM 7.x, Xpenology, and Arc Loader.

## Quick Install

```bash
# SSH into your NAS as root, then:
cd /tmp
git clone https://github.com/ParkWardRR/Synology-Lenovo-SA120-Fanspeed.git
cd Synology-Lenovo-SA120-Fanspeed
sudo bash install.sh
```

The installer will:
- Check for and install `sg3_utils` (via Entware)
- Copy the script to `/volume1/apps/sa120/`
- Test SA120 detection
- Print Task Scheduler setup instructions

## Usage

```bash
# Check current fan speeds
/volume1/apps/sa120/fanspeed.sh --status

# Set all fans to speed 2 (quiet)
/volume1/apps/sa120/fanspeed.sh 2

# Set all fans to speed 1 (quietest)
/volume1/apps/sa120/fanspeed.sh 1
```

### Speed Levels

| Level | Description |
|-------|-------------|
| 1     | Slowest (quietest) |
| 2     | Low |
| 3     | Medium |
| 4     | Medium-High |
| 5     | High |
| 6     | Maximum (loudest) |

## Auto-Start on Boot

1. Open **DSM > Control Panel > Task Scheduler**
2. Click **Create > Triggered Task > User-defined script**
3. Configure:
   - **Task:** `SA120-Fanspeed`
   - **User:** `root`
   - **Event:** `Boot-up`
   - **Enabled:** Yes
4. In **Task Settings**, enter:
   ```bash
   /volume1/apps/sa120/fanspeed.sh 2
   ```
   (Change `2` to your preferred speed)

## Requirements

- Synology DSM 7.x (or Xpenology/Arc Loader)
- Lenovo SA120 connected via SAS
- [Entware](https://github.com/Entware/Entware/wiki/Install-on-Synology-NAS) (for `sg3_utils`)

### Installing Entware

If you don't have Entware installed:

```bash
# Create Entware directory
sudo mkdir -p /volume1/@Entware/opt
sudo mkdir -p /opt
sudo mount -o bind /volume1/@Entware/opt /opt

# Install Entware (x86_64)
wget -O - https://bin.entware.net/x64-k3.2/installer/generic.sh | sudo sh

# Install sg3_utils
sudo /opt/bin/opkg update
sudo /opt/bin/opkg install sg3_utils
```

## Troubleshooting

### "sg_ses not found"

Install sg3_utils via Entware:
```bash
sudo /opt/bin/opkg install sg3_utils
```

### "No SA120 enclosure found"

1. Check SAS cable connections
2. Verify SA120 is powered on
3. List available devices:
   ```bash
   ls /dev/sg*
   sg_ses /dev/sg0  # Try each device
   ```

### Permission denied

Run with sudo:
```bash
sudo /volume1/apps/sa120/fanspeed.sh 2
```

## Command Line Options

```
Usage: fanspeed.sh [OPTIONS] [SPEED]

Options:
  -s, --status       Show current fan speeds
  -d, --device DEV   Use specific device (skip auto-detect)
  -q, --quiet        Suppress output
  -h, --help         Show help

Examples:
  fanspeed.sh --status           # Check speeds
  fanspeed.sh 2                  # Set to speed 2
  fanspeed.sh -d /dev/sg6 1      # Specific device
```

## License

Apache 2.0 - See [LICENSE](LICENSE)

## Credits

Original Python script from [Reddit](https://www.reddit.com/r/DataHoarder/comments/70z50k/lenovo_sa120_how_to_quieten/dn7465u/)
