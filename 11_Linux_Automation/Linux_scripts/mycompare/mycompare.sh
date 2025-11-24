#!/bin/bash


# Monitor-> Problems -> Service problems
## Filter
## Service (regex)
## backup|vault

files=("old_state.txt" "new_state.txt")

for f in ${files[@]}; do
  echo $f
  dos2unix $f
  sed -i 's/.Backup//g' $f
  sed -i 's/.Vault//g' $f
  sed -i 's/Footprint.//g' $f
  sed -i 's/Snapvault//g' $f
  sed -i 's/.Primary//g' $f
  sed -i 's/ //g' $f
  grep -v  '^$' $f > $f.tmp
  cat $f.tmp | sort  --field-separator=':' -k2,2 -k1,1 |uniq  > $f
  rm $f.tmp
done
diff  "old_state.txt" "new_state.txt" | grep -v "^---" | grep -v "^[0-9c0-9]" > Result.txt
cp Result.txt   backup/Result-$(date +"%d.%m.%Y").txt
cat Result.txt | grep ^\< | sed 's/<//g' | sed 's/ //g' >01_vergleichen_old_$(date +"%d.%m.%Y").txt
cat Result.txt | grep ^\> | sed 's/>//g' | sed 's/ //g' >02_vergleichen_new_$(date +"%d.%m.%Y").txt
rm Result.txt
