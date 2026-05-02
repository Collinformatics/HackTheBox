#!/bin/python3

import argparse
from pwn import *

parser = argparse.ArgumentParser(description="Execute Shellcode.")
parser.add_argument("-i", "--interactive", action="store_true", 
                    help="Exeucte in interactive mode.")
parser.add_argument("-s", "--shellcode", type=str, 
                    help="Shellcode in hexadecimal format.")
args = parser.parse_args()
iMode = args.interactive
shellcode = args.shellcode

#context(os="linux", arch="amd64")
context(os="linux", arch="amd64", log_level="error")

try:
	int(shellcode, 16)
except ValueError:
	print('ERROR: The input is not a hexadecimal string')
	import sys
	sys.exit()

if iMode:
	run_shellcode(unhex(shellcode)).interactive()
else:
	p = run_shellcode(unhex(shellcode), arch='amd64')
	p.wait_for_close()
	p.poll()
	output = p.recvall()
	print(f'Output:\n{output.decode()}')
