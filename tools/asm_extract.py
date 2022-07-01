import re

target = []
pattern = re.compile(r"^(?P<address>[{0-9a-f]{8}) <(?P<func>.*)>:")
ret_pattern = re.compile(r'(?P<addr>([0-9a-f]+)):\s+[0-9a-f]{8}\s+ret')
last_function_name = ''
last_start_point = 0
with open('temp/asm.asm', 'r') as f:
    for i in f.readlines():
        z = pattern.match(i)
        if z is not None:
            address = z.group("address")
            function_name = z.group("func")
            last_function_name = function_name
            last_start_point = int(address, 16)
        z = ret_pattern(i)
        if z is not None:
            target.append({
                "name": last_function_name,
                "start_point": last_start_point,
                "end_point": int(z.group('addr'), 16)
            })
print(target)