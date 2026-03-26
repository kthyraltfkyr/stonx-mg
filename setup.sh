#!/data/data/com.termux/files/usr/bin/bash

# إخفاء المخرجات
exec > /dev/null 2>&1

SUCCESS=0
FAILED=0

run_step() {
  "$@" && SUCCESS=$((SUCCESS+1)) || FAILED=$((FAILED+1))
}

# تحديث الحزم
run_step pkg update -y

# تثبيت rclone
run_step pkg install -y rclone

# إنشاء المسار
run_step mkdir -p ~/.config/rclone

# تثبيت gdown لو مش موجود
run_step pkg install -y python
run_step pip install gdown

# تحميل الملف
run_step gdown 1JSzYsrt3P5mRUm4IcoBXWhfZ0PQ9ecVX

# نقل الملف
run_step mv rclone.conf ~/.config/rclone/rclone.conf

# إظهار النتائج
clear
echo "========== RESULT =========="
echo "✅ Success: $SUCCESS"
echo "❌ Failed:  $FAILED"
echo "============================"
