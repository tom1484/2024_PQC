```sh
# Generate correct answer for comparison
python test.py > output_test.txt
# Build and run
gcc main.c mult256.s -o bin/main && cat input.txt | ./bin/main > output.txt
```
