#!/bin/bash

# Dừng script ngay lập tức nếu có lệnh nào thất bại
set -e

# =================================================================
# CẤU HÌNH - VUI LÒNG THAY ĐỔI CÁC GIÁ TRỊ DƯỚI ĐÂY
# =================================================================

# 1. Token truy cập cá nhân của bạn. 
#    Tạo tại: https://github.com/settings/tokens
GITHUB_TOKEN="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"

# 2. Tên người dùng hoặc tổ chức trên GitHub
GITHUB_OWNER="tsukiazuma"

# 3. Tên repository
GITHUB_REPO="dientap"

# 4. (Tùy chọn) Đường dẫn trong repo nơi bạn muốn lưu file.
#    Để trống nếu muốn lưu ở thư mục gốc. Phải kết thúc bằng dấu "/". Ví dụ: "data/"
PATH_IN_REPO=""

# =================================================================
# KỊCH BẢN TỰ ĐỘNG - KHÔNG CẦN CHỈNH SỬA PHẦN DƯỚI NÀY
# =================================================================

echo "[1/6] Chuẩn bị biến môi trường..."

# Kiểm tra xem jq đã được cài đặt chưa
if ! command -v jq &> /dev/null; then
    echo "LỖI: Lệnh 'jq' không được tìm thấy."
    echo "Vui lòng cài đặt jq để chạy script này (ví dụ: sudo apt-get install jq)."
    exit 1
fi

# Tên file sẽ được upload, dựa trên tên máy tính
FILENAME="$(hostname).txt"
FULL_PATH_IN_REPO="${PATH_IN_REPO}${FILENAME}"

# URL của API GitHub
API_URL="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/${FULL_PATH_IN_REPO}"

echo "    + Tên file: ${FILENAME}"
echo "    + URL API: ${API_URL}"

echo
echo "[2/6] Tạo file nội dung local..."
# Tạo nội dung cho file
echo "File được upload từ máy $(hostname) vào lúc: $(date)" > "${FILENAME}"
echo "    + Đã tạo file '${FILENAME}'."

echo
echo "[3/6] Mã hóa nội dung sang Base64..."
# Mã hóa file sang Base64. -w 0 để đảm bảo không có ngắt dòng.
BASE64_CONTENT=$(base64 -w 0 "${FILENAME}")
echo "    + Mã hóa thành công."

echo
echo "[4/6] Kiểm tra file đã tồn tại trên GitHub để lấy SHA..."
# Lấy thông tin file hiện tại (nếu có) bằng curl và trích xuất SHA bằng jq
# curl -s sẽ ẩn thanh tiến trình, -f sẽ báo lỗi nếu HTTP status code là lỗi (ví dụ 404)
# || true để script không bị dừng nếu file không tồn tại (lỗi 404)
API_RESPONSE=$(curl -s -H "Authorization: Bearer ${GITHUB_TOKEN}" "${API_URL}" || true)
FILE_SHA=$(echo "${API_RESPONSE}" | jq -r '.sha // ""')

echo
echo "[5/6] Tạo JSON payload để gửi lên API..."
if [ -n "${FILE_SHA}" ]; then
    echo "    + File đã tồn tại. Sẽ thực hiện cập nhật. SHA: ${FILE_SHA}"
    COMMIT_MESSAGE="Update ${FILENAME} via API"
    JSON_PAYLOAD=$(cat <<EOF
{
  "message": "${COMMIT_MESSAGE}",
  "content": "${BASE64_CONTENT}",
  "sha": "${FILE_SHA}"
}
EOF
)
else
    echo "    + File chưa tồn tại. Sẽ thực hiện tạo mới."
    COMMIT_MESSAGE="Create ${FILENAME} via API"
    JSON_PAYLOAD=$(cat <<EOF
{
  "message": "${COMMIT_MESSAGE}",
  "content": "${BASE64_CONTENT}"
}
EOF
)
fi
echo "    + Đã tạo payload."

echo
echo "[6/6] Gọi API để upload file..."
# Gửi yêu cầu PUT đến GitHub API
RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -d "${JSON_PAYLOAD}" \
  "${API_URL}")

echo
echo "================================================================="
if [[ ${RESPONSE_CODE} -eq 200 || ${RESPONSE_CODE} -eq 201 ]]; then
    echo "HOÀN THÀNH! File đã được upload/cập nhật thành công (Status Code: ${RESPONSE_CODE})."
    echo "Vui lòng kiểm tra repository của bạn:"
    echo "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/blob/main/${FULL_PATH_IN_REPO}"
else
    echo "THẤT BẠI! Đã xảy ra lỗi khi gọi API (Status Code: ${RESPONSE_CODE})."
    echo "Vui lòng kiểm tra lại Token, tên Owner/Repo và các quyền truy cập."
fi
echo "================================================================="

# Dọn dẹp file tạm
rm -f "${FILENAME}"