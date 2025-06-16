@echo off
setlocal enabledelayedexpansion

REM Xoa file info.txt cu neu co va tao file moi voi tieu de
echo THONG TIN HE THONG (WINDOWS) > info.txt
echo Chay vao luc: %date% %time% >> info.txt
echo ============================================== >> info.txt
echo. >> info.txt

echo Dang thu thap thong tin... Vui long cho.

REM --- 1, 2 & 3. Thong tin OS, phien ban va ban va ---
echo [1, 2, 3] THONG TIN HE DIEU HANH, PHIEN BAN VA BAN VA >> info.txt
echo --------------------------------------------------- >> info.txt
REM systeminfo la lenh manh me nhat de lay cac thong tin nay
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" /C:"System Type" /C:"Hotfix(s)" >> info.txt
echo. >> info.txt

REM --- 4. Danh sach tai khoan va quyen quan tri ---
echo [4] TAI KHOAN NGUOI DUNG VA QUYEN QUAN TRI >> info.txt
echo -------------------------------------------- >> info.txt
echo --- Tat ca tai khoan nguoi dung (Local): >> info.txt
net user >> info.txt
echo. >> info.txt
echo --- Tai khoan co quyen Quan tri (Members of Administrators group): >> info.txt
net localgroup Administrators >> info.txt
echo. >> info.txt

REM --- 5. Ten may chu va thong tin Domain ---
echo [5] TEN MAY CHU (HOSTNAME) VA DOMAIN >> info.txt
echo -------------------------------------- >> info.txt
echo Hostname: %COMPUTERNAME% >> info.txt
echo Domain: %USERDOMAIN% >> info.txt
REM Neu khong trong domain, %USERDOMAIN% thuong se la ten may
echo. >> info.txt

echo.
echo HOAN TAT!
echo Da luu toan bo thong tin vao file "info.txt".
echo Ban co the mo file do de xem ket qua.
echo.
pause