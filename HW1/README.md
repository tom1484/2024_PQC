```sh
# Generate correct answer for comparison
python test/generate_output.py test/input.txt > test/output.txt

# Build and run (Arm64)
gcc arm/main.c arm/mult256.s -o arm/bin/main
cat test/input.txt | arm/bin/main > arm/output.txt
```
