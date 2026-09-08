"""Deterministic per-student DHCP parameters derived from a student ID.
Both the student's lab instructions and the teacher's marker import this,
so the 'correct answer' is a pure function of the ID - impossible to copy
from another student because their ID yields different required values."""
import hashlib

def student_params(student_id: str) -> dict:
    student_id = student_id.strip().lower()
    h = int(hashlib.sha256(student_id.encode()).hexdigest(), 16)
    # third octet 10..250, network 192.168.<octet>.0/24
    octet = 10 + (h % 200)
    # DHCP pool range within that /24
    pool_start = 50 + (h // 200 % 50)      # .50 .. .99
    pool_end   = pool_start + 100          # +100 hosts
    # one required static reservation: last octet + a MAC derived from ID
    res_ip_last = 200 + (h // 7 % 40)      # .200 .. .239
    mac_tail = format((h >> 8) & 0xFFFFFF, '06x')
    mac = "52:54:00:%s:%s:%s" % (mac_tail[0:2], mac_tail[2:4], mac_tail[4:6])
    # lease time in seconds, one of a few values
    lease = [3600, 7200, 21600, 86400][h % 4]
    return {
        "student_id": student_id,
        "network": f"192.168.{octet}.0",
        "netmask": "255.255.255.0",
        "router":  f"192.168.{octet}.1",
        "pool_start": f"192.168.{octet}.{pool_start}",
        "pool_end":   f"192.168.{octet}.{pool_end}",
        "reservation_ip":  f"192.168.{octet}.{res_ip_last}",
        "reservation_mac": mac,
        "lease_seconds": lease,
    }

if __name__ == "__main__":
    import sys, json
    print(json.dumps(student_params(sys.argv[1]), indent=2))

