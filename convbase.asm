SECTION .data	
	msgb 	db	'Conversor de bases em x64 Assembly (NASM)', 10, 'Organização e Arquitetura de Sistemas', 10, 'Aluno: Heitor Benedetti Lopes, RA 2840482421003', 10, 10, 0

	msgi1 	db 	'Digite o número que deseja converter: ', 0
	
	msgi2	db	'Digite a base desse número: ', 0
	
	msgi3	db	'Agora, digite para qual base o deseja converter: ', 0
	
	stdin	equ	0
	stdout	equ	1
	stderr	equ	2
	
SECTION .bss
digtoconv:	resb	128 			;named block "digtoconv", 2048 bytes long
digbasein:	resb	128
digbaseout:	resb 	128

digdest:	resb 	128

SECTION .text

global _start

_start:

	push retmsg1
	push msgb

	jmp strlen_start
retmsg1:
	push retmsg2
	push rcx
	push msgb

	jmp writeout

retmsg2:
	push retmsg3
	push msgi1

	jmp strlen_start
retmsg3:
	push ret1
	push rcx
	push msgi1

	jmp writeout
ret1:	
	push retmsg4
	push 128
	push digtoconv

	jmp inuser
retmsg4:
	push retmsg5
	push msgi2

	jmp strlen_start
retmsg5:
	push ret2
	push rcx
	push msgi2

	jmp writeout
ret2:
	push retmsg6
	push 128
	push digbasein

	jmp inuser
retmsg6:
	push retmsg7
	push msgi3

	jmp strlen_start
retmsg7:
	push ret3
	push rcx
	push msgi3

	jmp writeout
ret3:
	push ret4
	push 128
	push digbaseout

	jmp inuser
ret4:
	push ret5
	push 10
	push digbasein

	jmp strtoquad
ret5:
	mov r14, rcx

	push ret6
	push 10
	push digbaseout

	jmp strtoquad
;;; Determine destination bases
ret6:
	mov r15, rcx

	cmp r14, 2
	jl reterr

	cmp r15, 2
	jl reterr

	cmp r14, 16
	jg reterr

	je ret6_conv16to10

	jmp ret6_convXto10
ret6_conv16to10:
	push ret7
	push digtoconv

	jmp strtoquad_hex_fast
ret6_convXto10:
	push ret7
	push r14
	push digtoconv

	jmp strtoquad
ret7:	
	push ret8
	push r15
	push digdest
	push rcx

	jmp base10tons
ret8:
	push ret9
	push digdest

	jmp strlen_start
ret9:
	push ret10
	push rcx
	push digdest

	jmp writeout
ret10:
	jmp exit
reterr:
	jmp exit

;; LABEL strlen(a -> rsi buf, rcx <- count)
;; b -> rax ret
strlen_start:
	pop rsi
	mov rcx, 0
strlen:
	cmp byte [rsi], 0
	jz strlen_end

	inc rsi
	inc rcx

	jmp strlen
strlen_end:
	pop rax
	jmp rax
	
;; LABEL inuser(rdi set as fd const stdin, a -> rsi buf, b -> rdx count)
;; c -> rax ret
inuser:
	;; sys_read
	mov rdi, stdin
	pop rsi
	pop rdx

	mov rax, 0
	syscall

	pop rax
	jmp rax
	
;; LABEL writeout(rdi set as fd const stdout, a -> rsi buf, b -> rdx count)
;; c -> rax ret
writeout:
	;; sys_write
	mov rdi, stdout
	pop rsi
	pop rdx

	mov rax, 1
	syscall

	pop rax
	jmp rax
	
;;; LABEL base10tons(a -> r9 no, b -> rsi buf, c -> r8 base)
;;; d -> rax ret
base10tons:
	pop r9 			;r9 is later used to retrieve remainders from the stack
	pop rsi
	pop r8

	mov rax, r9
	mov r10, 0		;used as a counter for the number of digits to pop from the stack
base10tons_loop:
	div r8
	
	push rdx 		;push remainder and increment
	mov rdx, 0
	inc r10

	cmp rax, 0
	jz base10tons_puts

	jmp base10tons_loop
base10tons_puts:	
	cmp r10, 0
	jz base10tons_end

	mov r9, 0 		;r9 is now used for the remainders

	pop r9
	
	cmp r9, 10
	jge add_hex
	
	jmp add_dig
add_hex:
	sub r9, 10
	add r9, 41h

	jmp add_cont
add_dig:	
	add r9, 30h
add_cont:	
	mov byte [rsi], r9b
	
	dec r10 		;decrease number of digits left
	inc rsi 		;move pointer forwards

	jmp base10tons_puts
base10tons_end:
	mov byte [rsi], 0
	pop rax
	jmp rax

;;; LABEL strtoquad_hex_fast(a -> rsi buf, RETURNS rcx count)
;;; b -> rax ret
strtoquad_hex_fast:
	xor rcx, rcx
	pop rsi

strtoquad_hex_loop:
	xor rax, rax
	mov al, byte [rsi]

	cmp al, 0
	jz strtoquad_hex_end

	cmp al, 10
	jz strtoquad_hex_end
strtoquad_numdigit_chk:
	cmp al, 30h
	jge strtoquad_numdigit_chk2

strtoquad_numdigit_chk2:
	cmp al, 39h
	jle getdigit_dec
strtoquad_hexdigit_chk:
	cmp al, 41h
	jge strtoquad_hexdigit_chk2
strtoquad_hexdigit_chk2:
	cmp al, 46h
	jle getdigit_hex

	jmp strtoquad_hex_end
getdigit_dec:
	sub al, 30h

	jmp strtoquad_hex_reloop
getdigit_hex:
	sub al, 41h
	add al, 10
strtoquad_hex_reloop:
	shl rcx, 4
	add rcx, rax
	
	inc rsi

	jmp strtoquad_hex_loop
strtoquad_hex_end:
	pop rax
	jmp rax
	
;;; LABEL strtoquad(a -> rsi buf, b -> r8 base, RETURNS rcx count)
;;; c -> rax ret
strtoquad:
	pop rsi
	pop r8
	mov rcx, 0
	
	cmp byte [rsi], 45	;ASCII "-"
	jz strtoquad_negate

	mov r9, 1
	jmp strtoquad_loop
strtoquad_negate:
	mov r9, -1		;we use r9 here to apply negation later
	inc rsi
strtoquad_loop:
	cmp byte [rsi], 0
	jz strtoquad_end

	cmp byte [rsi], 30h 	;ASCII "0"
	jge eval_asciidigit

	jmp strtoquad_end
eval_asciidigit:
	cmp byte [rsi], 39h
	jle perform_conversion

	jmp strtoquad_end
perform_conversion:
	mov rax, rcx
	mov rcx, r8 		;rcx used temporarily to transfer the base
	mul rcx

	mov rcx, 0
	mov cl, byte [rsi]
	
	add rax, rcx
	sub rax, 30h

	mov rcx, rax
	inc rsi
	jmp strtoquad_loop
strtoquad_end:
	mov rax, rcx
	mul r9
	mov rcx, rax

	pop rax
	jmp rax
	

exit:
	;; all linux programs must exit properly
	;; sys_exit
	mov rax, 60
	mov rdi, 0 		;int error_code
	syscall
