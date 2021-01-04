.model tiny
.386
.code	
	ORG 80h
	cmd_len db ?
	cmd_line db ?
	ORG 100h
main:
 	
	cmd_param db ?
	old_handler dd ?
	
	sc_vovels db 12h,15h,16h,17h,18h,1eh,0	
	str3 db 12h,15h,16h,17h,18h,1eh,10h,11h,13h,14h,19h,1fh,20h,21h,22h,23h,24h,25h,26h,2ch,2dh,2eh,2fh,30h,21h,32h,0

	; Обрабатываем входные параметры.
	; Пользователь гарантирует правильность ввода параметра. (один пробел и одна буква (i,u,o,v,c,k) ).	
	lea di,cmd_line
	mov dl,[di+1] 		
	lea di,cmd_param
	mov [di],dl ; Теперь наш параметр хранится в [cmd_line].
	
	push es;
	mov ax,0
	mov es, ax

	mov ax, word ptr es:[09h*4]
	mov word ptr old_handler, ax
	mov ax, word ptr es:[09h * 4 + 2]
	mov word ptr old_handler + 2, ax
	
	mov ax, cs
	pushf
	cli ; ЗАпрет на прерывания.
	mov word ptr es:[09h * 4 + 2], ax
	mov ax, offset our_handler
	mov word ptr es:[09h * 4], ax
	popf ; Восстанавливаем флаги. разрешаем прерывания.
	pop es
	
inf_cycle: ; Цикл ввода символов.

	mov ah,1
	int 21h
	mov dl, al
	cmp dl, 27 ;(обработка Escape)
	jne inf_cycle

last: ; Возвращаем старый обработчик.
	
	push es
	mov ax,0
	mov es, ax
	pushf
	cli
	mov ax, word ptr old_handler + 2
	mov word ptr es:[09h * 4 + 2], ax
	mov ax, word ptr old_handler
	mov word ptr es:[09h * 4], ax	
	popf
	pop es

	mov ax, 4c00h
	int 21h
	
; -------------------------------------------------------- Наш обработчик. -----------------------------------

	str2 db 10h,11h,13h,14h,19h,1fh,20h,21h,22h,23h,24h,25h,26h,2ch,2dh,2eh,2fh,30h,31h,32h,0
	
our_handler:
	push es ds si di cx bx dx ax
				
	mov ax,0
	in al, 60h
	push ax
	
	; Начало проверок в зависимости от параметра "cmd_param".
	; if "k":
		cmp [cmd_param],'k'
		je ke1
			pop ax
			jmp if_i
		ke1:
		; Проверяем какая шифт нажата. (нажата ли ваще)
		mov ah,02h
		int 16h
		test al,2
		jz cont1
			pop ax
			jmp end_cycle1
		cont1:
		test al,1
		jz cont2
			pop ax
			jmp end_cycle1

		cont2:
		pop ax
		mov bx,0	
		mov si,bx
		cycle1:
			cmp sc_vovels[si],0
			je end_cycle1
					
			mov si,bx
			mov dl,sc_vovels[si]
			cmp dl,al
			je end_handler
				inc bx
				jmp cycle1
		end_cycle1:
		jmp standart_handler
	
	; if "i" проглатывать малые буквы.
		if_i:
		push ax
		cmp [cmd_param],'i'
		je ke2
			pop ax
			jmp if_u
		ke2:
		; Проверяем какая шифт нажата. (нажата ли ваще)
		mov ah,02h
		int 16h
		test al,2
		jz cont3
			pop ax
			jmp end_cycle2
		cont3:
		test al,1
		jz cont4
			pop ax
			jmp end_cycle2

		cont4:
		pop ax
		mov bx,0	
		mov si,bx
		cycle2:
			cmp str3[si],0
			je end_cycle2
					
			mov si,bx
			mov dl,str3[si]
			cmp dl,al
			je end_handler
				inc bx
				jmp cycle2
		end_cycle2:
		jmp standart_handler
		
	; if "u" проглатывать большие буквы.
		if_u:
		push ax
		cmp [cmd_param],'u'
		je ke3
			pop ax
			jmp if_o
		ke3:
		; Проверяем какая шифт нажата. (нажата ли ваще)
		mov ah,02h
		int 16h
		test al,2
		jz cont5			
			jmp cont6
		cont5:
		test al,1
		jnz cont6
			pop ax
			jmp end_cycle3

		cont6:
		pop ax
		mov bx,0	
		mov si,bx
		cycle3:
			cmp str3[si],0
			je end_cycle3
					
			mov si,bx
			mov dl,str3[si]
			cmp dl,al
			je end_handler
				inc bx
				jmp cycle3
		end_cycle3:
		jmp standart_handler
		
	; if "o" проглатывать вс кроме букв.
		if_o:
		push ax
		cmp [cmd_param],'o'
		je ke4
			pop ax
			jmp if_v
		ke4:
		
		cont7:	
		pop ax
		cmp al,01h ; предусматриваем Escape.
		je standart_handler
		mov bx,0	
		mov si,bx
		cycle4:
			cmp str3[si],0
			je end_cycle4
					
			mov si,bx
			mov dl,str3[si]
			cmp dl,al
			je standart_handler
				inc bx
				jmp cycle4
		end_cycle4:
		jmp end_handler
		
	; if "v" проглатывать гластные.
		if_v:
		push ax
		cmp [cmd_param],'v'
		je ke5
			pop ax
			jmp if_c
		ke5:
		
		cont8:
		pop ax
		mov bx,0	
		mov si,bx
		cycle5:
			cmp sc_vovels[si],0
			je end_cycle5
					
			mov si,bx
			mov dl,sc_vovels[si]
			cmp dl,al
			je end_handler
				inc bx
				jmp cycle5
		end_cycle5:
		jmp standart_handler
	
	; if "c" проглатывать согласные. (default).
		if_c:
		push ax
		cmp [cmd_param],'c'
		je ke6
			pop ax
			jmp standart_handler ;***			
		ke6:
		
		cont9:
		pop ax
		mov bx,0	
		mov si,bx
		cycle6:
			cmp str2[si],0
			je end_cycle6
					
			mov si,bx
			mov dl,str2[si]
			cmp dl,al
			je end_handler
				inc bx
				jmp cycle6
		end_cycle6:
		jmp standart_handler
		
; ------------------------------------------------------------------------- IF
	
end_handler:
        mov al,20h  
        out 20h,al  
        pop ax dx bx cx di si ds es
        iret
		
standart_handler:
	pop ax dx bx cx di si ds es
	jmp dword ptr old_handler

end main