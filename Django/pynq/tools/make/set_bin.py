src = [
    0x000080b7
]

def extend(s):
    b = s
    if len(s) < 32:
        b = (32 - len(b)) * '0' + b
    return b

def extend_bin(s):
    a = bin(s)[2:]
    return extend(a)

with open('bin.coe', 'w') as f, open('main.bin', 'rb') as g:
    f.write('memory_initialization_radix = 16;\nmemory_initialization_vector =\n')
    i = 0
    while(True):
        s = g.read(4)[::-1]
        if s:
            f.write(s.hex())
            f.write(',\n')
        else:
            f.write(';')
            break
        

