#!/data/data/com.termux/files/usr/bin/bash

# ───────── إعدادات ─────────
INPUT_FILE="stonx-mg.txt"
PROGRESS_FILE="uploaded.txt"
FAILED_FILE="failed.txt"

REMOTE="stonx-mg:stonx-mg"
MAX_JOBS=3

LOCK_FILE=".stonx.lock"
COUNTER_FILE=".stonx_counter"

# ───────── ألوان ─────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

OK="✔"
FAIL="✘"
SKIP="—"
ARROW="›"
DOT="•"

# ───────── التحقق من الملفات ─────────
if [ ! -f "$INPUT_FILE" ]; then
  echo -e "${RED}${BOLD}${FAIL} ملف المسارات غير موجود: $INPUT_FILE${NC}"
  exit 1
fi

touch "$PROGRESS_FILE" "$FAILED_FILE"
rclone mkdir "$REMOTE" 2>/dev/null

# ───────── نظام رقم آمن (بدون /tmp نهائياً) ─────────
get_next_number() {
(
  flock 200

  if [ ! -f "$COUNTER_FILE" ]; then
    echo 1 > "$COUNTER_FILE"
  fi

  num=$(cat "$COUNTER_FILE")
  echo $((num + 1)) > "$COUNTER_FILE"

  echo "$num"

) 200>"$LOCK_FILE"
}

# ───────── التحقق من الرفع ─────────
is_uploaded() {
  local file="$1"
  local base=$(basename "$file")

  grep -Fxq "$file" "$PROGRESS_FILE" 2>/dev/null && return 0
  rclone ls "$REMOTE" 2>/dev/null | grep -q "$base" && return 0

  return 1
}

# ───────── رفع ملف ─────────
upload() {
  local file="$1"

  if [ ! -f "$file" ]; then
    echo -e "${YELLOW}${SKIP} غير موجود: $file${NC}"
    return
  fi

  if is_uploaded "$file"; then
    echo -e "${CYAN}${SKIP} مرفوع مسبقاً: $(basename "$file")${NC}"
    return
  fi

  ext="${file##*.}"
  num=$(get_next_number)

  # اسم فريد مضمون 100%
  name="stonx_${num}_$(date +%s%N | tail -c 6).${ext}"

  echo -e "${CYAN}${ARROW} رفع: $name${NC}"

  if rclone copyto "$file" "$REMOTE/$name" --ignore-existing --quiet; then
    (
      flock 200
      echo "$file" >> "$PROGRESS_FILE"
    ) 200>"$LOCK_FILE"

    echo -e "${GREEN}${OK} تم: $name${NC}"
  else
    (
      flock 200
      echo "$file" >> "$FAILED_FILE"
    ) 200>"$LOCK_FILE"

    echo -e "${RED}${FAIL} فشل: $name${NC}"
  fi
}

# ───────── تحميل الملفات ─────────
mapfile -t files < <(grep -v '^$' "$INPUT_FILE")

total=${#files[@]}
echo -e "${CYAN}${BOLD}بدء رفع ${total} ملف${NC}"

i=0

while [ $i -lt $total ]; do
  end=$((i + MAX_JOBS))
  [ $end -gt $total ] && end=$total

  echo -e "\n${DOT} دفعة: $((i+1)) → $end"

  for ((j=i; j<end; j++)); do
    upload "${files[$j]}" &
  done

  wait
  i=$end
done

# ───────── إعادة المحاولة ─────────
if [ -s "$FAILED_FILE" ]; then
  echo -e "\n${YELLOW}إعادة المحاولة...${NC}"

  tmp=$(mktemp)
  cp "$FAILED_FILE" "$tmp"
  > "$FAILED_FILE"

  while read -r f; do
    [ -z "$f" ] && continue
    upload "$f"
  done < "$tmp"

  rm -f "$tmp"
fi

# ───────── إحصائيات ─────────
success=$(wc -l < "$PROGRESS_FILE")
failed=$(wc -l < "$FAILED_FILE")

echo -e "\n${BOLD}──── النتائج ────${NC}"
echo -e "${GREEN}${OK} نجاح: $success${NC}"
echo -e "${RED}${FAIL} فشل: $failed${NC}"
echo -e "${CYAN}${DOT} إجمالي: $total${NC}"

# ───────── آخر ملفات ─────────
echo -e "\nآخر 5 ملفات:"
rclone ls "$REMOTE" 2>/dev/null | tail -5
