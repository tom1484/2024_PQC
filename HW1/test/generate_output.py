import sys
from random import randint

N = int(sys.argv[1])
input_f = open(sys.argv[2], "w")
output_f = open(sys.argv[3], "w")

for i in range(N):
    a = randint(0, 2**256 - 1)
    b = randint(0, 2**256 - 1)

    input_f.write("%064X\n" % a)
    input_f.write("%064X\n" % b)

    c = a * b
    high = c >> 256
    low = c - (high << 256)

    output_f.write("%064X\n" % high)
    output_f.write("%064X\n" % low)
