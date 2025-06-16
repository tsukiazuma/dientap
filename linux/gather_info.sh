#!/bin/bash

# Xoa file info.txt cu neu co va tao file moi voi tieu de
echo "THONG TIN HE THONG (LINUX/MACOS)" > info.txt
echo "Chay vao luc: $(date)" >> info.txt
echo "==============================================" >> info.txt
echo "" >> info.txt

echo "Dang thu thap thong tin... Vui long cho."

# --- 1, 2 & 3. Thong tin OS, phien ban va ban va ---
echo "[1, 2, 3] THONG TIN HE DIEU HANH, PHIEN BAN & BAN VA" >> info.txt
echo "---------------------------------------------------" >> info.txt
OS_TYPE=$(uname)
if [ "$OS_TYPE" = "Linux" ]; then
    # Su dung /etc/os-release de co thong tin chi tiet tren hau het cac distro Linux
    if [ -f /etc/os-release ]; then
        cat /etc/os-release >> info.txt
    else
        # Fallback cho he thong cu
        uname -a >> info.txt
    fi
elif [ "$OS_TYPE" = "Darwin" ]; then
    # Su dung sw_vers cho macOS
    sw_vers >> info.txt
fi
# Kernel version la mot chi so tot cho cap do ban va
echo "Kernel Version (Patch Level): $(uname -r)" >> info.txt
echo "" >> info.txt


# --- 4. Danh sach tai khoan va quyen quan tri ---
echo "[4] TAI KHOAN NGUOI DUNG VA QUYEN QUAN TRI" >> info.txt
echo "--------------------------------------------" >> info.txt
echo "--- Tat ca tai khoan nguoi dung (Local):" >> info.txt
cut -d: -f1 /etc/passwd >> info.txt
echo "" >> info.txt
echo "--- Tai khoan co quyen Quan tri (sudo/wheel group members):" >> info.txt
# Tren Debian/Ubuntu thuong la group 'sudo', tren RHEL/CentOS/macOS la 'wheel'
# Ghi chu: Tai khoan 'root' luon co toan quyen.
grep -E '^sudo|^wheel' /etc/group | sed 's/$/,/g' >> info.txt
echo "(Luu y: Tai khoan 'root' luon co quyen quan tri cao nhat)" >> info.txt
echo "" >> info.txt


# --- 5. Ten may chu va thong tin Domain ---
echo "[5] TEN MAY CHU (HOSTNAME) VA DOMAIN" >> info.txt
echo "--------------------------------------" >> info.txt
echo "Hostname: $(hostname)" >> info.txt
echo -n "Domain Info (from /etc/resolv.conf): " >> info.txt
# Tim dong 'search' hoac 'domain' trong file resolv.conf
grep -E '^search|^domain' /etc/resolv.conf >> info.txt || echo "Not configured" >> info.txt
echo "" >> info.txt

echo ""
echo "HOAN TAT!"
echo "Da luu toan bo thong tin vao file \"info.txt\"."