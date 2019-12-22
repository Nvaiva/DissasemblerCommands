; **********************************************************
; 3 atsiskaitymas 5 uzduotis 
; APDOROTI CALL, ADD, CMP, PUSHF, POPF
; Autoriai - Vaiva Nostytė, Rokas Žeruolis
; **********************************************************

JUMPS ; auto generate inverted condition jmp on far jumps
.model small
.stack 100h
.data
.386
MAX = 15								;Naudojamas apibrezti didziausiam nuskaitomo failo pavadinimo ilgiui
	
	apie 			db 'Programa priima faila ', 13, 10, '$'
	err_source		db 'Nepavyko atidaryti failo nuskaitymui ', 13, 10, '$'
	Call_IT 		db 'Cia yra call isorinis tiesioginis $'
; **********************************************************
; DARBUI SU FAILAIS
; **********************************************************

	sourceF   		db MAX dup (0)
	sourceFHandle	dw ?
	
	destF   		db MAX dup(0)
	destFHandle 	dw ?
	
	buffer			db 50 dup (?)					;Is failo nuskaitytiems simboliams saugoti

; **********************************************************
; SPAUSDINAMU KOMANDU VARDAI
; **********************************************************

	CALL_k			db 'CALL $'	
	;3 variantai (add registras/atmintis += betarpiškas operandas)(add registras += registras/atmintis)(add akumuliatorius(ax arba al) += betarpiškas operandas)
	ADD_k			db 'ADD $'			
	CMP_k			db 'CMP $'			
	PUSHF_k			db 'PUSHF $'
	POPF_k			db 'POPF $'			
	
; **********************************************************
; SPAUSDINAMU REGISTRU VARDAI
; **********************************************************

	AX_r			db 'ax $'
	CX_r			db 'cx $'
	DX_r			db 'dx $'
	BX_r			db 'bx $'
	SP_r			db 'sp $'
	BP_r			db 'bp $'
	SI_r			db 'si $'
	DI_r			db 'di $'
	AL_r			db 'al $'
	w0bytes			db'alcldlblahchdhbh $'
	rmMod00			db'[bx+si][bx+di][bp+si][bp+di][si]   [di]          [bx]   $'
	w1bytes			db 'axcxdxbxspbpsidi $'
	rmMod01			db '[bx+si+[bx+di+[bp+si+[bp+di+[si+   [di+   [bp+   [bx+    $'
	tiesioginisW0 	db 'byte ptr [$'
	tiesioginisW1 	db 'word ptr [$'
	

; ***********************************************************
; PAPILDOMI KINTAMIJEI
; ***********************************************************

	atmintiesAdresas 	dw 256
	w 					db 0
	d 					db 0
	newLine				db 0Dh, 0Ah, "$"
	tab					db 09h, "$"
	space 				db 32
	kablelis			db ','
	hexNumber			db 0
	neatpazinta 		db 'Komanda nebuvo atpazinta $'
	byteDW				db 0
	byteMod				db 0
	byteReg				db 0
	byteRm				db 0
	turimasBaitas		db 0
	priesBaitas			db 0
	poslinkioBaitas		db 0
	poslinkiojBaitas	db 0
	poslinkiovBaitas	db 0
	opjb				db 0
	opvb				db 0
	jaunesnysisBaitas	db 0
	komandosBaitai		db 4 dup(0)
	skliaustas			db '] $'
	nuskaitytasimboliu	db 0
	ajb					db 0
	avb 				db 0
	hex 				db 'h$'
	
.code
START:
		mov			ax, @data
		mov			es, ax			; es kad galetume naudot stosb funkcija: Store AL at address ES:(E)DI
		mov			si, 81h      	; programos paleidimo parametrai rasomi segmente es pradedant 129 (arba 81h) baitu  
		call skip_spaces
		
		;jeigu nebuvo nuskaityta jokiu parametru isvesti pagalbos pranesima
		mov			al, byte ptr ds:[si]			; nuskaityti pirma parametro simboli
		cmp			al, 13							; jei nera parametru
		je			help							; tai isvesti pagalba
		
		;jei buvo nuskaitytas /? vistiek isvedam pagalba
		mov			ax, word ptr ds:[si]			; su word ptr nuskaitome 2 simobolius 
		cmp			ax, 3F2Fh        				; jei nuskaityta "/?" - 3F = '?'; 2F = '/' susikeicia vietom jaunesnysis ir vyresnysis baitai
		je			help         					; rastas "/?", vadinasi reikia isvesti pagalba
		
	readSourceFile:

		lea			di, sourceF
		call		read_filename					; perkelti is parametro i eilute
		cmp			byte ptr ds:[sourceF], '$' 		;jei nieko nenuskaite
		je			print_error
		
		lea			di, destF
		call		read_filename					; perkelti is parametro i eilute
		
		mov			ax, @data
		mov			ds, ax
			
	source_from_file:
	
		mov	dx, offset sourceF						; failo pavadinimas
		mov	ah, 3dh                					; atidaro faila - komandos kodas
		mov	al, 0                  					; 0 - reading, 1-writing, 2-abu
		int	21h										; INT 21h / AH= 3Dh - open existing file
		jc	print_error								; CF set on error AX = error code.
		mov	sourceFHandle, ax						; issaugojam filehandle	
		
		
		mov dx, offset destF
		mov	ah, 3Ch			; atidaro faila - komandos kodas
		mov	cx, 0			; rasymui
		int	21h				; INT 21h / AH= 3Dh - open existing file.
		mov	destFHandle, ax		; issaugom handle	
		
		call skaitom
		jmp pagrindinis_ciklas
	skaitom proc near
		mov si, 0
		mov cx, 50
		uznulinam:
			mov buffer[si], 0
			inc si
		loop uznulinam
		xor si, si
		xor bx,bx 
		xor dx,dx
		xor ax,ax
		mov	bx, sourceFHandle
		mov	dx, offset buffer       				; address of buffer in dx
		mov	cx, 50    								; kiek baitu nuskaitysim
		mov	ah, 3fh  								; function 3Fh - read from file
		int	21h
		mov si, offset buffer
		cmp al,0
		je _end
		mov nuskaitytasimboliu,al
		ret
	skaitom endp
	
	naujasBaitas proc near
		cmp nuskaitytasimboliu, 0
		je perskaitomdar
		lodsb
		dec nuskaitytasimboliu
		ret
		perskaitomdar:
			call skaitom
			lodsb
			ret
	naujasBaitas endp
		
		
	pagrindinis_ciklas:
		xor ax,ax
		mov ax, atmintiesAdresas
		call PrintHexNumber
		call tabFunkcija
		xor ax,ax
		
		call naujasBaitas
		cmp al, '$'
		je baigti
		inc atmintiesAdresas
		jmp komandosVardas
		
		baigti:
			jmp _end
;**********************************************************
; NUSTATOME, KURI TAI KOMANDA
; *********************************************************	
	komandosVardas:
	
		cmp al, 9Ch ; PUSHF
		jne nePUSHF
		call PUSHF_funkcija
		jmp pagrindinis_ciklas
		
		nePUSHF:
			cmp al, 9Dh ; POPF
			jne nePOPF
			call POPF_funkcija
			jmp pagrindinis_ciklas
		
		nePOPF:
			cmp al, 3Ch ;cmp w = 0 akululiatorius ir betarpiskas operandas
			jne necmpAl
			mov w, 0 	;jeigu tai 3C tai w = 0
			call cmp1_funkcija
			jmp pagrindinis_ciklas
			
		necmpAl:
			cmp al, 3Dh ;cmp w = 1 akululiatorius ir betarpiskas operandas
			jne necmpAX
			mov w, 1 	;jeigu tai 3C tai w = 0
			call cmp1_funkcija
			jmp pagrindinis_ciklas
			
		necmpAX:
			cmp al, 04h ;add w = 0 akululiatorius ir betarpiskas operandas
			jne neAddAl
			mov w, 0
			call add1_funkcija
			jmp pagrindinis_ciklas
		neAddAl:
			cmp ax, 05h ; add w = 1 akumuliatorius ir betarpiskas operandas
			jne neAddAX
			mov w, 1
			call add1_funkcija
			jmp pagrindinis_ciklas
		neAddAX:
			cmp ax, 04h 
			jae neAddRegistras
			call AddPirmasVariantas
			jmp pagrindinis_ciklas
		neAddRegistras:
			cmp ax, 79h
			ja galAddAntras
			jmp neAddAntras
			
		neAddAntras:
			cmp ax, 37h
			ja galcmpPirmas
			jmp neCmpPirmas
			
		neCmpPirmas:
			cmp ax, 00E8h
			jne neCallVT
			call vidinisTiesioginisCall
			jmp pagrindinis_ciklas
		
		neCallVT:
			cmp ax, 00FFh
			jne neCallVNT
			call vidinisNetiesioginisCall
			jmp pagrindinis_ciklas
		
		neCallVNT: 
			cmp ax, 009Ah
			jne neCallIT
			call isorinisTiesioginisCall
			jmp pagrindinis_ciklas
			
		neCallIT:
		
		neatpazinom:
			call PrintHexNumber
			call tabFunkcija
			mov cx, 25
			mov dx, offset neatpazinta
			call iFaila
			call naujaEilute	
		jmp pagrindinis_ciklas
		
		galAddAntras:
			cmp ax, 84h
			ja neAddAntras
			call AddAntrasVariantas
			jmp pagrindinis_ciklas
		galcmpPirmas:
			cmp ax, 8Ch
			ja neCmpPirmas
			call cmpPirmasVariantas
			jmp pagrindinis_ciklas

; *******************************************************
; ISORINIS TIESIOGINIS CALL
; *******************************************************
	isorinisTiesioginisCall proc near
		call PrintHexNumber
		call spaceFunkcija
		mov cx, 3
		uzrasomVisusBaitus:
			call naujasBaitas
			inc atmintiesAdresas
			call PrintHexNumber
			call spaceFunkcija
		loop uzrasomVisusBaitus
		mov cx, 34
		mov dx, offset Call_IT
		call iFaila
		call naujaEilute
		
	isorinisTiesioginisCall endp
; *******************************************************
; VIDINIS NETIESIOGINIS CALL
; *******************************************************
	vidinisNetiesioginisCall proc near
		mov priesBaitas, al
		call analizuoti
		cmp byteReg, 010b
		jne taiNeCallVidinisNetiesioginis
		
		mov al, priesBaitas
		call PrintHexNumber
		call spaceFunkcija
		
		mov al, turimasBaitas
		call PrintHexNumber
		call spaceFunkcija
		
		cmp byteMod, 00b
		je nebusPoslinkio
		cmp byteMod, 11b
		je nebusPoslinkio
		
		call naujasBaitas
		inc atmintiesAdresas
		mov poslinkioBaitas, al
		call PrintHexNumber
		call spaceFunkcija
		
		nebusPoslinkio:
		cmp byteRm, 110b
		je tiesioginisCallAdresas
		
		spausdinam:
		call tabFunkcija
		mov dx, offset CALL_k
		mov cx, 5
		call iFaila
		
		call addAntrosFunkcijosKintamieji
		call naujaEilute
		ret
	

		tiesioginisCallAdresas:
			call spaceFunkcija
			call naujasBaitas 
			inc atmintiesAdresas
			mov poslinkiojBaitas,al
			call printHexNumber
			call spaceFunkcija
			call naujasBaitas
			inc atmintiesAdresas
			mov poslinkiovBaitas, al
			call PrintHexNumber
			call tabFunkcija
			jmp spausdinam
			
		taiNeCallVidinisNetiesioginis:
			cmp byteReg, 011b
			je CallIN
			ret
		CallIN:
			call isorinisNetiesioginisCall
			ret
	vidinisNetiesioginisCall endp
; *******************************************************
; ISORINIS NETIESIOGINIS CALL
; *******************************************************
	isorinisNetiesioginisCall Proc near
	
		mov al, priesBaitas
		call PrintHexNumber
		mov al, turimasBaitas
		call PrintHexNumber
		
		cmp byteMod, 00b
		je nebusPoslinkio1
		cmp byteMod, 11b
		je nebusPoslinkio1
		
		call naujasBaitas
		inc atmintiesAdresas
		mov poslinkioBaitas, al
		call PrintHexNumber
		call spaceFunkcija
		
		nebusPoslinkio1:
		cmp byteRm, 110b
		je tiesioginisCallAdresas1
		
		spausdinam1:
		call tabFunkcija
		mov dx, offset CALL_k
		mov cx, 5
		call iFaila
		
		call addAntrosFunkcijosKintamieji
		call naujaEilute
		ret
	

		tiesioginisCallAdresas1:
			call spaceFunkcija
			call naujasBaitas 
			inc atmintiesAdresas
			mov poslinkiojBaitas,al
			call printHexNumber
			call spaceFunkcija
			call naujasBaitas
			inc atmintiesAdresas
			mov poslinkiovBaitas, al
			call PrintHexNumber
			call tabFunkcija
			jmp spausdinam1
			
	isorinisNetiesioginisCall endp
; *******************************************************
; VIDINIS TIESIOGINIS CALL
; *******************************************************
	vidinisTiesioginisCall PROC near
	
		call printHexNumber
		call spaceFunkcija
		
		call naujasBaitas
		inc atmintiesAdresas
		mov ajb, al
		call PrintHexNumber
		call spaceFunkcija
		call naujasBaitas
		inc atmintiesAdresas
		mov avb, al
		call PrintHexNumber
		call tabFunkcija
		
		mov dx, offset CALL_k
		mov cx, 5
		call iFaila
		
		mov dx, offset tiesioginisW1
		mov cx, 10
		call iFaila
		
		mov al, avb
		call PrintHexNumber
		mov al, ajb
		call PrintHexNumber
		call printHexSimbol
		mov dx, offset skliaustas
		mov cx, 1
		call iFaila
		call naujaEilute
		ret
	vidinisTiesioginisCall endp
; *******************************************************
; CMP REGISTRAS - ATMINTIS/REGISTRAS
; *******************************************************
	CmpPirmasVariantas PROC near
		; atspausdinam baita kuris nurodo, kad komanda yra cmp
		call PrintHexNumber
		call spaceFunkcija
		;analizuojam sekanti baita, kuris parodys mod, reg,r/m ir ar yra poslinkis. atspausdinam tą nauja baita
		call analizuoti
		call PrintHexNumber
		call spaceFunkcija
		
		;poslinkis imanomas tada kai gaunam mod 01 arba 10
		cmp byteMod, 00b
		je neraPoslinkio11
		cmp byteMod, 11b
		je neraPoslinkio11
		
		call naujasBaitas
		inc atmintiesAdresas
		call PrintHexNumber

		
		neraPoslinkio11:
		cmp byteRm, 110b
		je tiesioginisAddAdresas11
		call tabFunkcija
		
		pradedam11:
		mov dx, offset CMP_k
		mov cx, 4
		call iFaila
		
		call PrintModRegRM
		call naujaEilute
		ret
		
		tiesioginisAddAdresas11:
			call naujasBaitas 
			inc atmintiesAdresas
			mov poslinkiojBaitas,al
			call printHexNumber
			call spaceFunkcija
			call naujasBaitas
			inc atmintiesAdresas
			mov poslinkiovBaitas, al
			call PrintHexNumber
			call tabFunkcija
			mov turimasBaitas, al
			jmp pradedam11
		
		ret
	CmpPirmasVariantas endp
; *******************************************************
; CMP ANTRAS VARIANTAS REGISTRAS/ATMINTIS + BETARPISKAS
; *******************************************************
	CmpAntrasVariantas Proc near
		
		; atspausdinam baita kuris nurodo, kad komanda yra add
		xor ax, ax
		mov al, priesBaitas
		call PrintHexNumber
		call spaceFunkcija
	
		mov al, turimasBaitas
		call PrintHexNumber
		call spaceFunkcija
		
		;poslinkis imanomas tada kai gaunam mod 01 arba 10
		cmp byteMod, 00b
		je neraPoslinkio2
		cmp byteMod, 11b
		je neraPoslinkio2
		
		call naujasBaitas
		inc atmintiesAdresas
		call PrintHexNumber
		mov poslinkioBaitas, al
		call spaceFunkcija
		
		neraPoslinkio2:
		cmp byteRm, 110b
		je tiesioginisAddAdresas2
		
		pradedam2:
		call naujasBaitas 
		inc atmintiesAdresas
		call printHexNumber
		mov opvb, al
		call spaceFunkcija
		cmp byteDW,01b
		jne rasomCmp
		call naujasBaitas 
		mov opjb, al
		inc atmintiesAdresas
		call printHexNumber
		
		rasomCmp:
		call tabFunkcija
		mov dx, offset CMP_k
		mov cx, 4
		call iFaila
		
		call addAntrosFunkcijosKintamieji
		call printKablelis
		cmp byteDw,01
		je w1buvo2
		mov al, opvb
		call printHexNumber
		call printHexSimbol
		call naujaEilute
		ret
		w1buvo2:
		mov al, opjb
		call printHexNumber
		mov al, opvb
		call printHexNumber
		call printHexSimbol
		call naujaEilute
		ret
		
		tiesioginisAddAdresas2:
			call naujasBaitas 
			inc atmintiesAdresas
			mov poslinkiojBaitas,al
			call naujasBaitas 
			inc atmintiesAdresas
			mov poslinkiovBaitas, al
			mov al, poslinkiojBaitas
			call printHexNumber
			call spaceFunkcija
			mov al, poslinkiovBaitas
			call printHexNumber
			call spaceFunkcija
			jmp pradedam2
		
		pasirodoNeCmp:
		ret
		
	CmpAntrasVariantas ENDP
; *******************************************************
; ADD ANTRAS VARIANTAS REGISTRAS/ATMINTIS + BETARPISKAS
; *******************************************************
	AddAntrasVariantas PROC near
		mov priesBaitas, al
		call analizuoti
		cmp byteReg, 000b
		jne pasirodoNeAdd
		; atspausdinam baita kuris nurodo, kad komanda yra add
		xor ax, ax
		mov al, priesBaitas
		call PrintHexNumber
		call spaceFunkcija
	
		mov al, turimasBaitas
		call PrintHexNumber
		call spaceFunkcija
		
		;poslinkis imanomas tada kai gaunam mod 01 arba 10
		cmp byteMod, 00b
		je neraPoslinkio1
		cmp byteMod, 11b
		je neraPoslinkio1
		
		call naujasBaitas
		inc atmintiesAdresas
		call PrintHexNumber
		mov poslinkioBaitas, al
		call spaceFunkcija
		
		
		neraPoslinkio1:
		cmp byteRm, 110b
		je tiesioginisAddAdresas1
		
		pradedam1:
		call naujasBaitas 
		inc atmintiesAdresas
		call printHexNumber
		mov opvb, al
		call spaceFunkcija
		cmp byteDW,01b
		jne rasomAdd
		call naujasBaitas 
		mov opjb, al
		inc atmintiesAdresas
		call printHexNumber
		
		rasomAdd:
		call tabFunkcija
		mov dx, offset ADD_k
		mov cx, 4
		call iFaila
		
		call addAntrosFunkcijosKintamieji
		call printKablelis
		cmp byteDw,01
		je w1buvo
		mov al, opvb
		call printHexNumber
		call printHexSimbol
		call naujaEilute
		ret
		w1buvo:
		mov al, opjb
		call printHexNumber
		mov al, opvb
		call printHexNumber
		call printHexSimbol
		call naujaEilute
		ret
		
		tiesioginisAddAdresas1:
			call naujasBaitas 
			inc atmintiesAdresas
			mov poslinkiojBaitas,al
			call naujasBaitas 
			inc atmintiesAdresas
			mov poslinkiovBaitas, al
			mov al, poslinkiojBaitas
			call printHexNumber
			call spaceFunkcija
			mov al, poslinkiovBaitas
			call printHexNumber
			call spaceFunkcija
			jmp pradedam1
		
		pasirodoNeAdd:
		cmp byteReg, 111b
		je taiCmp
		ret
		taiCmp:
			xor ax,ax
			mov al, priesBaitas
			call CmpAntrasVariantas
			ret
	AddAntrasVariantas ENDP
	
	addAntrosFunkcijosKintamieji proc near
		cmp byteMod, 00b
		jne AddModne00
			call printRmMod00
				cmp byteRm, 110b
				je tsg
			ret
			tsg:
				mov al, poslinkiovBaitas
				call printHexNumber
				mov al, poslinkiojBaitas
				call printHexNumber
				call printHexSimbol
				mov dx, offset skliaustas
				mov cx, 1
				call iFaila
				ret
		AddModne00:
			cmp byteMod, 01b
			jne AddModne01
			call printRm01
			mov al, poslinkioBaitas
			call printHexNumber
			call printHexSimbol
				mov dx, offset skliaustas
				mov cx, 1
				call iFaila
			ret
		AddModne01:
			cmp byteMod, 10b
			jne AddModne10
			call printRm01
			mov al, poslinkioBaitas
			call printHexNumber
			call printHexSimbol
				mov dx, offset skliaustas
				mov cx, 1
				call iFaila
			ret
		AddModne10:
			cmp w, 0
			jne w1bus
			call printRm11W0
			call printKablelis
			ret
			w1bus:
			call printRm11W1
			ret
	addAntrosFunkcijosKintamieji ENDP
; ********************************************************
 ; PRINT RM KAI MOD 00
 ; ********************************************************
	printRmMod00 PROC near
		cmp byteRm, 110b
		je tiesioginisAdresas
		xor bx, bx
		mov al, byteRm
		mov dl, 7
		MUL dl
				
		mov bx, ax
		mov di, offset rmMod00
		add di, bx
		mov dx, di
		mov cx,7
		call iFaila
		ret
		
		tiesioginisAdresas:
			cmp w, 0
			jne tiesioginisAdresasW1
			mov dx, offset tiesioginisW0
			mov cx, 10
			call iFaila
			ret
		tiesioginisAdresasW1:
			mov dx, offset tiesioginisW1
			mov cx, 10
			call iFaila
			ret
	printRmMod00 ENDP
	
	printKablelis proc near
		mov dx, offset kablelis
		mov cx, 2
		call iFaila
		ret
	printKablelis endp
	printRegW0 proc near
		xor bx, bx
		mov al, byteReg
		mov dl, 2
		MUL dl
		mov bx, ax
		mov di, offset w0bytes
		add di, bx
		mov dx, di
		mov cx, 2
		call iFaila
		ret
	printRegW0 endp
	printRegW1 proc near
		mov al, byteReg
		mov dl, 2
		MUL dl
		mov bx, ax
		mov di, offset w1bytes
		add di, bx
		mov dx, di
		mov cx, 2
		call iFaila
		ret
	printRegW1 endp
	printRm01 proc near
		mov al,byteRm
		mov dl, 7
		mul dl
		mov bx, ax
		mov di, offset rmMod01
		add di, bx
		mov dx, di
		mov cx, 7
		call iFaila
		ret
	printRm01 endp
	printRm11W0 proc near
		xor bx, bx
		mov al, byteRm
		mov dl, 2
		MUL dl
		mov bx, ax
		mov di, offset w0bytes
		add di, bx
		mov dx, di
		mov cx, 2
		call iFaila
		ret
	printRm11W0 endp
	printRm11W1 proc near
		xor bx, bx
		mov al, byteRm
		mov dl, 2
		MUL dl
		mov bx, ax
		mov bx, ax
		mov di, offset w1bytes
		add di, bx
		mov dx, di
		mov cx, 2
		call iFaila
		ret
	printRm11W1 endp
; *********************************************************
; PRINT MOD REG R/M
; *********************************************************
	PrintModRegRM PROC near
		mov turimasBaitas, al
		xor bx,bx
		cmp byteMod, 0
		ja neMod01
			cmp byteDW, 0000b
			ja neDW01
				call printRmMod00
				
				cmp byteRm, 110b
				jne toliau0
				xor ax,ax 
				mov al, poslinkiovBaitas
				call PrintHexNumber
				mov al, poslinkiojBaitas
				call PrintHexNumber
				call printHexSimbol
				mov dx, offset skliaustas
				mov cx, 1
				call iFaila
				
				toliau0:
				call printKablelis
				call printRegW0
			ret
		neDW01:
			cmp byteDW, 0001b
			ja neDW10
				
				call printRmMod00
				
				cmp byteRm, 110b
				jne toliau1
				xor ax, ax
				mov al, poslinkiovBaitas
				call PrintHexNumber
				mov al, poslinkiojBaitas
				call PrintHexNumber
				call printHexSimbol
				mov dx, offset skliaustas
				mov cx, 1
				call iFaila
				
				toliau1:
				call printKablelis
				call printRegW1
			ret
		neDW10:
			cmp byteDW, 0010b
			ja neDW11
			call printRegW0
			call printKablelis
			call printRmMod00
			
			cmp byteRm, 110b
			jne toliau2
			xor ax, ax
			mov al, poslinkiovBaitas
				call PrintHexNumber
				mov al, poslinkiojBaitas
				call PrintHexNumber
				call printHexSimbol
			mov dx, offset skliaustas
			mov cx, 1
			call iFaila
			toliau2:	
			ret
			
		neDW11:
			call printRegW1
			call printKablelis
			call printRmMod00
			
			cmp byteRm, 110b
			jne toliau3
			xor ax, ax
			mov al, poslinkiovBaitas
				call PrintHexNumber
				mov al, poslinkiojBaitas
				call PrintHexNumber
				call printHexSimbol
			mov dx, offset skliaustas
			mov cx, 1
			call iFaila
			toliau3:	
			ret
		
		neMod01:
			cmp byteMod, 1
			ja neMod02
			mod02gal:
			cmp byteDW, 0
			ja neDW01_01
				call printRm01
				xor ax,ax
				mov al, turimasBaitas
				call PrintHexNumber
				call printHexSimbol
				;mov dx, offset turimasBaitas
				;mov cx, 1
				;call iFaila
				
				mov dx, offset skliaustas
				mov cx, 1
				call iFaila
				call printKablelis
				call printRegW0
			ret
			neDW01_01:
			cmp byteDW, 1
			ja neDW10_01
				call printRm01
				xor ax,ax
				mov al, turimasBaitas
				call PrintHexNumber
				;mov dx, offset turimasBaitas
				;mov cx, 1
				;call iFaila
				
				mov dx, offset skliaustas
				mov cx, 1
				call iFaila
				
				call printKablelis
				call printRegW1
			ret
				neDW10_01:
				cmp byteDw, 2
				ja neDW11_01
					call printRegW0
					call printKablelis
					call printRm01
					xor ax, ax
					
					mov al, turimasBaitas
					call PrintHexNumber
					call printHexSimbol
					;mov dx, offset turimasBaitas
					;mov cx, 1
					;call iFaila
				
					mov dx, offset skliaustas
					mov cx, 1
					call iFaila
				ret
			neDW11_01:
				call printRegW1
					call printKablelis
					call printRm01
					xor ax, ax
					mov al, turimasBaitas
				call PrintHexNumber
				call printHexSimbol
					;mov dx, offset turimasBaitas
					;mov cx, 1
					;call iFaila
				
					mov dx, offset skliaustas
					mov cx, 1
					call iFaila
				ret
			neMod02:
			cmp byteMod, 2
			je mod02gal
			cmp byteDW, 0
			ja neDW01_3
				call printRm11W0
				call printKablelis
				call printRegW0
				ret
			neDW01_3:
			cmp byteDW, 1
			ja neDW10_3
				call printRm11W1
				call printKablelis
				call printRegW1
				ret
			neDW10_3:
			cmp byteDw, 2
			ja neDW11_3
				call printRegW0
				call printKablelis
				call printRm11W0
				ret
			neDW11_3:
				call printRegW1
				call printKablelis
				call printRm11W1
				ret
				
	PrintModRegRM ENDP
; *********************************************************
; ADD PIRMAS VARIANTAS
; *********************************************************
	AddPirmasVariantas PROC near
		; atspausdinam baita kuris nurodo, kad komanda yra add
		call PrintHexNumber
		call spaceFunkcija
		;analizuojam sekanti baita, kuris parodys mod, reg,r/m ir ar yra poslinkis. atspausdinam tą nauja baita
		call analizuoti
		call PrintHexNumber
		call spaceFunkcija
		
		;poslinkis imanomas tada kai gaunam mod 01 arba 10
		cmp byteMod, 00b
		je neraPoslinkio
		cmp byteMod, 11b
		je neraPoslinkio
		
		call naujasBaitas
		inc atmintiesAdresas
		call PrintHexNumber

		
		neraPoslinkio:
		cmp byteRm, 110b
		je tiesioginisAddAdresas
		call tabFunkcija
		
		pradedam:
		mov dx, offset ADD_k
		mov cx, 4
		call iFaila
		
		call PrintModRegRM
		call naujaEilute
		ret
		
		tiesioginisAddAdresas:
			call naujasBaitas 
			inc atmintiesAdresas
			mov poslinkiojBaitas, al
			call printHexNumber
			call spaceFunkcija
			call naujasBaitas
			inc atmintiesAdresas
			mov poslinkiovBaitas, al
			call printHexNumber
			call tabFunkcija
			mov turimasBaitas, al
			jmp pradedam
		
	AddPirmasVariantas ENDP
; *********************************************************
; NUSTATYTI DW REG RM IR MOD DALIS
; *********************************************************
	Analizuoti PROC near

		mov turimasBaitas, al
		mov ah, 00h
		mov dl, 0100b
		div dl
		mov byteDW, ah
		
		; issiaiskinom DW, imam nauja baita ir nustatom mod reg ir rm
		call naujasBaitas
		mov turimasBaitas, al ;nes dalinant pasikeicia reiksme
		inc atmintiesAdresas
		
		mov ah, 00h
		mov dl, 00001000b 
		div dl
		mov byteRm, ah
		
		mov ah, 00h
		div dl
		mov byteReg,ah
		
		mov dl, 100b 
		mov ah, 00h
		div dl
		mov byteMod, ah
		
		xor ah, ah
		mov al, turimasBaitas
		call devideBW
		ret
	Analizuoti ENDP
; *********************************************************
; ADD AKUMULIATORIUS - BETARPISKAS OPERANDAS
; *********************************************************
	add1_funkcija PROC near
		call PrintHexNumber
		call spaceFunkcija
		xor ax,ax
		call naujasBaitas
		inc atmintiesAdresas
		mov opjb, al
		call PrintHexNumber
		cmp w, 1
		je loadinamDarViena1
		call tabFunkcija
		
		einamToliau1:
		mov dx, offset ADD_k
		mov cx, 4
		call iFaila
		call perkeltiAx
		ret
		
		loadinamDarViena1:
			mov opvb, 0
			call spaceFunkcija
			call naujasBaitas
			mov opvb, al
			call PrintHexNumber
			inc atmintiesAdresas
			call tabFunkcija
			jmp einamToliau1
		
	add1_funkcija ENDP
; *********************************************************
; CMP AKUMULIATORIUS - BETARPISKAS OPERANDAS
; *********************************************************
		CMP1_funkcija PROC near
			call PrintHexNumber
			call spaceFunkcija
			xor ax,ax
			call naujasBaitas
			inc atmintiesAdresas
			mov opjb, al
			call PrintHexNumber
			cmp w,1
			je loadinamDarViena
			call tabFunkcija
			
			einamToliau:
			mov dx, offset CMP_k
			mov cx, 4
			call iFaila
			call perkeltiAX
			ret
			
			loadinamDarViena:
				call spaceFunkcija
				call naujasBaitas
				mov opvb, al
				inc atmintiesAdresas
				call PrintHexNumber
				call tabFunkcija
				jmp einamToliau
				
		CMP1_funkcija ENDP
; *********************************************************
; AKUMULIATORIAUS IRASYMO I BUFFERISVEDIMUI FUNKCIJA
; *********************************************************
	perkeltiAx PROC near
		cmp w, 0
			jne akumuliatoriusAX1
			
				mov dx, offset AL_r
				mov cx, 2
				call iFaila
				
				mov dx, offset kablelis
				mov cx, 2
				call iFaila
				
				mov al, opjb
				call PrintHexNumber
				call printHexSimbol
				call naujaEilute
			
			ret
			akumuliatoriusAX1:
				mov dx, offset AX_r
				mov cx, 2
				call iFaila
				
				mov dx, offset kablelis
				mov cx, 2
				call iFaila
				
				mov al,opvb
				call printHexNumber
				xor ax, ax
				mov al, opjb
				call printHexNumber
				call printHexSimbol
				call naujaEilute	
			ret
	perkeltiAx ENDP
; *********************************************************
; PUSHF PERRASYMAS I BUFERI
; *********************************************************
	PUSHF_funkcija PROC near
		call PrintHexNumber
		call tabFunkcija
		mov dx, offset PUSHF_k
		mov cx, 6
		call iFaila
		call naujaEilute
		ret
	PUSHF_funkcija ENDP
; ************************************************************
; POPF PERRSASYMAS I BUFERI 	
;*************************************************************
	POPF_funkcija PROC near
		call PrintHexNumber
		call tabFunkcija
		mov dx, offset POPF_k
		mov cx, 5
		call iFaila
		call naujaEilute
		ret
	POPF_funkcija ENDP
; **********************************************************
; IRASOME I FAILA	
; **********************************************************	
	iFaila PROC near
		push ax
		mov bx, destFHandle
		mov	ah, 40h			; INT 21h / AH= 40h - write to file
		int	21h
		
		pop ax
		ret
	iFaila ENDP
; ***********************************************************
; TAB 
; ***********************************************************
	tabFunkcija PROC near
		mov dx, offset tab
		mov cx, 1
		call iFaila
		ret
	tabFunkcija ENDP
; ***********************************************************
; SPACE FUNKCIJA 
; ***********************************************************
	spaceFunkcija PROC near
		mov dx, offset space
		mov cx, 1
		call iFaila
		ret
	spaceFunkcija ENDP
; ***********************************************************
; NAUJA EILUTE FAILE
; ***********************************************************
	naujaEilute PROC near
		mov dx, offset newLine
		mov cx, 2
		call iFaila
		ret
	naujaEilute ENDP
; **********************************************************
; PASIVERCIAM SKAICIU DL I HEX
; **********************************************************
	PrintHexNumber proc ;
		push ax
		cmp ax, 100h
		jb diBus2
		mov di, 4
		jmp convert_and_print
		diBus2:
		mov di, 2
	convert_and_print:
		MOV cx, 0000h
		MOV bx, 16
	convert:
		XOR dx,dx
		DIV bx
		ADD dl, '0'
	loop1:
		PUSH dx
		INC cx
		dec di
		CMP di, 0
		JA convert
	print_number:
		POP dx		; griztam i praeita reiksme
		cmp dl,9
		jb rasom
		cmp dl, ':'
		je printA
		cmp dl, ';'
		je printB
		cmp dl, '<'
		je printC
		cmp dl, '='
		je printD
		cmp dl, '>'
		je printE
		cmp dl, '?'
		je printF
		
	rasom:
		push cx
		mov cx, 1
		mov hexNumber, dl
		mov dx, offset hexNumber
		call iFaila
		xor dx,dx
		mov hexNumber, 0
		pop cx
	LOOP print_number
		pop ax
		ret
		printA:
			mov dx, 'A'
			jmp rasom
		printB:
			mov dx, 'B'
			jmp rasom
		printC:
			mov dx, 'C'
			jmp rasom
		printD:
			mov dx, 'D'
			jmp rasom
		printE:
			mov dx, 'E'
			jmp rasom
		printF:
			mov dx, 'F'
			jmp rasom	
		PrintHexNumber endp
		devideBW proc near
			cmp byteDW, 00b
			jne kitas1
			mov w, 0
			mov d,0
			ret
		kitas1:
			cmp byteDW, 01b
			jne kitas2
			mov w, 1
			mov d, 0
			ret
		kitas2:
			cmp byteDW, 10b
			jne kitas3
			mov w,0
			mov d, 1
			ret
		kitas3:
			mov w,1
			mov d,1
			ret
		devideBW endp 
; **********************************************************
; FAILO VARDO SKAITYMO FUNKCIJA
; **********************************************************
	read_filename PROC near

		push		ax								;pasidedam ax į SS, kad nepasimestu reiksme		
		call		skip_spaces	
		MOV 		cx, 14 							;vienu maziau nes reikia pasilikti vietos '$' zenklui gale
	read_filename_start:
		cmp	byte ptr ds:[si], 13					; jei nera parametru
		je	read_filename_end						; tai taip, tai baigtas failo vedimas
		cmp	byte ptr ds:[si], ' '					; jei tarpas
		jne	read_filename_next						; tai praleisti visus tarpus, ir sokti prie kito parametro
	read_filename_end:
		mov	al, '$'									; irasyti '$' gale
		stosb                          				; Store AL at address ES:(E)DI, di = di + 1
		pop	ax
		ret
	read_filename_next:
		lodsb										; uzkrauna kita simboli
		stosb                           			; Store AL at address ES:(E)DI, di = di + 1
		LOOP read_filename_start
		JMP _end

	read_filename ENDP	
	
	printHexSimbol proc near
		mov dx, offset hex
		mov cx, 1
		call iFaila
		ret
	printHexSimbol endp
; **********************************************************
; HELP ATSPAUSDINIMO FUNKCIJA
; **********************************************************
	help:
	
		mov	ax, @data
		mov	ds, ax
		
		mov	dx, offset apie      
		mov	ah, 09h
		int	21h
		jmp _end

; **********************************************************
; ERROR  ATSPAUSDINIMO FUNKCIJA
; **********************************************************
	print_error:
		
		mov	ax, @data
		mov	ds, ax
		
		mov	dx, offset err_source      
		mov	ah, 09h
		int	21h

		jmp _end
	
; **********************************************************
; SKIP_SPACES FUNKCIJA
; **********************************************************		
	skip_spaces PROC near

	skip_spaces_loop:
		cmp 		byte ptr ds:[si], ' '
		jne 		skip_spaces_end
		inc 		si
		jmp 		skip_spaces_loop
	skip_spaces_end:
		ret
	
	skip_spaces ENDP	
; **********************************************************
; PROGRAMOS UZDARYMO FUNKCIJA
; **********************************************************
	_end:
		mov	bx, destFHandle	
		mov	ah, 3eh			
		int	21h
		
		mov	bx, sourceFHandle							
		mov	ah, 3eh									
		int	21h
	
		mov	ax, 4c00h
		int	21h
		
end START		