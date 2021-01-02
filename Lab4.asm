.model small
.stack 100h
.data	
	kek db "lol$"
	strAll db 102 dup(?) ; Stores the whole entered string.
	str2Begins dw ? ; Index where str2 begins!
	str1 db 102 dup(?)
	str2 db 102 dup(?)
	lenAll dw 0
	len1 dw 0
	len2 dw 0
	yesStr db "yes$"
	noStr db "no$"
	symbol db ?
	tryStr db "Try again: $"
	flag dw 1
.code
.386
main:
	MOV ax,@data
	MOV ds,ax
	
	CALL ReadString c, offset strAll, offset lenAll
	
	; Calculating where str1 ends. and str2Begins.
	mov cx,0	
	find1str:
		MOV si,cx
		CMP strAll[si],' '
		JE cont2
		INC cx
		JMP find1str
		
	cont2:	
	MOV len1,cx ; len1 detected!
	mov cx,lenAll
	sub cx,len1
	dec cx 
	mov len2, cx ; len2 detected!
	
	MOV ax,len1
	INC ax ; ax = i 	
	jmp mainAct1
	forcyc1:
		
		inc ax
		cmp ax,lenAll
		jae forcyc1end
		mov cx,lenAll
		sub cx,ax ; cx - длина оставшейся str2.
		cmp len1,cx ; str1 не должна быть длиннее оставшейся str2.
		ja forcyc1end
		
		mainAct1:
		mov flag,1 ; flag = true.		
				
		push ax
		MOV bx,0 ; bx = j
		MOV cx,len1 
		DEC cx ; Цикл идёт от 0 до len1-1 по str1 и от ax до ax+len1-1 по str2.
		jmp mainAct2
		forcyc2:
			
			inc bx
			inc ax
			cmp bx,len1
			jae forcyc2end			
			
			mainAct2:
			mov si, bx
			mov dl, strAll[si]
			mov si, ax
			
			cmp dl, strAll[si]
			je forcyc2
				mov flag,0				
		; forcyc2 end.	----------	
		forcyc2end:
		pop ax
		
	CMP flag,1 ; if (flag == true) print "yes" 
	JNE forcyc1
		call PrintStr c, offset yesStr
		JMP totalEnd
	; forcyc1 end. --------
	forcyc1end:
	
	call PrintStr c, offset noStr
	
	totalEnd:	
	MOV ax,4c00h
	INT 21h	
	
	;----------------------------------------------------------------------------------------------------------------------procedures.
	
	;*
	ReadString proc C near
	arg ourStr1:word,ourLeng1:word
	uses ax,bx
    mov bx, ourStr1
    mov si, 0

    ContRead:
        call ReadChar C, offset symbol
		
		; /r
        cmp symbol, 13
        je cont1
	
		; /n
        cmp symbol, 10
        je cont1

        mov al, symbol
        mov byte ptr [bx + si], al
        
        inc si        
        jmp ContRead
	
		; Когда закончился ввод.
		cont1:
		mov byte ptr [bx + si], '$'
		
		; по адресу "ourLeng1" сохр. значение длины строки.
		mov bx, ourLeng1
		mov [bx], si
		ret
	endp
	
	;*
	; Передаём как параметр символ "symbol"(из ds) 
	ReadChar proc C near
	arg ourChar:word
	uses ax, bx
		mov bx, ourChar
		mov ah, 01h
		int 21h
		mov byte ptr [bx], al
		ret
	endp
	
	;*	
	PrintStr proc c near ; near - значит что эта процедура будет вызываться в этом же сигменте.
	arg ourStr:word
	uses ax,dx
		MOV dx,ourStr
		MOV ah,09h
		INT 21h
		ret
	endp
	
	;*
	NextStr proc c near
	uses ax,dx
		MOV ah,02h
		MOV dl,10
		INT 21h
		ret
	endp
	
	;*
	TryProc proc c near
	uses ax,dx
		MOV ah,09h
		LEA dx,tryStr		
		INT 21h
		CALL NextStr
		ret
	endp
	
end main