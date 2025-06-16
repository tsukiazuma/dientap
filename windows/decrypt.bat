@echo off
setlocal enabledelayedexpansion

:: ========================= CÀI ĐẶT =========================
:: Các cài đặt này PHẢI KHỚP với file mã hóa
set "EXTENSION=.drill"

:: File chứa key sẽ được xác định bằng tên máy tính (hostname)
set "INFO_FILE=%COMPUTERNAME%.txt"

:: Cung cấp thư mục đích cần giải mã
set "TARGET_DIR=D:\NamTN\2025\Ransomware drill\Ransomware\Encrypt"
:: ==========================================================

:: Kiểm tra xem OpenSSL đã được cài đặt chưa
where openssl >nul 2>nul
if %errorlevel% neq 0 (
    echo [LOI] OpenSSL khong duoc tim thay. Vui long cai dat OpenSSL va them vao bien PATH.
    pause
    exit /b 1
)

:: Kiểm tra xem thư mục đích có tồn tại không
if not exist "%TARGET_DIR%\" (
    echo [LOI] Thu muc dich "%TARGET_DIR%" khong ton tai.
    pause
    exit /b 1
)

:: Chuyển đến thư mục đích
pushd "%TARGET_DIR%"

:: Kiểm tra sự tồn tại của file chứa thông tin và key
if not exist "%INFO_FILE%" (
    echo [LOI] Khong tim thay file thong tin/key "%INFO_FILE%".
    echo Vui long dat file "%INFO_FILE%" vao thu muc "%TARGET_DIR%" de tiep tuc.
    popd
    pause
    exit /b 1
)

:: ========================= ĐỌC KEY TỪ FILE =========================
:: Day la phan da duoc sua de xu ly file .txt cua ban
echo [INFO] Dang doc key tu file "%INFO_FILE%"...
set "key="

REM Vong lap nay doc qua tung dong cua file.
REM Vi for /f bo qua cac dong trong, gia tri cuoi cung ma bien "key" nhan duoc
REM se la dong text cuoi cung trong file, chinh la key ma hoa.
for /f "usebackq delims=" %%L in ("%INFO_FILE%") do (
    set "key=%%L"
)

:: Kiểm tra xem key có được đọc thành công không
if not defined key (
    echo [LOI] Khong the doc duoc key tu file "%INFO_FILE%". File co the bi trong hoac loi.
    popd
    pause
    exit /b 1
)
echo [INFO] Da doc key thanh cong.

:: ========================= TIẾN HÀNH GIẢI MÃ =========================
echo [INFO] Bat dau qua trinh giai ma...
set "found_files=0"
for /r "%TARGET_DIR%" %%F in (*%EXTENSION%) do (
    set "found_files=1"
    
    :: Lấy tên file gốc bằng cách loại bỏ đuôi extension
    set "original_file=%%~dpnF"
    
    :: Lệnh giải mã phải tương ứng với lệnh mã hóa
    openssl enc -d -aes-256-cbc -in "%%F" -out "!original_file!" -pass pass:!key! -pbkdf2
    
    :: Nếu giải mã thành công, xóa file mã hóa
    if !errorlevel! equ 0 (
        echo [OK] Da giai ma thanh cong: "%%~nxF"
        del /F /Q "%%F"
    ) else (
        echo [LOI] Giai ma file "%%F" that bai. Co the key sai hoac file bi hong.
    )
)

if "%found_files%"=="0" (
    echo [INFO] Khong tim thay file nao co duoi "%EXTENSION%" de giai ma.
) else (
    echo.
    echo [HOAN TAT] Qua trinh giai ma va don dep da hoan thanh.
)

popd
pause