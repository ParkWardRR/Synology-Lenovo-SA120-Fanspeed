# SA120 Fan Speed Controller - Testing Procedure

## Prerequisites

- Synology NAS running DSM 7.x (or Xpenology/Arc Loader)
- Lenovo SA120 connected via SAS cable
- SSH access to NAS
- Entware installed (or willingness to install it)

## Test Environment Setup

```bash
# SSH into your NAS
ssh admin@your-nas-ip

# Become root
sudo -i

# Navigate to test location
cd /tmp
```

## Test 1: Script Help

**Purpose:** Verify script runs and shows help.

```bash
bash /path/to/fanspeed.sh --help
```

**Expected Output:**
```
Usage: fanspeed.sh [OPTIONS] [SPEED]

Control fan speed on Lenovo ThinkServer SA120 disk shelves.

Options:
  -s, --status       Show current fan speeds without making changes
  -d, --device DEV   Use specific device (default: auto-detect)
  -q, --quiet        Suppress informational output
  -h, --help         Show this help message
...
```

**Pass Criteria:** Help text displays without errors.

---

## Test 2: SA120 Detection

**Purpose:** Verify script can find the SA120 enclosure.

```bash
bash /path/to/fanspeed.sh --status
```

**Expected Output:**
```
Scanning for SA120 enclosure...
Found: /dev/sgX
SA120 Enclosure: /dev/sgX
----------------------------
Fan 0: XXXX RPM
Fan 1: XXXX RPM
Fan 2: XXXX RPM
Fan 3: XXXX RPM
Fan 4: XXXX RPM
Fan 5: XXXX RPM
```

**Pass Criteria:**
- Enclosure detected automatically
- All 6 fan speeds displayed
- No errors

**If Failed:**
- Check SAS cable connections
- Verify SA120 is powered on
- Try `ls /dev/sg*` and `sg_ses /dev/sgX` manually

---

## Test 3: Set Fan Speed

**Purpose:** Verify fan speed can be changed.

```bash
# Note current speeds first
bash /path/to/fanspeed.sh --status

# Set to speed 2
bash /path/to/fanspeed.sh 2
```

**Expected Output:**
```
Scanning for SA120 enclosure...
Found: /dev/sgX

Setting all fans to speed 2 on /dev/sgX...
Fan speed set to 2

Waiting 5 seconds for fans to adjust...
SA120 Enclosure: /dev/sgX
----------------------------
Fan 0: XXXX RPM
Fan 1: XXXX RPM
...
```

**Pass Criteria:**
- No errors during set operation
- Fan RPMs change after setting (may take a few seconds)
- You should hear the fan noise change

**Physical Verification:**
- Listen to the SA120 - fans should be quieter at speed 1-2, louder at 5-6

---

## Test 4: Invalid Speed Handling

**Purpose:** Verify script rejects invalid input.

```bash
# Try invalid speeds
bash /path/to/fanspeed.sh 0
bash /path/to/fanspeed.sh 7
bash /path/to/fanspeed.sh abc
```

**Expected Output:**
```
Error: Speed must be 1-6 (got: 0)
```

**Pass Criteria:** Script exits with error for invalid speeds.

---

## Test 5: Specific Device Flag

**Purpose:** Verify --device flag works.

```bash
# First find your device
bash /path/to/fanspeed.sh --status
# Note the device path (e.g., /dev/sg6)

# Then test with explicit device
bash /path/to/fanspeed.sh --device /dev/sg6 --status
```

**Pass Criteria:** Works with explicit device path.

---

## Test 6: Quiet Mode

**Purpose:** Verify quiet mode suppresses output.

```bash
bash /path/to/fanspeed.sh --quiet 2
echo "Exit code: $?"
```

**Expected Output:**
```
Exit code: 0
```

**Pass Criteria:** No output except exit code 0.

---

## Test 7: Installer Script

**Purpose:** Verify install.sh works correctly.

```bash
# Run installer
sudo bash /path/to/install.sh
```

**Expected Output:**
```
==========================================
SA120 Fan Speed Controller Installer
==========================================

[OK] Running as root
[OK] DSM Version: 7.x.x
[OK] Entware detected
[OK] sg_ses found
[..] Creating /volume1/apps/sa120/...
[..] Installing fanspeed.sh...
[..] Testing SA120 detection...
[OK] SA120 enclosure detected

==========================================
Installation Complete!
==========================================
...
```

**Pass Criteria:**
- All checks pass
- Script installed to `/volume1/apps/sa120/fanspeed.sh`
- Script is executable

**Verify Installation:**
```bash
ls -la /volume1/apps/sa120/
/volume1/apps/sa120/fanspeed.sh --status
```

---

## Test 8: Boot Persistence (Optional)

**Purpose:** Verify fan speed persists after reboot via Task Scheduler.

1. Set up Task Scheduler as described in README
2. Reboot NAS
3. After reboot, check fan speeds:
   ```bash
   /volume1/apps/sa120/fanspeed.sh --status
   ```

**Pass Criteria:** Fans are at the speed configured in Task Scheduler.

---

## Test Summary Checklist

| Test | Description | Pass/Fail |
|------|-------------|-----------|
| 1 | Help displays | [ ] |
| 2 | SA120 detected | [ ] |
| 3 | Fan speed changes | [ ] |
| 4 | Invalid input rejected | [ ] |
| 5 | Device flag works | [ ] |
| 6 | Quiet mode works | [ ] |
| 7 | Installer works | [ ] |
| 8 | Boot persistence | [ ] |

## Reporting Issues

If any tests fail, please report:
1. DSM version (`cat /etc.defaults/VERSION`)
2. Output of failed command
3. Output of `sg_ses /dev/sgX` (replace X with your device)
4. SAS controller model (if known)
