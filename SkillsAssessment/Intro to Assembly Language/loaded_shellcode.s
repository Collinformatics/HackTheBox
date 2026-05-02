global _start
extern printf, fflush

section .data
	outFormat db  "0x%lx", 0x0a, 0x00

section .text
_start:
	mov rax, 0xa2845c7cdbd7
	push rax
	mov rax, 0x11051084
	push rax
	mov rax, 0x10b29dab6970
	push rax
	mov rax, 0x2ceb0d9645
	push rax
	mov rax, 0xe64ce5108462
	push rax
	mov rax, 0x69cd5c7c3e0c51
	push rax
	mov rax, 0x65652584a185d6
	push rax
	mov rax, 0x69ff6c6c
	push rax
	mov rax, 0x3734a681
	push rax
	mov rax, 0x6af2571e69ff48
	push rax
	mov rax, 0x6d17aff20709e6
	push rax
	mov rax, 0x52315bc9
	push rax
	mov rax, 0x373abb0917
	push rax
	mov rax, 0x69754405a2a3
	push rax
	mov rbx, 0x2144144144
	mov rcx, 15
	
dc:
	pop rdx
	xor rax, rax
	xor rdx, rbx	     ; decode
	mov rdi, outFormat ; set 1st argument (Print Format)
	bswap rdx          ; Reverse order of bytes
	mov rsi, rdx       ; set 2nd argument (value)
	
	push rcx
	call printf
	pop rcx
	dec rcx
  jnz dc

  mov rdi, 0         ; NULL = flush all streams
	call fflush        ; Flushing output allows output to be writen to a file

  mov rax, 60
  mov rdi, 0
  syscall
