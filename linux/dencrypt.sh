#!/bin/bash

# Dừng script ngay khi có lỗi
set -e

# ========================= CÀI ĐẶT =========================
# Các cài đặt này PHẢI KHỚP với file encrypt.sh
RANSOM_NOTE="_FILES_ENCRYPTED_.txt"
EXTENSION=".drill"

# File chứa key sẽ được xác định bằng tên máy tính (hostname)
HOSTNAME_VAR=$(hostname)
INFO_FILE="${HOSTNAME_VAR}.txt"

# Cung cấp thư mục đích cần giải mã
TARGET_DIR="/home/namtn/encrypt"
# ==========================================================

# Kiểm tra xem OpenSSL đã được cài đặt chưa
if ! command -v openssl &> /dev/null; then
    echo "[LỖI] OpenSSL không được tìm thấy. Vui lòng cài đặt OpenSSL."
    exit 1
fi

# Kiểm tra xem thư mục đích có tồn tại không
if [ ! -d "$TARGET_DIR" ]; then
    echo "[LỖI] Thư mục đích \"$TARGET_DIR\" không tồn tại."
    exit 1
fi

# Chuyển đến thư mục đích
cd "$TARGET_DIR"

# Kiểm tra sự tồn tại của file chứa thông tin và key
if [ ! -f "$INFO_FILE" ]; then
    echo "[LỖI] Không tìm thấy file thông tin/key \"$INFO_FILE\" trong thư mục này."
    echo "Vui lòng đặt file \"$INFO_FILE\" vào thư mục \"$TARGET_DIR\" để tiếp tục."
    exit 1
fi

# 1. Đọc key từ dòng cuối cùng của file $HOSTNAME.txt
echo "[INFO] Đang đọc key từ file: $INFO_FILE"
KEY=$(grep . "$INFO_FILE" | tail -n 1)

# Kiểm tra xem key có được đọc thành công không
if [ -z "$KEY" ]; then
    echo "[LỖI] Không thể đọc key từ file (dòng cuối cùng trống hoặc file bị lỗi)."
    exit 1
fi
echo "[INFO] Đã đọc key thành công."

# 2. Giải mã file và 3. Xóa file đã mã hóa
echo "[INFO] Bắt đầu quá trình giải mã..."
found_files=0

# *** THAY ĐỔI QUAN TRỌNG NẰM Ở ĐÂY ***
# Sử dụng Process Substitution để tránh tạo subshell cho vòng lặp while
while IFS= read -r -d $'\0' file; do
    found_files=1
    original_file="${file%$EXTENSION}"
    echo "  -> Đang giải mã: $file"
    
    openssl enc -d -aes-256-cbc -in "$file" -out "$original_file" -pass pass:"$KEY" -pbkdf2 && rm "$file"
done < <(find . -type f -name "*$EXTENSION" -print0)


# Bây giờ, câu lệnh if sẽ hoạt động đúng
if [ "$found_files" -eq 0 ]; then
    echo "[INFO] Không tìm thấy file nào có đuôi \"$EXTENSION\" để giải mã."
else
    echo
    echo "[HOÀN TẤT] Quá trình giải mã và dọn dẹp đã hoàn thành."
fi