# This file define some PYNQ LIBRARY method

import os, subprocess, sys, re
from pathlib import Path
from pynq import Overlay

BASE_DIR = Path(__file__).resolve().parent.parent

PATH = BASE_DIR / 'tools/make'

SOURCE_FILE_NAME = ['main.c', 'main.cpp', 'main.asm']

base = None
mem = None
rst_rv = None
rst_trace = None
trace = None

def init():
    global base, mem, rst_rv, rst_trace, trace
    base = Overlay(str(BASE_DIR / 'onboard.bit'))
    mem = base.axi_bram_ctrl_1
    rst_rv = base.axi_gpio_0
    rst_trace = base.axi_gpio_1
    trace = base.function_trace_0
    

def store(src, src_type):

    for i in os.listdir(PATH):
        if os.path.isfile(i) and i in SOURCE_FILE_NAME:
            os.remove(PATH + i)

    if src_type == 'C':
        file_name = 'main.c'
    elif src_type == 'CPP':
        file_name = 'main.cpp'
    elif src_type == 'ASM':
        file_name = 'main.S'
    else:
        return

    with open(PATH / file_name, 'w') as f:
        f.write(src)

def mark():
    input_array = []
    return_array = []
    pattern = re.compile(r"^(?P<address>[{0-9a-f]{8}) <(?P<func>.*)>:")
    ret_pattern = re.compile(r'(?P<addr>([0-9a-f]+)):\s+[0-9a-f]{8}\s+ret')
    last_function_name = ''
    last_start_point = 0
    with open(PATH / 'asm.asm', 'r') as f:
        for i in f.readlines():
            z = pattern.match(i)
            if z is not None:
                address = z.group("address")
                function_name = z.group("func")
                last_function_name = function_name
                last_start_point = int(address, 16)
            z = ret_pattern.search(i)
            if z is not None:
                input_array.append(last_start_point)
                input_array.append(int(z.group('addr'), 16))
                return_array.append({'name': last_function_name, 'type': 'start'})
                return_array.append({'name': last_function_name, 'type': 'end'})
    return {'input': input_array, 'response': return_array}

def make():
    compile_path = BASE_DIR / 'tools/toolchain/bin'
    with open('a.log', 'w') as f, open('b.log', 'w') as g:
        subprocess.run(f'export PATH={BASE_DIR}/tools/xpack-riscv-none-elf-gcc-12.1.0-2/bin:$PATH;make', stdout=f, stderr=g, shell=True, cwd=PATH)
    feedback = {}
    with open('a.log', 'r') as f, open('b.log', 'r') as g:
        err = g.read()
        if(err == ''):
            feedback['compile_feedback'] = 'Building Successful'
            feedback['code'] = 0
        else:
            feedback['compile_feedback'] = err
            feedback['code'] = 1
    return feedback

def build(src, src_type):
    store(src, src_type)
    return make()

def upload():
    base.load_ip_data('axi_bram_ctrl_1', PATH / 'main.bin')

def run():
    # Upload trace list
    u = mark()
    rst_trace.channel1.write(0, 0x1)
    rst_rv.channel1.write(0, 0x1)
    rst_trace.channel1.write(1, 0x1)
    print(u['input'])
    for i in u['input']:
        trace.S_AXI.write(0x4, i)
    trace.S_AXI.write(0x0, 1)
    rst_rv.channel1.write(1, 0x1)
    return u['response']

def read_trace():
    ret = [];
    while(trace.S_AXI.read(0x14) != 0):
        t_perf= trace.S_AXI.read(0x8)
        t_sym = trace.S_AXI.read(0xc)
        ret.append({'id': t_sym, 't': t_perf})
    return ret

if __name__ == '__main__':
    init()
    upload()
    print(run())
    print(read_trace())