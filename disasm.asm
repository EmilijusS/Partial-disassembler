;Emilijus Stankus
;Programų sistemos 1 kursas 4 grupė 2015m.
;Disasembleris
;Reikalavimai: http://www.mif.vu.lt/~linas1/KompArch/Disasembleris.htm

.model small

.stack 100h

.data
;****************************************************************************************
;JUMPAI SU 1 BAITO POSLINKIU
;****************************************************************************************
;Visi 6 baitų ilgio, kad galėčiau su ciklu gražiai pereiti
	jumpai		db	'JMP', 9, 9, 0
				db	'JO', 9, 9, 0, 0
				db	'JNO', 9, 9, 0
				db	'JNAE', 9, 0
				db	'JAE', 9, 9, 0
				db	'JE', 9, 9, 0, 0
				db	'JNE', 9, 9, 0
				db	'JBE', 9, 9, 0
				db	'JA', 9, 9, 0, 0
				db	'JS', 9, 9, 0, 0
				db	'JNS', 9, 9, 0
				db	'JP', 9, 9, 0, 0
				db	'JNP', 9, 9, 0
				db	'JL', 9, 9, 0, 0
				db	'JGE', 9, 9, 0
				db	'JLE', 9, 9, 0
				db	'JG', 9, 9, 0, 0
				db	'JCXZ', 9, 0
				db	'LOOP', 9, 0

;****************************************************************************************
;VISI LIKE ATSKIRI
;****************************************************************************************
	neatpazinta	db	'NEATPAZINTA', 10, 0
	kodINT		db 	'INT', 9, 9, 0
	kodRET		db 	'RET', 9, 9, 0
	kodRETF		db 	'RETF', 9, 0
	kodCALL		db 	'CALL', 9, 0
	kodPUSH		db	'PUSH', 9, 0
	kodPOP		db	'POP', 9, 9, 0
	kodINC		db	'INC', 9, 9, 0
	kodDEC		db	'DEC', 9, 9, 0
	kodADD		db	'ADD', 9, 9, 0
	kodSUB		db	'SUB', 9, 9, 0
	kodCMP		db	'CMP', 9, 9, 0
	kodMOV		db	'MOV', 9, 9, 0
	kodDIV		db	'DIV', 9, 9, 0
	kodMUL		db	'MUL', 9, 9, 0

;****************************************************************************************
;REGISTRAI	(man patogiau žodinius pirmiau turėti, jų dažniau reikia)
;			EDIT: pasirodo nebūtinai patogiau, bet jau tiek to
;****************************************************************************************
	reg			db	'AX', 0
				db	'CX', 0
				db	'DX', 0
				db	'BX', 0
				db	'SP', 0
				db	'BP', 0
				db	'SI', 0
				db	'DI', 0
	regByte		db	'AL', 0
				db	'CL', 0
				db	'DL', 0
				db	'BL', 0
				db	'AH', 0
				db	'CH', 0
				db	'DH', 0
				db	'BH', 0

;****************************************************************************************
;SEGMENTINIAI REGISTRAI
;****************************************************************************************
	segreg		db 	'ES', 0
				db	'CS', 0
				db	'SS', 0
				db	'DS', 0

;****************************************************************************************
;ADRESACIJOS BAITAS
;****************************************************************************************
	adresB		db	'[BX+SI]', 0
				db	'[BX+DI]', 0
				db	'[BP+SI]', 0
				db	'[BP+DI]', 0
				db	'[SI]', 0, 0, 0, 0
				db	'[DI]', 0, 0, 0, 0
				db	'[BP]', 0, 0, 0, 0
				db	'[BX]', 0, 0, 0, 0
	byteptr		db	'byte ptr ', 0
	wordptr		db	'word ptr ', 0
	dwordptr	db 	'dword ptr ', 0

;****************************************************************************************
;KINTAMIEJI
;****************************************************************************************
	help				db "Disasembleris.", 10, 13, "Jei matote si pranesima, reiskia jus to norejote, arba neteisingai ivesti parametrai, arba nepavyko atidaryti/uzdaryti failu, arba ivyko klaida skaitant/rasant i/is failu", 10, 13, "Paleidimui reikalingi parametrai tokiu formatu: ", 34, "disasm.exe duom.com rez.asm", 34, 10, 13, "Darba atliko - Emilijus Stankus, Programu sistemu 1 kursas, 4 grupe$"
	duomFailas			db 14 dup (?)
	rezFailas			db 14 dup (?)
	duomHandle			dw ?
	rezHandle			dw ?
	duomBuferis			db 255 dup (?)
	rezBuferis			db 100 dup (?)
	buferioLikutis		db 0
	pozDuomBuferyje		dw ?
	failoPabaiga 		db 0
	poslinkis			dw 100h
	konvertavimui		dw ?
	konvertavimuiIlgis	dw ?
	sesiolikaWord		dw 10h
	sesiolikaByte		db 10h
	operacijosEilute	db 100 dup (?)
	operacijosIlgis		dw ?
	jumpoNr				dw ?
	prefiksas			db 4
	segmentoRegistras	db 4
	registras			db ?
	operanduIlgis		db ?
	ABmod				db ?
	ABreg				db ?
	ABrm				db ?
	dBitas				db ?
	sBitas				db ?
	arRasytiPtr			db ?
	duOperandai			db ?
	betOperandas		db ?

.code
pradzia:
	MOV ax, @data
	MOV es, ax

;****************************************************************************************
;PARAMETRŲ NUSKAITYMAS
;****************************************************************************************
	MOV ch, 0
	MOV cl, byte ptr ds:[0080h]			;Kiek parametrų simbolių buvo nuskaityta

	CMP cx, 0							;Jei neįvedė parametrų
	JNE parametruSkaitymas
	CALL pagalba
	JMP pabaiga

;Pirmas duomenų failas:

parametruSkaitymas:		
	MOV si, 0081h						
	MOV di, offset duomFailas

tarpuPraleidimas1:
	CMP byte ptr ds:[si], ' '			;Praleidžia tarpus
	JNE failoPavadinimoSkaitymas1
	INC si
	DEC cx
	JNE tarpuPraleidimas1
	CALL pagalba
	JMP pabaiga
failoPavadinimoSkaitymas1:
	CMP byte ptr ds:[si], ' '			;Skaito simbolius tol, kol neprieina tarpo
	JE skaitymoPabaiga1
	MOVSB								;Perkelinėja failo pavadinimą				
	DEC cx					
	JNE failoPavadinimoSkaitymas1		;Jei pasibaigė parametrai, reiškia jie buvo neteisingi
	CALL pagalba
	JMP pabaiga
skaitymoPabaiga1:
	MOV byte ptr es:[di], 0				;Įdeda nulinį simbolį eilutės pabaigai
	INC si;								;Kadangi dabar sustojęs ant tarpo
	DEC cx

;Rezultatų failas:

	MOV di, offset rezFailas
tarpuPraleidimas2:
	CMP byte ptr ds:[si], ' '			;Praleidžia tarpus
	JNE failoPavadinimoSkaitymas2
	INC si
	DEC cx
	JNE tarpuPraleidimas2
	CALL pagalba
	JMP pabaiga
failoPavadinimoSkaitymas2:
	CMP byte ptr ds:[si], ' '			;Skaito simbolius tol, kol neprieina tarpo
	JE skaitymoPabaiga2
	MOVSB								;Perkelinėja failo pavadinimą				
	DEC cx					
	JNE failoPavadinimoSkaitymas2		;Jei pasibaigė parametrai, reiškia jie buvo neteisingi
skaitymoPabaiga2:
	MOV byte ptr es:[di], 0				;Įdeda nulinį simbolį eilutės pabaigai

	CMP cx, 0							;Jei parametrai jau baigesi
	JE parametruPabaiga

likeTarpai:
	CMP byte ptr ds:[si], ' '			;Praleidžia tarpus
	JNE perDaugParametru
	INC si
	DEC cx
	JE parametruPabaiga
	JMP likeTarpai
perDaugParametru:
	CALL pagalba
	JMP pabaiga

parametruPabaiga:
	MOV ax, @data
	MOV ds, ax							
	
;****************************************************************************************
;FAILŲ ATIDARYMAS
;****************************************************************************************	

	MOV dx, offset duomFailas
	MOV al, 0h							;Tik skaitymui
	MOV ah, 3Dh
	INT 21h
	JNC duomFailoAtidarymoPabaiga		;Tikrina, ar sėkmingai atidarė failą
	CALL pagalba
	JMP pabaiga

duomFailoAtidarymoPabaiga:
	MOV duomHandle, ax					;Perkelia pirmo failo handle į atmintį

	MOV dx, offset rezFailas
	MOV al, 0
	MOV ah, 3Ch
	MOV cx, 0h							;Jokių failo atributų
	INT 21h
	JNC atidarymuPabaiga				;Tikrina, ar sėkmingai atidarė failą
	CALL pagalba
	JMP duomFailoUzdarymas

atidarymuPabaiga:
	MOV rezHandle, ax
	JMP skaitymas						;Kad neperkelinėtų rodyklės, nes pirmam kartui nereikia


;****************************************************************************************
;PAGRINDINIS CIKLAS
;****************************************************************************************
		
rodyklesPerkelimas:
	MOV cx, -1							;Perkeliu rodyklę atgal per nepanaudotų baitų kiekį (taip darau, kad garantuočiau, jog buferyje visada bus visa komanda ir nebus nukirptas jos galas)
	MOV dh, 0							
	MOV dl, buferioLikutis
	NEG dx
	MOV bx, duomHandle
	MOV al, 1							
	MOV ah, 42h
	INT 21h
	JNC skaitymas
	CALL pagalba
	JMP rezFailoUzdarymas

skaitymas:								; Nusiskaitau iš failo į buferį
	MOV bx, duomHandle
	MOV cx, 255							
	MOV dx, offset duomBuferis
	MOV ah, 3Fh
	INT 21h
	JNC pavykoNuskaityti
	CALL pagalba
	JMP rezFailoUzdarymas

pavykoNuskaityti:
	MOV pozDuomBuferyje, 0		
	MOV buferioLikutis, al				;Galėjau ir su vienu kintamuoju čia kaip nors apsieiti turbūt, bet bijau pasimesti (buferio likutis iš esmės reikalingas, kai baigsis failas)
    CMP al, 255							;Patikrina, kiek baitų buvo nuskaityta
    JE pagrindinisCiklas
    MOV failoPabaiga, 1

pagrindinisCiklas:
	CMP failoPabaiga, 1					;Kai baigėsi failas, tai buferį jau ištuštins iki galo
	JE pasibaigusFailui

	CMP buferioLikutis, 10				;Kad nebūtų perkirpta komanda
	JB rodyklesPerkelimas

pasibaigusFailui:
	MOV operacijosIlgis, 0				;Šitų dalykų nedarys, jei ras segmento keitimo prefiksą
	MOV prefiksas, 4					;4 reiškia, kad nėra

	;Iš buferio į al perkelia komandos kodą
	MOV bx, offset duomBuferis
	ADD bx, pozDuomBuferyje
	MOV al, byte ptr[bx]

komandosAtpazinimas:
;Dabar tikrins visas komandas (tik nelabai iš eilės turbūt)

	CALL nustSegReg						;Kad nereikėtų vėliau
	CALL nustReg
	CALL operanduIlgioNust
	INC bx								;Čia irgi patogu dabar, kai prieis komandos su OPK išplėtimu
	MOV al, byte ptr[bx]
	CALL ABnagrinejimas
	DEC bx
	MOV al, byte ptr[bx]

;1110 1011 poslinkis – JMP žymė (vidinis artimas)
tikJMPvidinisartimas:
	MOV jumpoNr, 0						;Aš čia pirma numerį įdedu, nes man to nulio reikės kitame žingsnyje vis tiek
	CMP al, 11101011b
	JNE tikSalyginiaiJumpai
	CALL grupe1apdorojimas
	JMP buferioIsvedimas
tikSalyginiaiJumpai:					;Iš kart visus 16 apdorosiu
	MOV dx, 0
	MOV ah, 0
	DIV sesiolikaWord
	CMP ax, 0111b
	JNE	tikJCXZ
	MOV jumpoNr, dx						;Liekana kaip numeris išeina
	INC jumpoNr							;Aš čia susimoviau pradžioje, tingiu keisti
	CALL grupe1apdorojimas
	JMP buferioIsvedimas
;1110 0011 poslinkis – JCXZ žymė
tikJCXZ:
	MOV al, byte ptr[bx]				;Kadangi sudirbau praeitame žingsnyje tą kodą
	CMP al, 11100011b
	JNE tikLOOP
	MOV jumpoNr, 17
	CALL grupe1apdorojimas
	JMP buferioIsvedimas
;1110 0010 poslinkis – LOOP žymė
tikLOOP:
	CMP al, 11100010b
	JNE tikINT
	MOV jumpoNr, 18
	CALL grupe1apdorojimas
	JMP buferioIsvedimas
;1100 1101 numeris – INT numeris
tikINT:
	CMP al, 11001101b
	JNE tikRET
	MOV si, offset kodINT
	CALL ikeltiPavadinima
	INC bx
	MOV dl, byte ptr [bx]
	MOV dh, 0
	MOV konvertavimui, dx
	MOV bx, di
	MOV konvertavimuiIlgis, 2
	CALL hexToAscii
	MOV byte ptr[bx], 10
	ADD operacijosIlgis, 2
	JMP buferioIsvedimas
;1100 0011 – RET
tikRET:
	CMP al, 11000011b
	JNE tikRETF
	MOV si, offset kodRET
	CALL ikeltiPavadinima
	MOV bx, di
	MOV byte ptr[bx], 10
	ADD operacijosIlgis, 1
	JMP buferioIsvedimas
;1100 1011 – RETF
tikRETF:
	CMP al, 11001011b
	JNE tikCALLisorinisTiesioginis
	MOV si, offset kodRETF
	CALL ikeltiPavadinima
	MOV bx, di
	MOV byte ptr[bx], 10
	ADD operacijosIlgis, 1
	JMP buferioIsvedimas
;1001 1010 ajb avb srjb srvb – CALL žymė (išorinis tiesioginis)
tikCALLisorinisTiesioginis:
	CMP al, 10011010b
	JNE tikJMPisorinisTiesioginis
	MOV si, offset kodCALL
	CALL isorinisTiesioginis
	JMP buferioIsvedimas
;1110 1010 ajb avb srjb srvb – JMP žymė (išorinis tiesioginis)
tikJMPisorinisTiesioginis:
	CMP al, 11101010b
	JNE tikPrefiksas
	MOV si, offset jumpai
	CALL isorinisTiesioginis
	JMP buferioIsvedimas
;001sr 110 – segmento registro keitimo prefiksas
tikPrefiksas:
	AND al, 11100111b						;Sunaikina vidurį tikrinimui, po šitų komandų atstatys
	CMP al, 00100110b
	JNE tikPUSHsr
	MOV dl, segmentoRegistras
	MOV prefiksas, dl
	INC operacijosIlgis
	INC bx
	MOV al, byte ptr[bx]
	JMP komandosAtpazinimas					;Jį prideda prie kitos komandos
;000sr 110 – PUSH segmento registras
tikPUSHsr:
	CMP al, 00000110b
	JNE tikPOPsr
	MOV si, offset kodPUSH
	CALL PUSHirPOPsr
	JMP buferioIsvedimas
;000sr 111 – POP segmento registras
tikPOPsr:
	CMP al, 00000111b
	JNE tikINCreg
	MOV si, offset kodPOP
	CALL PUSHirPOPsr
	JMP buferioIsvedimas
;0100 0reg – INC registras (žodinis)
tikINCreg:
	MOV al, byte ptr[bx]					;Atstatau pilną kodą
	AND al, 11111000b						;Ir vel sudirbu
	CMP al, 01000000b
	JNE tikDECreg
	MOV si, offset kodINC
	CALL regKom
	JMP buferioIsvedimas
;0100 1reg – DEC registras (žodinis)
tikDECreg:
	CMP al, 01001000b
	JNE tikPUSHreg
	MOV si, offset kodDEC
	CALL regKom
	JMP buferioIsvedimas
;0101 0reg – PUSH registras (žodinis)
tikPUSHreg:
	CMP al, 01010000b
	JNE tikPOPreg
	MOV si, offset kodPUSH
	CALL regKom
	JMP buferioIsvedimas
;0101 1reg – POP registras (žodinis)
tikPOPreg:
	CMP al, 01011000b
	JNE tikCALLvidinisTiesioginis
	MOV si, offset kodPOP
	CALL regKom
	JMP buferioIsvedimas
;1110 1000 pjb pvb – CALL žymė (vidinis tiesioginis)
tikCALLvidinisTiesioginis:
	MOV al, byte ptr[bx]				;Vėl atstatau
	CMP al, 11101000b
	JNE tikJMPvidinistiesioginis
	MOV si, offset kodCALL
	CALL vidinisTiesioginis
	JMP buferioIsvedimas
;1110 1001 pjb pvb – JMP žymė (vidinis tiesioginis)
tikJMPvidinistiesioginis:
	CMP al, 11101001b
	JNE tikADDakumBO
	MOV si, offset jumpai
	CALL vidinisTiesioginis
	JMP buferioIsvedimas
;0000 010w bojb [bovb] – ADD akumuliatorius += betarpiškas operandas
tikADDakumBO:
	AND al, 11111110b
	CMP al, 00000100b
	JNE tikSUBakumBO
	MOV si, offset kodADD
	MOV registras, 1
	CALL BOoperacijos
	JMP buferioIsvedimas
;0010 110w bojb [bovb] – SUB akumuliatorius -= betarpiškas operandas
tikSUBakumBO:
	CMP al, 00101100b
	JNE tikCMPakumBO
	MOV si, offset kodSUB
	MOV registras, 1
	CALL BOoperacijos
	JMP buferioIsvedimas
;0011 110w bojb [bovb] – CMP akumuliatorius ~ betarpiškas operandas
tikCMPakumBO:
	CMP al, 00111100b
	JNE tikRETBO
	MOV si, offset kodCMP
	MOV registras, 1
	CALL BOoperacijos
	JMP buferioIsvedimas
;1100 0010 bojb bovb – RET betarpiškas operandas
tikRETBO:
	MOV al, byte ptr[bx]
	CMP al, 11000010b
	JNE tikRETFBO
	MOV si, offset kodRET						;Čia neberašau komentarų, nes vis tiek nebedarau klaidų, o niekas kitas neskaitys šito
	MOV operanduIlgis, 1
	MOV registras, 0
	CALL BOoperacijos
	JMP buferioIsvedimas
;1100 1010 bojb bovb – RETF betarpiškas operandas
tikRETFBO:
	CMP al, 11001010b
	JNE tikMOVakumAtm
	MOV si, offset kodRETF
	MOV operanduIlgis, 1
	MOV registras, 0
	CALL BOoperacijos
	JMP buferioIsvedimas
;1010 000w ajb avb – MOV akumuliatorius <- atmintis
tikMOVakumAtm:
	AND al, 11111110b
	CMP al, 10100000b
	JNE tikMOVatmAkum
	MOV si, offset kodMOV
	CALL ikeltiPavadinima

	INC bx
	MOV ax, word ptr[bx]

	MOV si, offset reg
	CMP operanduIlgis, 1				;Tikrins ar operacija su ax ar su al
	JE nekeistiNesAX1
	MOV si, offset regByte						;Pakeičia į al
nekeistiNesAX1:
	CALL ikeltiStringa
	MOV bx, di
	MOV word ptr[bx], 202Ch					;čia kablelis ir tarpas 
	ADD bx, 2
	MOV byte ptr[bx], '['					
	INC bx
	MOV konvertavimui, ax
	MOV konvertavimuiIlgis, 4
	CALL hexToAscii
	MOV byte ptr[bx], ']'
	INC bx
	MOV byte ptr[bx], 10
	ADD operacijosIlgis, 3
	JMP buferioIsvedimas
;1010 001w ajb avb – MOV atmintis <- akumuliatorius
tikMOVatmAkum:
	CMP al, 10100010b
	JNE tikMOVregBO
	MOV si, offset kodMOV
	CALL ikeltiPavadinima
	INC bx
	MOV ax, word ptr[bx]
	MOV bx, di
	MOV byte ptr[bx], '['					
	INC bx
	MOV konvertavimui, ax
	MOV konvertavimuiIlgis, 4
	CALL hexToAscii
	MOV byte ptr[bx], ']'
	INC bx
	MOV word ptr[bx], 202Ch					;čia kablelis ir tarpas 
	ADD bx, 2
	MOV di, bx
	MOV si, offset reg
	CMP operanduIlgis, 1				;Tikrins ar operacija su ax ar su al
	JE nekeistiNesAX2
	MOV si, offset regByte						;Pakeičia į al
nekeistiNesAX2:
	CALL ikeltiStringa
	MOV bx, di
	MOV byte ptr[bx], 10
	ADD operacijosIlgis, 3
	JMP buferioIsvedimas
;1011 wreg bojb [bovb] – MOV registras <- betarpiškas operandas
tikMOVregBO:
	AND al, 11110000b
	CMP al, 10110000b
	JNE tikJMPisorinisNetiesioginis
	ADD operacijosIlgis, 2					;Skylių lopymas, todėl šitas pradžioje, jau tikrai netvarka čia darosi
	MOV si, offset kodMOV
	CALL ikeltiPavadinima
	MOV al, byte ptr[bx]					;Šita komanda nestandartiška, teks rašyti
	MOV ah, 0								;Iškrapštau tą w baitą
	MOV dl, 8
	DIV dl
	MOV dl, 2
	MOV ah, 0
	DIV dl
	MOV operanduIlgis, ah
	MOV si, offset reg
	CMP operanduIlgis, 1
	JE tikMOVregBOpab
	MOV si, offset regByte					;Pereina prie baitinių registrų
tikMOVregBOpab:
	MOV al, registras
	MOV ah, 0
	MOV dl, 3
	MUL dl
	ADD si, ax
	CALL ikeltiStringa

	INC bx
	MOV ax, word ptr[bx]
	MOV konvertavimui, ax
	MOV konvertavimuiIlgis, 2
	CMP operanduIlgis, 0
	JE baigtiTikMOVregBO
	ADD konvertavimuiIlgis, 2
	INC operacijosIlgis
baigtiTikMOVregBO:
	MOV bx, di
	MOV word ptr[bx], 202Ch
	ADD bx, 2
	CALL hexToAscii
	MOV byte ptr[bx], 10
	JMP buferioIsvedimas
;1111 1111 mod 101 r/m [poslinkis] – JMP adresas (išorinis netiesioginis)
tikJMPisorinisNetiesioginis:
	MOV al, byte ptr[bx]
	CMP al, 11111111b
	JE testitikJMPisorinisNetiesioginis
	JMP tikPOPregistrasAtmintis					;Per tolimi šuoliai, tai čia greitas taisymas
testitikJMPisorinisNetiesioginis:
	CMP ABreg, 101b
	JNE tikJMPvidinisNetiesioginis
	MOV si, offset jumpai
	MOV arRasytiPtr, 1
	MOV duOperandai, 0
	MOV betOperandas, 0
	MOV operanduIlgis, 2						;Čia, kad rašytų dword ptr, nieko kito sugadinti neturėtų
	CALL ABoperacijos
	JMP buferioIsvedimas
;1111 1111 mod 100 r/m [poslinkis] – JMP adresas (vidinis netiesioginis)
tikJMPvidinisNetiesioginis:
	CMP ABreg, 100b
	JNE tikCALLisorinisNetiesioginis
	MOV si, offset jumpai
	MOV arRasytiPtr, 1
	MOV duOperandai, 0
	MOV betOperandas, 0
	MOV operanduIlgis, 1
	CALL ABoperacijos
	JMP buferioIsvedimas
;1111 1111 mod 011 r/m [poslinkis] – CALL adresas (išorinis netiesioginis)
tikCALLisorinisNetiesioginis:
	CMP ABreg, 011b
	JNE tikCALLvidinisNetiesioginis
	MOV si, offset kodCALL
	MOV arRasytiPtr, 1
	MOV duOperandai, 0
	MOV betOperandas, 0
	MOV operanduIlgis, 2
	CALL ABoperacijos
	JMP buferioIsvedimas
;1111 1111 mod 010 r/m [poslinkis] – CALL adresas (vidinis netiesioginis)
tikCALLvidinisNetiesioginis:
	CMP ABreg, 010b
	JNE tikPUSHregistrasAtmintis
	MOV si, offset kodCALL
	MOV arRasytiPtr, 1
	MOV duOperandai, 0
	MOV betOperandas, 0
	MOV operanduIlgis, 1
	CALL ABoperacijos
	JMP buferioIsvedimas
;1111 1111 mod 110 r/m [poslinkis] – PUSH registras/atmintis
tikPUSHregistrasAtmintis:
	CMP ABreg, 110b
	JNE tikPOPregistrasAtmintis			;Čia nes nesutampa OPK plėtinys su niekuo 
	MOV si, offset kodPUSH
	MOV arRasytiPtr, 0
	MOV duOperandai, 0
	MOV betOperandas, 0
	MOV operanduIlgis, 1
	CALL ABoperacijos
	JMP buferioIsvedimas
;1000 1111 mod 000 r/m [poslinkis] – POP registras/atmintis
tikPOPregistrasAtmintis:
	CMP al, 10001111b
	JNE tikDIVregistrasAtmintis
	CMP ABreg, 000b
	JE testitikPOPregistrasAtmintis
	JMP neatpazintaOperacija
testitikPOPregistrasAtmintis:
	MOV si, offset kodPOP
	MOV arRasytiPtr, 0
	MOV duOperandai, 0
	MOV betOperandas, 0
	MOV operanduIlgis, 1
	CALL ABoperacijos
	JMP buferioIsvedimas
;1111 011w mod 110 r/m [poslinkis] – DIV registras/atmintis
tikDIVregistrasAtmintis:
	AND al, 11111110b
	CMP al, 11110110b
	JNE tikDECregistrasAtmintis
	CMP ABreg, 110b
	JNE tikMULregistrasAtmintis
	MOV si, offset kodDIV
	MOV arRasytiPtr, 1
	MOV duOperandai, 0
	MOV betOperandas, 0
	CALL ABoperacijos
	JMP buferioIsvedimas
;1111 011w mod 100 r/m [poslinkis] – MUL registras/atmintis
tikMULregistrasAtmintis:
	CMP ABreg, 100b
	JE testitikMULregistrasAtmintis
	JMP neatpazintaOperacija
testitikMULregistrasAtmintis:
	MOV si, offset kodMUL
	MOV arRasytiPtr, 1
	MOV duOperandai, 0
	MOV betOperandas, 0
	CALL ABoperacijos
	JMP buferioIsvedimas
;1111 111w mod 001 r/m [poslinkis] – DEC registras/atmintis
tikDECregistrasAtmintis:
	CMP al, 11111110b
	JNE tikMOVregistrasAtmintisBO
	CMP ABreg, 001b
	JNE tikINCregistrasAtmintis
	MOV si, offset kodDEC
	MOV arRasytiPtr, 1
	MOV duOperandai, 0
	MOV betOperandas, 0
	CALL ABoperacijos
	JMP buferioIsvedimas
;1111 111w mod 000 r/m [poslinkis] – INC registras/atmintis
tikINCregistrasAtmintis:
	CMP ABreg, 000b
	JE testitikINCregistrasAtmintis
	JMP neatpazintaOperacija
testitikINCregistrasAtmintis:
	MOV si, offset kodINC
	MOV arRasytiPtr, 1
	MOV duOperandai, 0
	MOV betOperandas, 0
	CALL ABoperacijos
	JMP buferioIsvedimas
;1100 011w mod 000 r/m [poslinkis] bojb [bovb] – MOV registras/atmintis <- betarpiškas operandas
tikMOVregistrasAtmintisBO:
	CMP al, 11000110b
	JNE tikADDregistrasAtmintisBO
	CMP ABreg, 000b
	JE testitikMOVregistrasAtmintisBO
	JMP neatpazintaOperacija
testitikMOVregistrasAtmintisBO:
	MOV si, offset kodMOV
	MOV arRasytiPtr, 1
	MOV duOperandai, 0
	MOV betOperandas, 1
	CALL ABoperacijos
	JMP buferioIsvedimas
;1000 00sw mod 000 r/m [poslinkis] bojb [bovb] – ADD registras/atmintis += betarpiškas operandas
tikADDregistrasAtmintisBO:
	AND al, 11111100b
	CMP al, 10000000b
	JNE tikMOVregistrasAtmintis
	CMP ABreg, 000b
	JNE tikSUBregistrasAtmintisBO
	MOV si, offset kodADD
	MOV arRasytiPtr, 1
	MOV duOperandai, 0
	MOV betOperandas, 1
	CALL ABoperacijos
	JMP buferioIsvedimas
;1000 00sw mod 101 r/m [poslinkis] bojb [bovb] – SUB registras/atmintis -= betarpiškas operandas
tikSUBregistrasAtmintisBO:
	CMP ABreg, 101b
	JNE tikCMPregistrasAtmintisBO
	MOV si, offset kodSUB
	MOV arRasytiPtr, 1
	MOV duOperandai, 0
	MOV betOperandas, 1
	CALL ABoperacijos
	JMP buferioIsvedimas
;1000 00sw mod 111 r/m [poslinkis] bojb [bovb] – CMP registras/atmintis ~ betarpiškas operandas
tikCMPregistrasAtmintisBO:
	CMP ABreg, 111b
	JE testitikCMPregistrasAtmintisBO
	JMP neatpazintaOperacija
testitikCMPregistrasAtmintisBO:
	MOV si, offset kodCMP
	MOV arRasytiPtr, 1
	MOV duOperandai, 0
	MOV betOperandas, 1
	CALL ABoperacijos
	JMP buferioIsvedimas
;1000 10dw mod reg r/m [poslinkis] – MOV registras <-> registras/atmintis
tikMOVregistrasAtmintis:
	CMP al, 10001000b
	JNE tikSUBregistrasAtmintis
	MOV si, offset kodMOV
	MOV arRasytiPtr, 0
	MOV duOperandai, 1
	MOV betOperandas, 0
	CALL ABoperacijos
	JMP buferioIsvedimas
;0010 10dw mod reg r/m [poslinkis] – SUB registras -= registras/atmintis
tikSUBregistrasAtmintis:
	CMP al, 00101000b
	JNE tikCMPregistrasAtmintis
	MOV si, offset kodSUB
	MOV arRasytiPtr, 0
	MOV duOperandai, 1
	MOV betOperandas, 0
	CALL ABoperacijos
	JMP buferioIsvedimas
;0011 10dw mod reg r/m [poslinkis] – CMP registras ~ registras/atmintis
tikCMPregistrasAtmintis:
	CMP al, 00111000b
	JNE tikADDregistrasAtmintis
	MOV si, offset kodCMP
	MOV arRasytiPtr, 0
	MOV duOperandai, 1
	MOV betOperandas, 0
	CALL ABoperacijos
	JMP buferioIsvedimas
;0000 00dw mod reg r/m [poslinkis] – ADD registras += registras/atmintis
tikADDregistrasAtmintis:
	CMP al, 00000000b
	JNE tikMOVsegregistrasAtmintis
	MOV si, offset kodADD
	MOV arRasytiPtr, 0
	MOV duOperandai, 1
	MOV betOperandas, 0
	CALL ABoperacijos
	JMP buferioIsvedimas
;1000 11d0 mod 0sr r/m [poslinkis] – MOV segmento registras <-> registras/atmintis
tikMOVsegregistrasAtmintis:
	MOV al, byte ptr[bx]
	AND al, 11111101b
	CMP al, 10001100b
	JNE neatpazintaOperacija			
	CMP ABreg, 100b
	JAE neatpazintaOperacija
	MOV si, offset kodMOV						;Šita nestandartinė, atskiras apdorojimas
	MOV arRasytiPtr, 0
	MOV operanduIlgis, 1
	MOV betOperandas, 0

	ADD operacijosIlgis, 2				
	MOV dx, bx							;Kadangi RM įrašymui reikia išsaugoti poziciją duomenų buferyje (ir pozDuomBuferyje kintamasis gali neteisingai rodyti dėl prefikso)
	CALL ikeltiPavadinima

	CMP dBitas, 0
	JE isREGiRMSEG

	MOV bx, di							;Čia įrašo reg <- r/m
	CALL irasoSREG
	MOV word ptr[bx], 202Ch
	ADD bx, 2
	CALL irasoRM
	JMP SEGMOVpabaiga

isREGiRMSEG:								;Įrašo visą operaciją
	MOV bx, di
	CALL irasoRM
	MOV word ptr[bx], 202Ch
	ADD bx, 2
	CALL irasoSREG

SEGMOVpabaiga:
	MOV byte ptr[bx], 10
	INC bx

	JMP buferioIsvedimas

neatpazintaOperacija:
	INC operacijosIlgis
	MOV si, offset neatpazinta
	CALL ikeltiPavadinima

buferioIsvedimas:
;Į buferį įdeda poslinkį, mašininį kodą, pačią komandą ir buferį išveda

;Įrašo poslinkį į buferį:
	MOV bx, poslinkis
	MOV konvertavimui, bx
	MOV bx, offset rezBuferis
	MOV konvertavimuiIlgis, 4
	CALL hexToAscii
	MOV word ptr [bx], 093Ah			;3A - ':', 09 - TAB
	ADD bx, 2

;Įrašo mašininį kodą:
	MOV cx, operacijosIlgis
	MOV ah, 0
masKodoRasymoCiklas:
	MOV dx, bx							;Išsisaugau čia bx
	MOV bx, offset duomBuferis
	ADD bx, pozDuomBuferyje
	ADD bx, operacijosIlgis
	SUB bx, cx
	MOV al, byte ptr[bx]
	MOV konvertavimui, ax
	MOV konvertavimuiIlgis, 2
	MOV bx, dx
	CALL hexToAscii
	LOOP masKodoRasymoCiklas

	MOV byte ptr [bx], 9
	INC bx

	CMP operacijosIlgis, 6
	JAE operacijosIrasymas				;Jei kodas trumpesnis nei 6 baitai reikia antro tabo
	MOV byte ptr [bx], 9
	INC bx

	CMP operacijosIlgis, 4
	JAE operacijosIrasymas				;Jei kodas trumpesnis nei 4 baitai reikia trčio tabo
	MOV byte ptr [bx], 9
	INC bx 

	CMP operacijosIlgis, 2
	JAE operacijosIrasymas				;Jei kodas trumpesnis nei 2 baitai reikia ketvirto tabo
	MOV byte ptr [bx], 9
	INC bx

operacijosIrasymas:
	MOV si, offset operacijosEilute
	MOV di, bx
operacijosIrasymoCiklas:
	CMP byte ptr[si], 10				;Kol prieis naujos eilutės simbolį 
	JE rasymasIFaila
	MOVSB
	JMP operacijosIrasymoCiklas

rasymasIFaila:
	MOVSB								;Perkelia naujos eilutės simbolį

	;Irašo buferį į failą
	MOV cx, offset rezBuferis			;Suskaičiuoja, kiek baitų įrašyti į failą
	SUB cx, di
	NEG cx
	MOV dx, offset rezBuferis
	MOV bx, rezHandle
	MOV ah, 40h
	INT 21h
	JNC pagrindinioCikloPabaiga
	CALL pagalba
	JMP rezFailoUzdarymas

pagrindinioCikloPabaiga:
	MOV ax, operacijosIlgis
	ADD pozDuomBuferyje, ax
	ADD poslinkis, ax
	SUB buferioLikutis, al				;Baigėsi failas
	JBE rezFailoUzdarymas

	JMP pagrindinisCiklas


;****************************************************************************************
;FAILŲ UŽDARYMAS
;****************************************************************************************


rezFailoUzdarymas:
	MOV bx, rezHandle
	MOV ah, 3Eh
	INT 21h
	JNC duomFailoUzdarymas
	CALL pagalba
duomFailoUzdarymas:
	MOV bx, duomHandle
	MOV ah, 3Eh
	INT 21h
	JNC pabaiga
	CALL pagalba

;****************************************************************************************
;PABAIGA
;****************************************************************************************

pabaiga: 
	MOV	ah, 4Ch			
	INT	21h	

;****************************************************************************************
;PROCEDŪROS
;****************************************************************************************
;Įrašo sreg ten, kur rodo bx (iš tiesų tik vienai komandai naudojama)
PROC irasoSREG
	PUSH ax

	MOV si, offset segreg
	MOV di, bx

	MOV ax, 3
	MUL ABreg
	ADD si, ax
	CALL ikeltiStringa
	MOV bx, di

	POP ax
	RET
ENDP irasoSREG

;Įrašo reg ten, kur rodo bx
PROC irasoREG
	PUSH ax

	MOV si, offset reg
	MOV di, bx
	CMP operanduIlgis, 1
	JE irasytiREG
	MOV si, offset regByte
irasytiREG:
	MOV ax, 3
	MUL ABreg
	ADD si, ax
	CALL ikeltiStringa
	MOV bx, di

	POP ax
	RET
ENDP irasoREG

;Irašo r/m ten, kur rodo bx, tuo tarpu į dx įrašytas adresas į operacijos kodą duomenų buferyje
PROC irasoRM
	PUSH ax
	
	CMP ABmod, 3
	JNE operandasNeRegistras
	JMP operandasRegistras

operandasNeRegistras:
	CMP arRasytiPtr, 0
	JE neraPtr

	MOV di, bx							;Čia tuos byte ptr arba word ptr parašo, jei reikia
	MOV si, offset byteptr
	MOV ax, 10
	MUL operanduIlgis
	ADD si, ax

	CALL ikeltiStringa
	MOV bx, di							;Gal reikėjo man visur rašymui naudoti di, gal nieko nebūtų nutikę, dabar painu išeina labai

neraPtr:

	CMP prefiksas, 4
	JE neraPrefikso

	MOV di, bx							;Jei yra prefiksas, tada prideda segmento registrą
	MOV si, offset segreg
	MOV ax, 3
	MUL prefiksas
	ADD si, ax
	CALL ikeltiStringa
	MOV bx, di
	MOV byte ptr[bx], ':'
	INC bx

neraPrefikso:

	CMP ABmod, 0
	JNE operandasNormalus
	CMP ABrm, 110b
	JNE operandasNormalus
	
	ADD operacijosIlgis, 2					;Čia reiškia bus tiesioginė adresacija
	MOV di, bx							
	MOV bx, dx
	ADD bx, 2
	MOV ax, word ptr[bx]
	MOV konvertavimui, ax
	MOV konvertavimuiIlgis, 4
	MOV bx, di
	MOV byte ptr[bx], '['
	INC bx
	CALL hexToAscii
	MOV byte ptr[bx], ']'
	INC bx
	JMP irasoRMpabaiga

operandasNormalus:
	
	MOV al, ABmod						;Padidina atitinkamai kiek reikia operacijos ilgį
	MOV ah, 0
	ADD operacijosIlgis, ax

	MOV di, bx							
	MOV si, offset adresB
	MOV ax, 8
	MUL ABrm
	ADD si, ax
	CALL ikeltiStringa

	MOV bx, di
	CMP ABmod, 0
	JE irasoRMpabaiga

	MOV byte ptr[bx], '+'
	INC bx
	MOV di, bx
	MOV bx, dx							;Įrašo poslinkį
	ADD bx, 2
	MOV ax, word ptr[bx]				
	MOV konvertavimui, ax
	MOV al, ABmod
	ADD al, ABmod						;Čia atseit daugyba iš 2
	MOV ah, 0
	MOV konvertavimuiIlgis, ax
	MOV bx, di		
	CALL hexToAscii
	JMP irasoRMpabaiga

operandasRegistras:
	MOV si, offset reg
	MOV di, bx
	CMP operanduIlgis, 0
	JNE irasytiRegistra
	MOV si, offset regByte
irasytiRegistra:
	MOV ax, 3
	MUL ABrm
	ADD si, ax
	CALL ikeltiStringa
	MOV bx, di

irasoRMpabaiga:
	POP ax
	RET
ENDP irasoRM

;Ištraukia mod reg ir r/m iš adresacijos baito (jis turėtų būti į al įrašytas)
PROC ABnagrinejimas
	PUSH ax
	PUSH dx

	MOV dl, 8
	DIV dl
	MOV ABrm, ah
	MOV ah, 0
	DIV dl
	MOV ABreg, ah
	MOV ABmod, al

	POP dx
	POP ax
	RET
ENDP ABnagrinejimas

;Komandos su adresacijos baitu (išskyrus ta su segmentiniais registrais, ji taip viską gadina)
PROC ABoperacijos
	ADD operacijosIlgis, 2				;Iš tiesų nusprendžiau, kad naujas standartas bus rašyti šitą pradžioje, o visi kiti variantai yra nestandartiški
	MOV dx, bx							;Kadangi RM įrašymui reikia išsaugoti poziciją duomenų buferyje (ir pozDuomBuferyje kintamasis gali neteisingai rodyti dėl prefikso)
	CALL ikeltiPavadinima

	CMP duOperandai, 0
	JE isREGiRM
	CMP dBitas, 0
	JE isREGiRM

	MOV bx, di							;Čia įrašo reg <- r/m
	CALL irasoREG
	MOV word ptr[bx], 202Ch
	ADD bx, 2
	CALL irasoRM
	JMP BOtikrinimas


isREGiRM:								;Įrašo visą operaciją
	MOV bx, di
	CALL irasoRM
	CMP duOperandai, 0
	JE BOtikrinimas
	MOV word ptr[bx], 202Ch
	ADD bx, 2
	CALL irasoREG


BOtikrinimas:
	CMP betOperandas, 0
	JE ABoperacijosPabaiga

	MOV word ptr[bx], 202Ch
	ADD bx, 2

	MOV di, bx							;Aš čia taip pasidedu, vėliau grąžinsiu
	MOV bx, dx							;Įrašys betarpišką operandą
	ADD bx, operacijosIlgis
	CMP prefiksas, 4
	JE nereikiaAtimtiIsBX
	DEC bx								;Dėl prefikso operacijos ilgis 1 ilgesnis
nereikiaAtimtiIsBX:
	MOV ax, word ptr[bx]
	MOV bx, di

	CMP operanduIlgis, 0
	JE vienoBaitoPoslinkis
	CMP sBitas, 1
	JE vienoBaitoPoslinkis

	ADD operacijosIlgis, 2				;Dveijų baitų poslinkis
	MOV konvertavimui, ax
	MOV konvertavimuiIlgis, 4
	CALL hexToAscii
	JMP ABoperacijosPabaiga

vienoBaitoPoslinkis:					;Vieno baito poslinkis arba s bitas aktyvuotas
	INC operacijosIlgis
	MOV konvertavimui, ax
	MOV konvertavimuiIlgis, 2
	CALL hexToAscii

ABoperacijosPabaiga:
	MOV byte ptr[bx], 10
	INC bx
	RET
ENDP ABoperacijos

;Komandos su betarpiškais operandais
PROC BOoperacijos
	PUSH ax

	ADD operacijosIlgis, 3				;Čia taip netradiciškai pradžioje

	CALL ikeltiPavadinima
	INC bx
	MOV ax, word ptr[bx]
	MOV konvertavimui, ax
	MOV konvertavimuiIlgis, 2
	CMP operanduIlgis, 0
	JE baigtiBO
	ADD konvertavimuiIlgis, 2
	MOV bx, di
baigtiBO:
	CMP registras, 0					;Šiuo atveju 1 reiškia, kad operacija su akumuliatoriumi
	JE tikraiBaigtiBO
	MOV si, offset reg

	CMP operanduIlgis, 1				;Tikrins ar operacija su ax ar su al
	JE nekeistiNesAX
	MOV si, offset regByte				;Pakeičia į al
	DEC operacijosIlgis
nekeistiNesAX:
	CALL ikeltiStringa
	MOV bx, di
	MOV word ptr[bx], 202Ch
	ADD bx, 2
tikraiBaigtiBO:
	CALL hexToAscii
	MOV byte ptr[bx], 10

	POP ax
	RET
ENDP BOoperacijos

;Ištraukia bitą w iš operacijos kodo pabaigos. Vėliau supratau, kad man reikia ir d (arba s) bito, tai šitas ištraukia ir tą.
PROC operanduIlgioNust
	PUSH ax
	PUSH dx

	MOV ah, 0
	MOV dl, 2
	DIV dl
	MOV operanduIlgis, ah
	DIV dl
	MOV dBitas, ah
	MOV sBitas, ah

	POP dx
	POP ax
	RET
ENDP operanduIlgioNust

;Apdoroja komandas su vidiniu tiesioginiu adresavimu
PROC vidinisTiesioginis
	PUSH ax

	CALL ikeltiPavadinima
	INC bx
	MOV ax, word ptr[bx]
	ADD ax, poslinkis
	MOV konvertavimui, ax
	ADD ax, 3
	MOV konvertavimuiIlgis, 4
	MOV bx, di
	CALL hexToAscii
	MOV byte ptr[bx], 10
	ADD operacijosIlgis, 3

	POP ax
	RET
ENDP vidinisTiesioginis

;Apdoroja keturias vieno baito komandas dirbančias su registrais
PROC regKom
	PUSH ax
	PUSH dx

	CALL ikeltiPavadinima
	MOV si, offset reg
	MOV al, registras
	MOV ah, 0
	MOV dl, 3
	MUL dl
	ADD si, ax
	CALL ikeltiStringa
	MOV bx, di
	MOV byte ptr[bx], 10
	ADD operacijosIlgis, 1

	POP dx
	POP ax
	RET
ENDP regKom
;Vieno baito operacijose nustato, su kokiu registru dirbama
PROC nustReg
	PUSH ax
	PUSH dx

	MOV ah, 0
	MOV dl, 8
	DIV dl
	MOV registras, ah

	POP dx
	POP ax
	RET
ENDP nustReg

;Apdoroja PUSH ir POP su dirbančius su segmentiniais registrais
PROC PUSHirPOPsr
	CALL ikeltiPavadinima
	MOV bx, di
	MOV si, offset segreg
	MOV ax, 3							;Po tiek simbolių segreg pavadinimai (su 0)
	MUL segmentoRegistras
	ADD si, ax
	MOV di, bx
	CALL ikeltiStringa
	MOV bx, di
	MOV byte ptr[bx], 10
	ADD operacijosIlgis, 1
	RET
ENDP PUSHirPOPsr

;Iš al esančio baito nustato ir įrašo, koks registras naudojamas į segmentoRegistras
PROC nustSegReg
	PUSH ax
	PUSH dx

	MOV ah, 0
	MOV dl, 8
	DIV dl
	MOV ah, 0
	MOV dl, 4
	DIV dl
	MOV segmentoRegistras, ah

	POP dx
	POP ax

	RET
ENDP nustSegReg

;Apdoroja porą komandų, kurios kviečia adresą tiesiogiai
PROC isorinisTiesioginis
	CALL ikeltiPavadinima
	INC bx
	MOV ax, word ptr[bx]
	ADD bx, 2
	MOV dx, word ptr[bx]
	MOV konvertavimui, ax
	MOV konvertavimuiIlgis, 4
	MOV bx, di
	CALL hexToAscii
	MOV byte ptr[bx], ':'
	INC bx
	MOV konvertavimui, dx
	CALL hexToAscii
	MOV byte ptr[bx], 10
	ADD operacijosIlgis, 5
	RET
ENDP isorinisTiesioginis

;Apdoroja 1 baito poslinkio jumpus
PROC grupe1apdorojimas
	PUSH ax
	PUSH bx

	MOV si, offset jumpai				;Čia prasideda jumpų komandų pavadinimai
	MOV ax, jumpoNr
	MOV ah, 6							;Visi pavadinimai po 6 baitus ten padaryti
	MUL ah
	ADD si, ax
	CALL ikeltiPavadinima

	MOV ax, poslinkis
	MOV konvertavimui, ax
	INC bx								;bx atrodo nekeičiau iki čia, tai vis dar turėtų rodyti į komandos kodą skaitymo buferyje
	MOV al, byte ptr[bx]
	CMP al, 127
	JA neigiamasPoslinkis
	MOV ah, 0
	ADD konvertavimui, ax
	JMP poslinkioIkelimasIEilute
neigiamasPoslinkis:
	MOV ah, 0FFh
	NEG ax
	SUB konvertavimui, ax

poslinkioikelimasIEilute:
	ADD konvertavimui, 2				;Nes ip rodo į kitą komandą
	MOV konvertavimuiIlgis, 4
	MOV bx, di
	CALL hexToAscii
	MOV byte ptr[bx], 10

	ADD operacijosIlgis, 2

	POP bx
	POP ax

	RET
ENDP grupe1apdorojimas

;Kelia iš si į di kol sutinka 0
PROC ikeltiStringa
	strIkelimoCiklas:
	CMP byte ptr [si], 0
	JE strPerkelimoPabaiga
	MOVSB
	JMP strIkelimoCiklas
strPerkelimoPabaiga:
	RET
ENDP ikeltiStringa

;Ikelia komandos pavadinima iš si į operacijosEilute
PROC ikeltiPavadinima
	MOV di, offset operacijosEilute
pavIkelimoCiklas:
	CMP byte ptr [si], 0
	JE perkelimoPabaiga
	MOVSB
	JMP pavIkelimoCiklas
perkelimoPabaiga:
	RET
ENDP ikeltiPavadinima

;Konvertuoja skaičių esantį kintamajame "konvertavimui" ir įrašo jį ten, kur rodo bx (veikia su baitais ir žodžiais)
PROC hexToAscii
	PUSH ax
	PUSH cx
	PUSH dx

	MOV cx, konvertavimuiIlgis

	MOV ax, konvertavimui

konvertuoja:							;Prastumia visus simbolius į steką
	MOV dx, 0
	DIV sesiolikaWord
	CMP dx, 9
	JA pridetiRaide
	ADD dx, '0'
	JMP ikeltiISteka
pridetiRaide:
	ADD dx, 55

ikeltiISteka:
	PUSH dx
	LOOP konvertuoja

	MOV cx, konvertavimuiIlgis	

iraso:									;Iš steko įdeda ten kur rodo bx
	POP [bx]							;Čia netyčia veikia, tikiuosi veiks ir toliau
	INC bx
	LOOP iraso

	POP dx
	POP cx
	POP ax
	RET
ENDP hexToAscii


;Pagalbos pranešimo išvedimas
PROC pagalba
	PUSH dx								;Kad galėtų grąžinti registrų reikšmes
	PUSH ax

	MOV ax, @data
	MOV ds, ax							;Kadangi šitas dar gali būti nenustatytas
	
	MOV dx, offset help					;Išveda pagalbos pranešimą
	MOV ah, 09h
	INT 21h

	POP ax
	POP dx
	RET
ENDP pagalba

END pradzia