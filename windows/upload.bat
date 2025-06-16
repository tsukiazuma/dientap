@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: CẤU HÌNH - VUI LÒNG THAY ĐỔI CÁC GIÁ TRỊ DƯỚI ĐÂY
:: =================================================================

:: 1. Token truy cập cá nhân của bạn. 
::    Tạo tại: https://github.com/settings/tokens
SET GITHUB_TOKEN=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

:: 2. Tên người dùng hoặc tổ chức trên GitHub
SET GITHUB_OWNER=tsukiazuma

:: 3. Tên repository
SET GITHUB_REPO=dientap

:: 4. (Tùy chọn) Đường dẫn trong repo nơi bạn muốn lưu file.
::    Để trống nếu muốn lưu ở thư mục gốc. Ví dụ: "data/"
SET PATH_IN_REPO=

:: =================================================================
:: KỊCH BẢN TỰ ĐỘNG - KHÔNG CẦN CHỈNH SỬA PHẦN DƯỚI NÀY
:: =================================================================

echo [1/6] Chuan bi bien moi truong...

:: Tên file sẽ được upload, dựa trên tên máy tính
SET FILENAME=%COMPUTERNAME%.txt
SET FULL_PATH_IN_REPO=%PATH_IN_REPO%%FILENAME%

:: Các file tạm
SET LOCAL_CONTENT_FILE=%FILENAME%
SET BASE64_TEMP_FILE=base64_content.tmp
SET PAYLOAD_FILE=payload.json
SET API_RESPONSE_FILE=api_response.json

:: URL của API GitHub
SET API_URL=https://api.github.com/repos/%GITHUB_OWNER%/%GITHUB_REPO%/contents/%FULL_PATH_IN_REPO%

echo    + Ten file: %FILENAME%
echo    + URL API: %API_URL%

echo.
echo [3/6] Ma hoa noi dung sang Base64...
:: Sử dụng certutil để mã hóa, nó có sẵn trên Windows
certutil -encode %LOCAL_CONTENT_FILE% %BASE64_TEMP_FILE% > nul

:: Đọc nội dung file base64 và loại bỏ các dòng header/footer
set "BASE64_CONTENT="
for /f "tokens=* delims=" %%a in ('type %BASE64_TEMP_FILE% ^| findstr /v /c:"CERTIFICATE"') do (
    set "BASE64_CONTENT=!BASE64_CONTENT!%%a"
)
echo    + Ma hoa thanh cong.

echo.
echo [4/6] Kiem tra file da ton tai tren GitHub de lay SHA...
:: Lấy thông tin file hiện tại (nếu có) để lấy SHA cho việc cập nhật
curl -s -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer %GITHUB_TOKEN%" "%API_URL%" -o %API_RESPONSE_FILE%

:: Tìm và trích xuất SHA từ file JSON trả về
set "FILE_SHA="
for /f "tokens=2 delims=:," %%s in ('type %API_RESPONSE_FILE% ^| findstr /i "\"sha\""') do (
    set "sha_temp=%%s"
    set "sha_temp=!sha_temp:"=!"
    set "sha_temp=!sha_temp: =!"
    set "FILE_SHA=!sha_temp!"
    goto :found_sha
)
:found_sha

echo.
echo [5/6] Tao JSON payload de gui len API...
IF DEFINED FILE_SHA (
    echo    + File da ton tai. Se thuc hien cap nhat. SHA: !FILE_SHA!
    (
        echo {
        echo   "message": "Update %FILENAME% via API",
        echo   "content": "!BASE64_CONTENT!",
        echo   "sha": "!FILE_SHA!"
        echo }
    ) > %PAYLOAD_FILE%
) ELSE (
    echo    + File chua ton tai. Se thuc hien tao moi.
    (
        echo {
        echo   "message": "Create %FILENAME% via API",
        echo   "content": "!BASE64_CONTENT!"
        echo }
    ) > %PAYLOAD_FILE%
)
echo    + Da tao file '%PAYLOAD_FILE%'.

echo.
echo [6/6] Goi API de upload file...
curl -s -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer %GITHUB_TOKEN%" -d @%PAYLOAD_FILE% "%API_URL%"

echo.
echo =================================================================
echo HOAN THANH!
echo Vui long kiem tra repository cua ban:
echo https://github.com/%GITHUB_OWNER%/%GITHUB_REPO%/
echo =================================================================

:: Dọn dẹp các file tạm
del %LOCAL_CONTENT_FILE% > nul 2>&1
del %BASE64_TEMP_FILE% > nul 2>&1
del %PAYLOAD_FILE% > nul 2>&1
del %API_RESPONSE_FILE% > nul 2>&1

endlocal
pause