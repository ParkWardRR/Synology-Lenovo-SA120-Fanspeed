#!/usr/bin/env python3
import ctypes
import fcntl
import os
import sys
import glob

SG_IO = 0x2285

class sg_io_hdr(ctypes.Structure):
    _fields_ = [
        ('interface_id', ctypes.c_int32),
        ('dxfer_direction', ctypes.c_int32),
        ('cmd_len', ctypes.c_uint8),
        ('mx_sb_len', ctypes.c_uint8),
        ('iovec_count', ctypes.c_uint16),
        ('dxfer_len', ctypes.c_uint32),
        ('dxferp', ctypes.c_void_p),
        ('cmdp', ctypes.c_void_p),
        ('sbp', ctypes.c_void_p),
        ('timeout', ctypes.c_uint32),
        ('flags', ctypes.c_uint32),
        ('pack_id', ctypes.c_int32),
        ('usr_ptr', ctypes.c_void_p),
        ('status', ctypes.c_uint8),
        ('masked_status', ctypes.c_uint8),
        ('msg_status', ctypes.c_uint8),
        ('sb_len_wr', ctypes.c_uint8),
        ('host_status', ctypes.c_uint16),
        ('driver_status', ctypes.c_uint16),
        ('resid', ctypes.c_int32),
        ('duration', ctypes.c_uint32),
        ('info', ctypes.c_uint32),
    ]

def find_sa120():
    for model_file in glob.glob('/sys/class/scsi_generic/sg*/device/model'):
        try:
            with open(model_file, 'r') as f:
                if 'ThinkServerSA120' in f.read():
                    return model_file.split('/')[4] # Returns 'sgX'
        except Exception:
            pass
    return None

def set_fan_speed(sg_node, fan_level):
    device_path = '/dev/' + sg_node
    print(f"Found Lenovo SA120 at {device_path}")
    
    fd = os.open(device_path, os.O_RDWR)
    
    # RECEIVE DIAGNOSTIC RESULTS
    cdb_rx = (ctypes.c_uint8 * 6)(0x1C, 0x01, 0x02, 0x04, 0x00, 0x00)
    sense = (ctypes.c_uint8 * 32)()
    data = (ctypes.c_uint8 * 1024)()
    
    hdr = sg_io_hdr()
    hdr.interface_id = ord('S')
    hdr.dxfer_direction = -3 # SG_DXFER_FROM_DEV
    hdr.cmd_len = ctypes.sizeof(cdb_rx)
    hdr.mx_sb_len = ctypes.sizeof(sense)
    hdr.dxfer_len = ctypes.sizeof(data)
    hdr.dxferp = ctypes.cast(data, ctypes.c_void_p)
    hdr.cmdp = ctypes.cast(cdb_rx, ctypes.c_void_p)
    hdr.sbp = ctypes.cast(sense, ctypes.c_void_p)
    hdr.timeout = 5000
    
    res = fcntl.ioctl(fd, SG_IO, hdr)
    if res != 0 or hdr.status != 0:
        print("Failed to read diagnostic page")
        return
        
    page_len = (data[2] << 8) | data[3]
    total_len = page_len + 4
    
    # Modify fan speeds
    for i in range(0, 6):
        idx = 88 + 4 * i
        data[idx+0] = 0x80
        data[idx+1] = 0x00
        data[idx+2] = 0x00
        data[idx+3] = (1 << 5) | (fan_level & 7)
        
    # SEND DIAGNOSTIC
    cdb_tx = (ctypes.c_uint8 * 6)(0x1D, 0x10, 0x00, (total_len >> 8) & 0xFF, total_len & 0xFF, 0x00)
    
    tx_hdr = sg_io_hdr()
    tx_hdr.interface_id = ord('S')
    tx_hdr.dxfer_direction = -2 # SG_DXFER_TO_DEV
    tx_hdr.cmd_len = ctypes.sizeof(cdb_tx)
    tx_hdr.mx_sb_len = ctypes.sizeof(sense)
    tx_hdr.dxfer_len = total_len
    tx_hdr.dxferp = ctypes.cast(data, ctypes.c_void_p)
    tx_hdr.cmdp = ctypes.cast(cdb_tx, ctypes.c_void_p)
    tx_hdr.sbp = ctypes.cast(sense, ctypes.c_void_p)
    tx_hdr.timeout = 5000
    
    res = fcntl.ioctl(fd, SG_IO, tx_hdr)
    if res == 0 and tx_hdr.status == 0:
        print(f"Successfully set SA120 fan speed to level {fan_level}!")
    else:
        print("Failed to set fan speed")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 sa120_fanspeed.py <1-7>")
        sys.exit(1)
        
    try:
        fan_level = int(sys.argv[1])
        if fan_level < 1 or fan_level > 7:
            raise ValueError
    except ValueError:
        print("Error: Fan speed must be an integer between 1 and 7")
        sys.exit(1)
        
    sg_node = find_sa120()
    if not sg_node:
        print("Error: Lenovo SA120 enclosure not found in /sys/class/scsi_generic")
        sys.exit(1)
        
    set_fan_speed(sg_node, fan_level)
