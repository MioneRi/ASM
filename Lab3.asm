; This program outputs the result of num1/num2.
.model small
.stack 100h ; 256 byte.
.data
	lessthen db "Should be <= 65 535!$"
	onlystr db "Only digits!$"
	trystr db "Try again: $"
	dot1 db ".$"
	stack1 dw ?
	arg1 dw ?
.code
.386

main:
	MOV ax,@data
	MOV ds,ax					
	
	; -----------------------------------------------------------------------------	
	
	CALL InputNum ; Input num1.
	PUSH ax ; Save num1.
	
	L1: ; Checking loop (p.s. num2 cannot be 0)
	CALL InputNum ; Input num2.
	CMP ax,0	
	JNE L2
	
	CALL TryProc
	JMP L1
	
	L2: ; Now input is correct.
	MOV bx,ax ; bx = num2.
	POP ax ; ax = num1.
	
	CMP ax,0
	JNL kek1
		MOV dx,0ffffh
		JMP kek2
	kek1:
		MOV dx,0 ; Обнуляем dx т.к. может возникнуть переполнение и будет оошибка как при делении на ноль!
		
	kek2:
	IDIV bx ; ax = ax/bx ; 
	
	CALL PrintNum ; Целая часть
	LEA cx,dot1	
	CALL PrintStr ; Печатаем точку (dot1).
	
	CMP ax,0
	JNL kek3
		; - Остаток после деления переводим в положительный эквивалент. (меняем dx)
		
		MOV ax,dx
		MOV dx,0ffffh
		SUB dx,ax
		INC dx
				
	kek3:
		MOV ax,dx
		MOV cx,10
		MOV dx,0
		MUL cx
		MOV dx,0
		DIV bx		
	
	kek4:
	
		CALL PrintNum ; Выводим остаток.
	; -----------------------------------------------------------------------------
	
	MOV ax,4c00h
	INT 21h ; Делаем прерывание процессора.	
	
	;********************************************INPUT NUM*********************************************************************
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
	
	; Deletes last char.
	DelChar PROC
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
	
	;*******************************************BASIC_PROCEDURES****************************************************	
	PrintStr PROC	; Changes cx.
		;POP stack ; Сохр. адрес для возвращения.		
		PUSH ax
		PUSH dx
		PUSH ds
		
		;CALL NextStr	
		
		MOV dx,cx		
		MOV ah,09h ; DS:DX - adress of string.
		INT 21h
		
		;CALL NextStr				
		
		POP ds
		POP dx
		POP ax		
		;PUSH stack ; Возвращаем адрес для возвращения.
		RET
	PrintStr ENDP
	
	NextStr PROC
		PUSH ax
		PUSH dx
		
		; Prints char from dl.
		MOV dl,10
		MOV ah,02h
		INT 21h
		
		POP dx
		POP ax
		RET
	NextStr ENDP
	
	TryProc PROC
		PUSH ax
		PUSH dx			
		
		LEA dx,trystr
		MOV ah,09h
		INT 21h
		
		CALL NextStr
		
		POP dx
		POP ax
		RET
	TryProc ENDP
	
end main