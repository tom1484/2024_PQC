# FF000001000FF002000000030000000400000005000000060000000700000008
# FF000002000FF003000000040000000500000006000000070000000800000009
# a = int('000000080000000700000006000000050000000400000003000FF002FF000001', 16)
# b = int('000000090000000800000007000000060000000500000004000FF003FF000002', 16)
a = int('000000080000000700000006000000050000000400000003000FF002FF000001', 16)
b = int('000000090000000800000007000000060000000500000004000FF003FF000002', 16)
c = a * b
h = hex(c)[2:]
h = '0' * (8 - len(h) % 8) + h
while len(h) > 0:
    print(h[-8:])
    h = h[:-8]
