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
main:
	MOV ax,@data
	MOV ds,ax					
	; Записывает след. команду в стек и переходит к выполнению процедуры.
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
	
	MOV dx,0 ; Обнуляем dx т.к. может возникнуть переполнение и будет оошибка как при делении на ноль!
	DIV bx ; ax = ax/bx	
	
	CALL PrintNum ; Целая часть
	LEA cx,dot1	
	CALL PrintStr ; Печатаем точку (dot1).
	
	MOV ax,dx
	MOV cx,10
	MOV dx,0
	MUL cx
	MOV dx,0
	DIV bx
	CALL PrintNum ; Выводим остаток.
	
	MOV ax,4c00h
	INT 21h ; Делаем прерывание процессора.	
	
	;********************************************INPUT NUM*********************************************************************
	; Gets an decimal num. from user in range 0..65 535
	; Writes input into AX register.
	; We'll use registers: ax - for final result;
	;					   al - stores input char;
	;                      bx - stores tmp results;	
	;					   dx - 10(number)
	InputNum Proc		
		PUSH bx
		PUSH dx		
		
		MOV bx,0		
		JMP cycle3
		
		Begin1:	
		MOV bx,0					
		CALL TryProc		
		
		cycle3:
			; Input 1 characer to AL				
			MOV ah,01h
			INT 21h
			
			; Если это Enter.
			CMP al,13
			JE endMark
			
			; Если это Esc.
			CMP al,27
			JE Begin1
			
			; Если число if(al>=48 && al<=57)
			CMP al,48
			JNAE Begin1
			CMP al,57
			JNBE Begin1
			
			; Logic BX=BX*10 + AL(inputed digit)
			CBW ; Расширили al до ax.
			SUB ax,48 ; Отняли "0"			
			PUSH ax ; 
			MOV ax,bx
			MOV dx,10
			MUL dx ; AX = AX * 10
			; Check for CF. (Проверка на переполнение)
			JNB Cont1 ; Goto if CF == 0.
				POP ax
				JMP Begin1			
			Cont1:
			MOV bx,ax			
			POP ax			
			ADD bx,ax ; BX += digit ; Тут поменяется CF если было переполнение, сохраняем это в CX.
			; Check for CF.
			JNB cycle3								
			
			JMP Begin1
		
		endMark:								
			MOV ax,bx
				
		POP dx
		POP bx		
		RET
	InputNum ENDP
	
	;****************************************************PRINT NUM*******************************************************
	; Prints decimal number in range 0..65 535
	; Gets number from AX.
	; We'll use registers: ax - stores number for printing;
	;					   bx - stores 10;
	;					   dx - stores remainder after dividing;
	; 					   cx - stores amount of chars in number.
	PrintNum PROC
		PUSH ax
		PUSH bx
		PUSH dx
		PUSh cx
		
		; Будем делить число на 10.
		MOV bx,10
		MOV cx,0
		
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
		
		POP cx
		POP dx
		POP bx
		POP ax
		; Берет из вершины стека адрес процедуры к которой нужно перейти (которую записал CALL).
		RET 
	PrintNum ENDP
	
	;*******************************************ERROR MESSAGES****************************************************	
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