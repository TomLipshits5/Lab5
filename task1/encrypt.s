global _start

section .data
	newLine: db "",10,0
	len: equ $-newLine
	success: db "Success!",10,0
	lesSuccess: equ $-success
	fail: db "Fail!",10,0
	lenFail: equ $-fail
	eStart: dd 0
	eIterator: dd 0
	input: dd 0
	output: dd 1
	
	
section .bss
	buffer: resb 1


section .text
	extern main


_start:
	pop dword ecx 	;assign argc to ecx
	mov esi, esp 	;pointer to argv 
	mov edx, 1		;init edx as 1
	jmp parseArgument	;start parsing arguments


handleE:
	add edi, 2		;move the pointer pass the '+e' chars
	cmp byte[edi], 0  ;make sure the key is not empty
	je exit
	mov [eStart], edi		;init eStart to key start
	mov [eIterator], edi	;init eIterator to key start
	jmp shouldReadArgs		;checl uf there are more arguments

handleI:
	add edi, 2 ;move the pointer pass the '-i' chars
	pushad
	mov eax, 5 ;system call Open
	mov ebx, edi
	mov ecx, 66   ;set read | write mode
	mov edx, 0777
	int 0x80
	mov [input], eax
	popad
	jmp shouldReadArgs


handleO:
	add edi, 2 ;move the pointer pass the '-0' chars
	pushad
	mov eax, 5 ;system call Open
	mov ebx, edi
	mov ecx, 66   ;set read | write mode
	mov edx, 0777
	int 0x80
	mov [output], eax
	popad
	jmp shouldReadArgs




parseArgument:
	mov edi, [esi + 4*edx]			;push esi to the next argiment
	cmp word [edi], word "+e"		;check if the first 2 letters are '+e'
	je handleE						;jump to handle case '+e'
	cmp word [edi], word "-i"
	je handleI
	cmp word [edi], word "-o"
	je handleO

shouldReadArgs:						
	inc edx							;increments edx by 1
	cmp edx, ecx					; checl if we reached the last argument
	je readLetterToBuffer			;if we did go on to reading and encrypting input
	jmp parseArgument				;else go on to parsing the rest of the argumnets


readLetterToBuffer:								
	mov eax, 3					;system call read
	mov ebx, [input]			; assign input
	mov ecx, buffer 			;save input text in buffer
	mov edx, 1                  ;read only one bite each time
	int 0x80
	cmp eax, 1
	jl exit
	mov edx, dword[eIterator]
	cmp byte[edx], 0
	jne writeFromBuffer 		;junp to encryppting and writing the input char
	mov edx, [eStart]
	mov [eIterator], edx	;rest pointers


writeFromBuffer:
	cmp byte[buffer], 0  		;make sure we are not at the end of the input
	je exit						;exit if we are
	cmp byte[buffer], 10 		;check if we are at the end of line
	je writeNewLine			;write new line 

	mov edx, dword[eIterator]	;copy next encryption val to edx
	add dword[eIterator], 1
	mov dl, byte[edx]			;save char byte to dl
	sub dl, byte '0'			;fix ascii offset
	add byte[buffer], dl 		;encrypt char in buffer

	pushad
	mov eax, 4 					;system call write
	mov ebx, [output] 			;output destination
	mov ecx, buffer 			;write text frim buffer
	mov edx, 1 					;write 1 byte
	int 0x80
	jmp readLetterToBuffer


writeNewLine:
	pushad
	mov eax, 4
	mov ebx, 1
	mov ecx, newLine
	mov edx, len       
	int 0x80
	popad
	jmp readLetterToBuffer

writeFail:
	pushad
	mov eax, 4
	mov ebx, 1
	mov ecx, fail   
	mov edx, lenFail     
	int 0x80
	popad
	jmp exit


writeSucces:
	pushad
	mov eax, 4
	mov ebx, 1
	mov ecx, success   
	mov edx, lesSuccess        
	int 0x80
	popad
	jmp writeFromBuffer


exit:
	mov eax, 6 	;system call Close
	mov ebx, [input]
	int 0x80

	mov eax, 6 	;system call Close
	mov ebx, [output]
	int 0x80

	mov eax, 1 ;;systemCall Exit
	int 0x80
	nop








	