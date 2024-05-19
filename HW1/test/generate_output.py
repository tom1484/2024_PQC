import sys

input_f = open(sys.argv[1], "r")
input_lines = input_f.readlines()

for i in range(0, len(input_lines), 2):
    a = int(input_lines[i][:-1], 16)
    b = int(input_lines[i + 1][:-1], 16)
    c = a * b

    high = c >> 256
    low = c - (high << 256)

    print("%064X" % high)
    print("%064X" % low)
