```sh
# Generate correct answer for comparison
python test/generate_output.py test/input.txt > test/output.txt

# Build and run (arm64 - MacOS)
mkdir arm64/bin
gcc arm64/main.c arm64/mult256.s -o arm64/bin/main
cat test/input.txt | arm64/bin/main > arm64/output.txt

# Build and run (aarch64 - RPi)
mkdir aarch64/bin
gcc aarch64/main.c aarch64/mult256.s -o aarch64/bin/main
cat test/input.txt | aarch64/bin/main > aarch64/output.txt
```
