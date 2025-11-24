sed: How to remove entire line matching specific string?

sed '/DNW/d' sample.txt >> output.txt
grep -v DNW sample.txt >> output.txt
awk '!/DNW/' file

# If you want to do it in Python, it's a lot more verbose, but not actually much harder:
with open('sample.txt') as fin, open('output.txt', 'a') as fout:
    for line in fin:
        if 'DNW' not in line:
            fout.write(fin)

