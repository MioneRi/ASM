.model small
.stack 100h
.data	
	n dw 0 ; amount of strings and rows.
	i dw 0
	j dw 0
	k dw 0
	value1 dw 0
	value2 dw 0
	array dw 202 dup(?)
	space dw 32
	const10 dw 10d
	trystr db "Try again: $"
	minus1 db "-$"
	ourArray db "Our array : $"
	printsize1 db "Print size of array : $"
	prvalue1 db "Print values of array : $"
	
.code
.386
main:
	mov ax,@data
	mov ds,ax
	
	; Read size of array first.
	call PrintStr c, offset printsize1
	call InputNum
	mov n,ax
	
	; Read array.
	call PrintStr c, offset prvalue1
	call NextStr
	mov i,0
	i_loop1:
	
		mov j,0
		j_loop1:
			call InputNum
			call get_index c, i, j, n ; getting index for store the value.
			mov array[si],ax
			
			inc j
			mov ax,n
			cmp j,ax ; cmp j,n
			jne j_loop1
		j_end_loop1:
		
		inc i
		mov ax,n
		cmp i,ax ; cmp i,n
		jne i_loop1
		
	i_end_loop1:
	; End read array.
	
	; Main logic.
	mov k, 0
	k_loop2:
		mov i, 0    
		i_loop2:
			mov j, 0
			j_loop2:
				call get_index C, i, k, n
				mov ax, array[si]
				mov value1, ax
				call get_index C, k, j, n
				mov ax, array[si]
				mov value2, ax
				call get_index C, i, j, n
				mov ax, value1
				add ax, value2
				cmp array[si], ax
				jle continue
				mov array[si], ax
				jmp continue
		
				continue:
            
				inc j
				mov ax, n
				cmp j, ax   
				jne j_loop2
			end_j_loop2:

			inc i
			mov ax, n
			cmp i, ax
			jne i_loop2
		end_i_loop2:

		inc k
		mov ax, n
		cmp k, ax
		jne k_loop2
	end_k_loop2:
	; End Main logic.
	
	; Print array.
	call PrintStr c, offset ourArray
	call NextStr
	mov i,0
	i_loop3:
	
		mov j,0
		j_loop3:			
			call get_index c, i, j, n
			mov ax,array[si]
			call PrintNum
			call print_char c, space
			
			inc j
			mov ax,n
			cmp j,ax ; cmp j,n
			jne j_loop3
		j_end_loop3:
		call NextStr
		
		inc i
		mov ax,n
		cmp i,ax ; cmp i,n
		jne i_loop3
		
	i_end_loop3:
	; End print array.
	
	MOV ax,4c00h
	INT 21h	
	
	;----------------------------------------------------------------------------------------------------------------------procedures.
	
	;*
	get_index proc C near ; returns "si" - index of array according i,j,n.
	arg ii, jj, nn : word
	uses ax,bx
    mov ax, ii
    mul byte ptr nn
    add ax, jj
    mov bx, 2d
    mul bx
    mov si, ax
	ret
	endp
	
	;*	
	PrintStr proc c near ; near - значит что эта процедура будет вызываться в этом же сигменте.
	arg ourStr: word
	uses ax,dx
		MOV ah,09h
		MOV dx, ourStr
		INT 21h
		ret
	endp
	
	;*
	print_char proc C near
	arg sym:word
	uses ax, dx
		mov ah, 02h
		mov dl, offset sym
		int 21h
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
	
	;*	
	DelChar PROC ; Deletes last char.
		PUSH ax
		PUSH dx								
		
		MOV dl,32 ; 32 is Space.
		MOV ah,02h
		INT 21h
		
		MOV dl,8
		MOV ah,02h ; Prints char from dl.
		INT 21h
		
		POP dx
		POP ax
		RET
	DelChar ENDP
	
	; Gets an decimal num. from user in range -32 768 .. 32767
	; Writes input into AX register.
	; We'll use registers: ax - for final result;
	;					   al - stores input char;
	;                      bx - stores tmp results;	
	;					   dx - 10(number)
	;					   cx - amount of chars. (includes "-" char)
	InputNum Proc C
	LOCAL isNegative:word ; Это позволяет делать переменные только внутри этой процедуры.
		PUSH bx
		PUSH dx		
		PUSh cx
		
		MOV isNegative,0 ; equals 1 if number is negative.
		MOV bx,0		
		MOV cx,0
		JMP cycle3
		
		EscapeL: ; For Escape.
		MOV isNegative,0
		MOV bx,0
		INC cx
		cycle4:
			MOV dl,8
			MOV ah,02h ; Prints char from dl.
			INT 21h
			CALL DelChar						
		LOOP cycle4
		JMP cycle3
		
		Begin1:	; For Bad input.
		MOV isNegative,0
		MOV bx,0			
		CALL NextStr
		CALL TryProc
		MOV cx,0
		JMP cycle3
		
		BcSpace: ; For Backspace.
		CALL DelChar		
		CMP isNegative,1
		JNE label3
			CMP cx,1
			JNE label3
				MOV isNegative,0
				JMP cycle3
		label3:
		MOV ax,bx
		MOV bx,10
		MOV dx,0
		DIV bx
		MOV bx,ax		
		DEC cx	
		JMP cycle3
		
		; Checks ax.
		CheckOverflow1: 	
			; Тут еще одна проверка, тк до этого могло быть переполнение.
			JNC Cont3 ; Goto if CF == 0 (Если не было переполнения).
				POP ax				
				JMP Begin1
			
			Cont3:			
			CMP isNegative,1
			JNE label1
			; если отрицательное (от 0 до 32 768)
			CMP ax,32768
			JNBE Begin1
			JMP return1
			
			label1:
			; если положительное. (от 0 до 32 767)
			CMP ax,32767
			JNBE Begin1
			
		JMP return1
		
		; Checks bx.
		CheckOverflow2:
		
			CMP isNegative,1
			JNE label2
			; если отрицательное (от 0 до 32 768)
			CMP bx,32768
			JNBE Begin1
			JMP return2
			
			label2:
			; если положительное. (от 0 до 32 767)
			CMP bx,32767
			JNBE Begin1
			
		JMP return2
			
		cycle3:
			; Input 1 characer to AL				
			MOV ah,01h
			INT 21h
			
			; Если это Esc.
			CMP al,27
			JE EscapeL
			
			; Если это Enter.
			CMP al,13
			JE endMark						
			
			; Если это Backspace.
			CMP al,8
			JE BcSpace
			
			; Если это "-" и cx == 0 (cx - кол-во символов, тоесть если знак "-" является первым символом).
			CMP al,45
			JNE Continue1 ; Если не минус то проверяем дальше число ли это.
			CMP cx,0
			JNE Begin1 ; Если это минус но не первый то конец.						
			MOV isNegative,1
			INC cx
			JMP cycle3 ; Продолжаем ввод.
			
			Continue1:
			; Если число if(al>=48 && al<=57)
			CMP al,48
			JNAE Begin1 ; Not above or equal.
			CMP al,57
			JNBE Begin1 ; Not below or equal.
			
			INC cx ; Increase amount of chars.
			
			; Logic BX = BX*10 + AL(inputed digit)
			CBW ; Расширили al до ax.
			SUB ax,48 ; Отняли символ "0"			
			PUSH ax ; Заносим в стек значение введенной цифры.
			MOV ax,bx
			MOV dx,10
			MUL dx ; AX = AX * 10
			
			; Check for CF.
			; Проверка на переполнение ax.			
			JMP CheckOverflow1
			return1:							
			Cont1:
			MOV bx,ax			
			POP ax	; Достаём из стека значение введенной цифры.
			ADD bx,ax ; BX += digit
			
			; Check for CF.
			; Проверка на переполнение bx.
			JC Begin1 ; Проверяем перед той проверкой тк могла до этого быть переполнение.
			JMP CheckOverflow2
			return2:			
			
			JMP cycle3
		
		endMark:		
			; 1) --------Проверить если число отрицательное т.е. был минус и после него нет чисел то сначала.			
			; 2) --------Преобразовать число если оно отрицательное. (т.е. Ответ = 65 535 - "введенное_число" + 1)
			CMP isNegative,1
			JNE label4
				CMP cx,1
				JNE label4
					JMP Begin1
			
			label4:
				CMP cx,0
				JNE label5
					JMP Begin1
					
			label5: ; < --- Если всё окей. Остается только преобразовать число в отрицательное если нужно.
			CMP isNegative,1
			JNE label6
				MOV ax,65535
				SUB ax,bx
				INC ax
				JMP endMark1
			
			label6:
			MOV ax,bx
		
		endMark1:		
		POP cx
		POP dx
		POP bx		
		RET
	InputNum ENDP
	
	;****************************************************PRINT NUM*******************************************************
	; Prints decimal number in range -32 768 .. 32767
	; Gets number from AX.
	; We'll use registers: ax - stores number for printing;
	;					   bx - stores 10;
	;					   dx - stores remainder after dividing;
	; 					   cx - stores amount of chars in number.
	; ! WARNING : if the number is negative and it isn't between [-32 768 .. 32767], printed number will be -x = "65 536 - x".
	PrintNum PROC
		PUSH ax
		PUSH bx
		PUSH dx
		PUSh cx
		
		; Будем делить число на 10 в любом случае.
		MOV bx,10
		MOV cx,0
		
		; Проверяем на отрицательнсть.
		TEST ax,-1
		
		JS notPositive1		
			; Cycle begin.
			cycle1:	
				MOV dx,0
				; Divide AX by 10(bx).
				DIV bx
				; Push remainder into stack.
				PUSH dx
				; Increase cx (amount of chars)
				INC cx
				; Есди остаток равен 0, то конец числа и цикла.
				CMP ax,0
			JNE cycle1
			
			; Loop decreases cx (amount of chars)
			cycle2:			
				; Pull our stack values from.
				POP dx	
				ADD dx,48
				; Prints value from dl.
				MOV ah,02h
				INT 21h			
			LOOP cycle2			
			
			JMP End1
		
		notPositive1: ; -------------------------- Если отрицательное--------!.
			; Если отрицательное.
			; Prints value from dl.
			MOV dl,45 ; 45 == "-".
			PUSH ax
			MOV ah,02h
			INT 21h
			POP ax
			
			; Делаем число "нормальным".
			MOV bx,ax
			MOV ax,0ffffh
			SUB ax,bx ; Получили число хорошее. И дальше по старому алгоритму.
			INC ax ; т.к. по формуле "-x = 65 536 - x = 65 535 - x + 1".
			
			MOV bx,10 ; В страом алгосе это должно быть равно 10.
			
			JMP cycle1 ; Перемещаемся к старому алгосу.
		
		End1:
		
		POP cx
		POP dx
		POP bx
		POP ax
		; Берет из вершины стека адрес процедуры к которой нужно перейти (которую записал CALL).
		RET 
	PrintNum ENDP
	
end main