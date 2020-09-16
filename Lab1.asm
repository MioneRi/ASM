.model small
.stack 200h
.data
	a dw 1
	b dw 2
	c dw 3
	d dw 0 ; 4 for last, 1 for first, 0 for middle condition check.
.code
main:
	MOV ax,@data
	MOV ds,ax
	
	; Присваиваем значения.	
	MOV bx,a
	MOV cx,b
	
	; bx = a(bx) | c
	OR bx,c
	
	; cx = b(cx) ^ d
	XOR cx,d
	
	; Comprehension.
	CMP bx,cx
	JNE ifNotEquals1 
		; If equals.
		MOV ax,a
		XOR ax,b ; ax = a(ax) ^ b
		XOR ax,c ; ax = ax ^ c
		ADD ax,d ; ax = ax + d
		; Check ax  = (a ^ b ^ c) + d
		JMP L2
		
	ifNotEquals1:
		; Else.
		; Prepare for condition.
		MOV bx,a
		ADD bx,b ; a(bx) + b
		MOV cx,c
		XOR cx,d ; c(cx) ^ d	
		
		; Comprehension 2.
		CMP bx,cx
		JNE ifNotEquals2
			; If equals.
			MOV ax,a
			AND ax,d ; a & d
			MOV bx,b		
			ADD bx,c ; b + c
			OR ax,bx
			; Check ax = (a & d) | ( b + c).
			JMP L2
			
		ifNotEquals2: 
			MOV ax,a
			MOV bx,b
			ADD bx,c ; (b + c)
			
			XOR ax,bx
			OR ax,d
			; Check ax = a ^ (b + c) | d.
	
	L2:
	
	MOV ax,4c00h
	INT 21h ; Делаем прерывание процессора.
	
	; Here i'll write some functions:
	
end main