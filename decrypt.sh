# Giả sử bạn có file key là "secret_key_dont_lose_it.key" chứa key hex
DECRYPTION_KEY=$(cat /home/namtn/encrypt/secret_key_dont_lose_it.key)
ENCRYPTED_EXTENSION=".locked"
TARGET_DIR_TO_DECRYPT="/home/namtn/encrypt" # Phải giống với TARGET_DIR khi mã hóa

find "$TARGET_DIR_TO_DECRYPT" -type f -name "*${ENCRYPTED_EXTENSION}" | while read ENCRYPTED_FILE; do
    ORIGINAL_FILE="${ENCRYPTED_FILE%$ENCRYPTED_EXTENSION}" # Xóa phần mở rộng .locked
    
    # Giải mã file
    openssl enc -aes-256-cbc -pbkdf2 -d -in "$ENCRYPTED_FILE" -out "$ORIGINAL_FILE" -k "$DECRYPTION_KEY"
    
    if [ $? -eq 0 ]; then
        echo "Đã giải mã: '$ENCRYPTED_FILE' -> '$ORIGINAL_FILE'"
        # Tùy chọn: Xóa file đã mã hóa sau khi giải mã thành công
        # rm "$ENCRYPTED_FILE"
    else
        echo "LỖI: Giải mã file '$ENCRYPTED_FILE' thất bại." >&2
    fi
done
echo "Hoàn tất quá trình giải mã."
