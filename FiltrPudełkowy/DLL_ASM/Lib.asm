;///////////////////////////////////////////////////////////////////////////////
;	Biblioteka zawiera nastêpuj¹ce procedury:
;	- rozmycie w poziomie (BoxBlurHorizontal),
;	- rozmycie w pionie (BoxBlurVertical),
;	- obliczenie wielkoœci 'pude³ek' dla przebiegów algorytmu (GetBoxes).
;/////////////////////////////////////////////////////////////////////////////
OPTION CASEMAP:NONE					

.CONST								; segment dla sta³ych
	twelve_d real8 12.0				; sta³a liczbowa 12.0 w real8
	one_d real8 1.0					; sta³a liczbowa 1.0 w real8

.CODE
;*****************************************************************
;* Makro s³u¿¹ca do za³adowania piksela w formacie RGBA (DWORD) 32 z bufora wskazanego przez source i pozycji wskazanej
;* przez offset do rejestru docelowego sse (sseDest), przy pomocy rejestru ogólnego przeznaczania dest i wyzerowanego rejestru sse,
;* wskazywanego przez ss0.
;******************************************************************
LOADPIXEL MACRO source, offset, dest, sseDest, sse0 
	mov dest, dword ptr[source + offset]; pobierz wartoœæ elementu z bufora wyjœciowego na podstawie rejestru Ÿród³owego i zadanego offsetu
	movd sseDest, dest					; skopiuj j¹ do docelowego rejestru sse
	punpcklbw sseDest, sse0				; wypakuj 32 bity do 64 bitów w docelowym rejestrze sse, w którym wszystkie æwiartki s¹ na 0
	punpcklwd sseDest, sse0				; wypakuj 64 bity do 128 bitów w docelowym rejestrze sse, w którym wszystkie æwiartki s¹ na 0
ENDM

;*****************************************************************
;* Makro s³u¿¹ce do za³adowania obliczonego piksela z rejestru sse sseSource do bufora wskazywanego przez rejestr dest i offset.
;* U¿ywane s¹ tak¿e rejestry:
;* - sseTemp - do tymczasowych obliczeñ w rejestrze sse, 
;* - sseWeight - rejestr z wag¹ pikseli,
;* - sse0 - wyzerowany rejestr sse,
;* - temp - tymczasowy rejestr ogólnego przeznaczenia.
;******************************************************************
DIVANDUNLOADPIXEL MACRO sseTemp, sseSource, sseWeight, sse0, temp, dest, offset
	movdqa sseTemp, sseSource			; przekopiuj wartoœæ z rejestru sse, który zawiera wartoœæ do zapisu w buforze do roboczego rejestru sse
	cvtdq2ps sseTemp, sseTemp			; przekonwertuj æwiartki w roboczym rejestrze z dword na real4
	divps sseTemp, sseWeight			; podziel ka¿d¹ æwiartkê przez rejestr sse zawieraj¹cy wagê
	cvttps2dq sseTemp, sseTemp			; przekonwertuj æwiartki w roboczym rejestrze z real4 na dword z obciêciem
	packusdw sseTemp, sse0				; zapakuj 128 bitów do 64 bitowych s³ów
	packuswb sseTemp, sse0				; zapakuj 64 bity do 32 bitowych s³ów
	movd temp, sseTemp					; przepisz wartoœæ z roboczego rejestru sse do roboczego rejestru ogólnego przeznaczenia
	mov dword ptr[dest + offset], temp	; zapisz wartoœæ do bufora wyjœciowego
ENDM

;*****************************************************************
;* Wykonuje przebieg filtru 'box filter' dla wierszy w obrazie. Przekazywane argumenty:
;* - adres kana³u wejœciowego (channelPtr),
;* - adres kana³u wyjœciowego (outputChannelPtr),
;* - szerokoœæ wiersza (rowWidth),
;* - promieñ (radius);
;******************************************************************
BoxBlurHorizontal proc uses rax rbx rcx rdx rsi rbp rdi channelPtr: PTR DWORD, outputChannelPtr: PTR DWORD, rowWidth: DWORD, radius: DWORD
	; zapis argumentów funkcji do wolnych rejestrów:
	mov rsi, rcx							; zapisz adres kana³u wejœciowego do rsi
	mov rdi, rdx							; zapisz adres kana³u wyjœciowego do rdi
	mov r12, r8								; zapisz szerokoœæ wiersza do r12
	mov r13, r9								; zapisz promieñ do r13

	xor rdx, rdx							; wyzeruj rejestr rdx
	mov rax, r12							; pobierz szerokoœæ wiersza do rax
	shr rax, 1								; podziel przez 2 zaokr¹glaj¹c w dó³ (przesuñ bity w prawo o jedn¹ pozycjê)
	dec rax									; a nastêpnie zdekrementuj
	cmovs rax, rdx							; wyzeruj rejestr rax jeœli jest ujemny
	mov rax, r13							; pobierz promieñ do rdx
	mov r13, rax							; zapisz promieñ do rejestru r13, który przechowuje wartoœæ promienia dla przebiegu algorytmu
	shl rax, 1								; podwój promieñ w rejestrze rax (przesuwaj¹cy bity o jedn¹ pozycjê w lewo)
	inc rax									; zinkrementuj uzyskuj¹c œrednicê 'pude³ka'
	movd xmm7, rax							; za³aduj œrednicê do rejestru xmm7, w którym pozostanie do koñca procedury
	shufps xmm7, xmm7, 0					; skopiuj œrednicê do ka¿dego 32-bitowego kana³u (4 identyczne æwiartki w rejestrze xmm7)
	cvtdq2ps xmm7, xmm7						; przekonwertuj wartoœci œrednicy zawartych w æwiartkach w rejestrze xmm7 z dword na real4

	mov r8, 0								; zapisz zero do r8 - rejestru z indeksem dla elementu wyjœciowego
	mov r9, 0								; zapisz zero do r9 - rejestru z indeksem dla elementu o promieñ na lewo od wyjœciowego
	mov r10, r13							; zapisz wartoœæ promienia do r10 - rejestru z indeksem dla elementu na prawo od wyjœciowego

	; Przetwarzanie kana³u:
	xorps xmm0, xmm0						; wyzeruj rejestr xmm0, który bêdzie s³u¿y³ do operacji pakowania i rozpakowywania
	xorps xmm3, xmm3						; wyzeruj rejestr xmm3 - rejestr przeznaczony na wartoœæ wyjœciow¹
	LOADPIXEL rsi, 0, ebx, xmm1, xmm0		; za³aduj piksel najbardziej na lewo do rejestru xmm1
	mov rax, r12							; za³aduj szerokoœæ wiersza do rax
	dec rax									; nastêpnie j¹ zdekrementuj
	LOADPIXEL rsi, rax * 4, ebx, xmm2, xmm0	; za³aduj ostatni piksel w wierszu do rejestru xmm2
	mov rax, r13							; za³aduj promieñ do rax
	inc rax									; nastêpnie go zinkrementuj
	movd xmm4, rax							; i zapisz do rejestru xmm4
	shufps xmm4, xmm4, 0					; i przetasuj (shuffle) rejestr, tak by wyst¹pi³ w ka¿dej æwiartce jako dword
	movdqa xmm3, xmm1						; skopiuj piksel najbardziej na lewo do rejestru xmm3
	pmulld xmm3, xmm4						; przemnó¿ przez promieñ + 1 (wartoœæ w rejestrze xmm4)
	
	xor rcx, rcx							; wyzeruj rejestr rcx, który bêdzie licznikiem dla pêtli nr 1
loop_1:
	cmp rcx, r13							; porównaj licznik z promieniem
	jnb end_loop_1							; jeœli nie jest mniejszy zakoñcz pêtlê
	LOADPIXEL rsi, rcx * 4, eax, xmm4, xmm0	; za³aduj kolejny piksel w wierszu z bufora Ÿród³owego do rejestru xmm4
	paddusw xmm3, xmm4						; i dodaj go do sumy skumulowanej w rejestrze xmm3
	inc rcx									; a nastêpnie zinkrementuj licznik
	jmp loop_1								; i powróæ na pocz¹tek pêtli
end_loop_1:

	xor rcx, rcx							; wyzeruj rejestr rcx, który bêdzie licznikiem dla pêtli nr 2
loop_2:
	cmp rcx, r13							; porównaj licznik z promieniem
	jg end_loop_2							; i jeœli jest wiêkszy zakoñcz pêtlê
	LOADPIXEL rsi, r10 * 4, eax, xmm4, xmm0	; w przeciwnym wypadku pobierz wartoœæ piksela na prawo o promieñ od aktualnie obliczanego i zapisz do rejestru xmm4
	paddusw xmm3, xmm4						; i dodaj go do sumy skumulowanej w rejestrze xmm3
	psubusw xmm3, xmm1						; a nastêpnie odejmij od tej sumy wartoœæ piksela najbardziej na lewo
	inc r10									; zinkrementuj indeks elementu najbardziej na prawo
	; podziel skumulowan¹ sumê przez sumê wag i zapisz do odpowiedniego elementu bufora wyjœciowego:
	
	DIVANDUNLOADPIXEL xmm4, xmm3, xmm7, xmm0, eax, rdi, r8 * 4

	inc r8									; zinkrementuj indeks elementu wyjœciowego
	inc rcx									; zinkrementuj licznik pêtli
	jmp loop_2								; i powróæ na pocz¹tek pêtli
end_loop_2:

	mov rcx, r13							; pobierz promieñ do rxc, rejestru licznika dla pêtli nr 3
	imul rcx, -2							; przemnó¿ przez -2
	add rcx, r12							; dodaj szerokoœæ wiersza
	dec rcx									; a nastêpnie zdekrementuj
	js end_loop_3							; i jeœli mniejsze od zera pomiñ pêtlê
loop_3:
	jz end_loop_3							; jeœli licznik jest równy zero zakoñcz pêtlê
	LOADPIXEL rsi, r10 * 4, eax, xmm4, xmm0 ; pobierz piksel o promieñ na prawo i zapisz do rejestru xmm4
	paddusw xmm3, xmm4						; dodaj go do sumy skumulowanej
	inc r10									; zinkrementuj indeks elementu o promieñ na prawo od aktualnie przetwarzanego
	LOADPIXEL rsi, r9 * 4, eax, xmm4, xmm0	; pobierz piksel o promieñ na lewo i zapisz do rejestru xmm4
	psubusw xmm3, xmm4						; i odejmij go od sumy skumulowanej
	inc r9									; zinkrementuj indeks elementu o promieñ na lewo od aktualnie przetwarzanego
	; podziel skumulowan¹ sumê przez sumê wag i zapisz do odpowiedniego elementu bufora wyjœciowego:
	DIVANDUNLOADPIXEL xmm4, xmm3, xmm7, xmm0, eax, rdi, r8 * 4
	inc r8									; zinkrementuj indeks elementu aktualnie przetwarzanego
	dec rcx									; zdekerementuj licznik
	jmp loop_3								; wróæ na pocz¹tek pêtli
end_loop_3:

	mov rcx, r13							; pobierz promieñ do rxc, rejestru licznika dla pêtli nr 3
	add rcx, 0								; wykonaj operacjê ¿eby ustawiæ flagi potrzebne przy skokach
	js end_loop_4							; i jeœli jest mniejszy od zera to pomiñ pêtlê
loop_4:
	jz end_loop_4							; jeœli licznik jest równo zero to zakoñcz pêtlê
	paddusw xmm3, xmm2						; dodaj do sumy skumulowanej wartoœæ piksela najbardziej na prawo
	LOADPIXEL rsi, r9 * 4, eax, xmm4, xmm0  ; pobierz piksel o promieñ na lewo i zapisz do rejestru xmm4
	psubusw xmm3, xmm4						; odejmij wartoœæ tego piksela od sumy skumulowanej
	inc r9									; zinkrementuj indeks elementu o promieñ na lewo
	; podziel skumulowan¹ sumê przez sumê wag i zapisz do odpowiedniego elementu bufora wyjœciowego:
	DIVANDUNLOADPIXEL xmm4, xmm3, xmm7, xmm0, eax, rdi, r8 * 4 
	inc r8									; zinkrementuj indeks elementu aktualnie przetwarzanego
	dec rcx									; zdekrementuj licznik pêtli
	jmp loop_4								; i powróæ na pocz¹tek pêtli		
end_loop_4:
	ret										; koniec :)

BoxBlurHorizontal endp

;*****************************************************************
;* Wykonuje przebieg filtru 'box filter' dla kolumn w obrazie. Przekazywane argumenty:
;* - adres kana³u wejœciowego (channelPtr),
;* - adres kana³u wyjœciowego (outputChannelPtr),
;* - szerokoœæ wiersza (rowWidth),
;* - wysokoœæ (height),
;* - promieñ (radius);
;******************************************************************
BoxBlurVertical proc uses rax rbx rcx rdx rsi rbp rdi channelPtr: PTR DWORD, outputChannelPtr: PTR DWORD, rowWidth: DWORD, height: DWORD, radius: DWORD
	; zapis argumentów funkcji do wolnych rejestrów:
	mov rsi, rcx							; zapisz adres kana³u wejœciowego do rsi
	mov rdi, rdx							; zapisz adres kana³u wyjœciowego do rdi
	mov r12, r8								; zapisz szerokoœæ wiersza do r12
	mov r13d, dword ptr [rbp + 48]			; zapisz promieñ do r13
	mov r14, r9								; zapisz wysokoœæ obrazka do r14

	xor rdx, rdx							; wyzeruj rejestr rdx
	mov rax, r12							; za³aduj wysokoœæ obrazka do rax
	shr rax, 1								; podziel przez 2 (przesuñ bity w prawo o jedn¹ pozycjê)
	dec rax									; a nastêpnie zdekrementuj
	cmovs rax, rdx							; wyzeruj rejestr rax jeœli jest ujemny
	mov rdx, r13							; pobierz promieñ do rdx
	cmp rdx, rax							; porównaj promieñ z rejestrem rax (po³owa szerokoœci wiersza - 1)
	cmovb rax, rdx							; jeœli jest mniejszy to za³aduj do rax jako promieñ
	mov r13, rax							; zapisz promieñ do rejestru r13, który przechowuje wartoœæ promienia dla przebiegu algorytmu
	shl rax, 1								; podwój promieñ w rejestrze rax (przesuwaj¹cy bity o jedn¹ pozycjê w lewo)
	inc rax									; zinkrementuj uzyskuj¹c œrednicê 'pude³ka'
	movd xmm7, rax							; za³aduj œrednicê do rejestru xmm7, w którym pozostanie do koñca procedury
	shufps xmm7, xmm7, 0					; skopiuj œrednicê do ka¿dego 32-bitowego kana³u (4 identyczne æwiartki w rejestrze xmm7)
	cvtdq2ps xmm7, xmm7						; przekonwertuj wartoœci œrednicy zawartych w æwiartkach w rejestrze xmm7 z dword na real4
	
	mov r8, 0								; zapisz zero do r8 - rejestru z indeksem dla elementu wyjœciowego
	mov r9, 0								; zapisz zero do r9 - rejestru z indeksem dla elementu o promieñ w górê od wyjœciowego
	mov r10, r13							; zapisz wartoœæ promienia do r10 - rejestru z indeksem dla elementu o promieñ w dó³ od wyjœciowego
	imul r10, r12							; pomnó¿ ten indeks przez szerokoœæ wiersza
	
	; Przetwarzanie kana³u:
	xorps xmm0, xmm0						; wyzeruj rejestr xmm0, który bêdzie s³u¿y³ do operacji pakowania i rozpakowywania
	xorps xmm3, xmm3						; wyzeruj rejestr xmm3 - rejestr przeznaczony na wartoœæ wyjœciow¹
	LOADPIXEL rsi, 0, ebx, xmm1, xmm0		; za³aduj pierwszy piksel w kolumnie do rejestru xmm1
	mov rax, r14							; za³aduj wysokoœæ obrazu do rax
	dec rax									; nastêpnie j¹ zdekrementuj
	imul rax, r12							; i pomnó¿ przez szerokoœæ wiersza
	LOADPIXEL rsi, rax * 4, ebx, xmm2, xmm0	; za³aduj ostatni piksel w kolumnie do rejestru xmm2
	mov rax, r13							; za³aduj promieñ do rax
	inc rax									; nastêpnie go zinkrementuj
	movd xmm4, rax							; i zapisz do rejestru xmm4
	shufps xmm4, xmm4, 0					; i przetasuj (shuffle) rejestr, tak by wyst¹pi³ w ka¿dej æwiartce jako dword
	movdqa xmm3, xmm1						; skopiuj pierwszy piksel w kolumnie do rejestru xmm3
	pmulld xmm3, xmm4						; przemnó¿ przez promieñ + 1 (wartoœæ w rejestrze xmm4)

	xor rcx, rcx							; wyzeruj rejestr rcx, który bêdzie licznikiem dla pêtli nr 1
loop_1:
	cmp rcx, r13							; porównaj licznik z promieniem
	jnb end_loop_1							; jeœli nie jest mniejszy zakoñcz pêtlê
	mov rax, rcx							; skopiuj wartoœæ licznika do rax
	imul rax, r12							; i pomnó¿ przez szerokoœæ wiersza
	LOADPIXEL rsi, rax * 4, ebx, xmm4, xmm0	; za³aduj piksel z wiersza ni¿ej do rejestru xmm4
	paddusw xmm3, xmm4						; i dodaj go do sumy skumulowanej w rejestrze xmm3
	inc rcx									; a nastêpnie zinkrementuj licznik
	jmp loop_1								; i powróæ na pocz¹tek pêtli
end_loop_1:

	xor rcx, rcx							; wyzeruj rejestr rcx, który bêdzie licznikiem dla pêtli nr 2
loop_2:
	cmp rcx, r13							; porównaj licznik z promieniem
	jg end_loop_2							; i jeœli jest wiêkszy zakoñcz pêtlê
	LOADPIXEL rsi, r10 * 4, eax, xmm4, xmm0	; w przeciwnym wypadku pobierz wartoœæ piksela o promieñ w dó³ od aktualnie obliczanego i zapisz do rejestru xmm4
	paddusw xmm3, xmm4						; i dodaj go do sumy skumulowanej w rejestrze xmm3
	psubusw xmm3, xmm1						; a nastêpnie odejmij od tej sumy wartoœæ piksela najbardziej na lewo
	add r10, r12							; dodaj szerokoœæ wiersza do indeksu elementu o promieñ ni¿ej
	; podziel skumulowan¹ sumê przez sumê wag i zapisz do odpowiedniego elementu bufora wyjœciowego:
	DIVANDUNLOADPIXEL xmm4, xmm3, xmm7, xmm0, eax, rdi, r8 * 4
	add r8, r12								; dodaj szerokoœæ wiersza do indeksu elementu wyjœciowego
	inc rcx									; zinkrementuj licznik pêtli
	jmp loop_2								; i powróæ na pocz¹tek pêtli
end_loop_2:

	mov rcx, r13							; pobierz promieñ do rxc, rejestru licznika dla pêtli nr 3
	imul rcx, -2							; przemnó¿ przez -2
	add rcx, r14							; dodaj wysokoœæ obrazka
	dec rcx									; a nastêpnie zdekrementuj
	js end_loop_3							; i jeœli mniejsze od zera pomiñ pêtlê
loop_3:
	jz end_loop_3							; jeœli licznik jest równy zero zakoñcz pêtlê
	LOADPIXEL rsi, r10 * 4, eax, xmm4, xmm0 ; pobierz piksel o promieñ w dó³ i zapisz do rejestru xmm4
	paddusw xmm3, xmm4						; dodaj go do sumy skumulowanej
	add r10, r12							; dodaj szerokoœæ do indeksu o promieñ w dó³ ni¿ej
	LOADPIXEL rsi, r9 * 4, eax, xmm4, xmm0	; pobierz piksel o promieñ w górê i zapisz do rejestru xmm4
	psubusw xmm3, xmm4						; i odejmij go od sumy skumulowanej
	add r9, r12								; dodaj szerokoœæ wiersza do indeksu elementu o promieñ w górê od aktualnie przetwarzanego
	; podziel skumulowan¹ sumê przez sumê wag i zapisz do odpowiedniego elementu bufora wyjœciowego:
	DIVANDUNLOADPIXEL xmm4, xmm3, xmm7, xmm0, eax, rdi, r8 * 4
	add r8, r12								; dodaj szerokoœæ wiersza do indeksu elementu aktualnie przetwarzanego
	dec rcx									; zdekerementuj licznik
	jmp loop_3								; wróæ na pocz¹tek pêtli
end_loop_3:

	mov rcx, r13							; pobierz promieñ do rxc, rejestru licznika dla pêtli nr 3
	add rcx, 0								; wykonaj operacjê ¿eby ustawiæ flagi potrzebne przy skokach
	js end_loop_4							; i jeœli jest mniejszy od zera to pomiñ pêtlê
loop_4:
	jz end_loop_4							; jeœli licznik jest równo zero to zakoñcz pêtlê
	paddusw xmm3, xmm2						; dodaj do sumy skumulowanej wartoœæ piksela w najni¿szym wierszu
	LOADPIXEL rsi, r9 * 4, eax, xmm4, xmm0  ; pobierz piksel o promieñ do góry i zapisz do rejestru xmm4
	psubusw xmm3, xmm4						; odejmij wartoœæ tego piksela od sumy skumulowanej
	add r9, r12								; dodaj szerokoœæ wiersza do indeksu elementu o promieñ na lewo
	; podziel skumulowan¹ sumê przez sumê wag i zapisz do odpowiedniego elementu bufora wyjœciowego:
	DIVANDUNLOADPIXEL xmm4, xmm3, xmm7, xmm0, eax, rdi, r8 * 4 
	add r8, r12								; dodaj szerokoœæ wiersza do indeksu elementu aktualnie przetwarzanego
	dec rcx									; zdekrementuj licznik pêtli
	jmp loop_4								; i powróæ na pocz¹tek pêtli		
end_loop_4:
	ret										; koniec :)

BoxBlurVertical endp

;*****************************************************************
;* Do zadanej tablicy (boxesArr) ³aduje obliczone wielkoœci 'pude³ek' u¿ywane przy realizacji filtru Gaussa.
;* Pozosta³ymi argumentami s¹: 
;* - liczba pude³ek (boxesCount),
;* - sigma (sigma);
;******************************************************************
GetBoxes proc uses rax rbx rcx rdx rsi rdi boxesArr: PTR QWORD, boxesCount: DWORD, sigma: real8

	mov r10, rcx						; wskaŸnik na tablicê rozmiarów do r10
	mov r11, rdx						; iloœæ 'pude³ek' do r11
	movsd xmm0, xmm2					; sigma do xmm0 u2
	mulsd xmm0, xmm0					; podnieœ sigmê do kwadratu
	cvtsi2sd xmm1, r11					; za³aduj liczbê 'pude³ek' przekonwertowan¹ w locie na real8 do xmm1
	mulsd xmm0, twelve_d				; przemnó¿ sigmê^2 * 12.0
	movdqa xmm2, xmm0					; skopiuj wynik do xmm2
	divsd xmm2, xmm1					; podziel kopiê przez liczbê 'pude³ek'
	addsd xmm2, one_d					; a nastêpnie dodaj do niej 1.0
	sqrtsd xmm2, xmm2					; i oblicz pierwiastek kwadratowy
	cvttsd2si eax, xmm2					; przekonwertuj t¹ kopiê do dword (obcinaj¹c w dó³) i za³aduj do eax
	test eax, 80000001h					; sprawdŸ, czy wynik jest podzielny przez 2 
	jnz continue						; pomiñ jeœli niepodzielny przez 2
	dec eax								; w przeciwnym razie zdekrementuj ¿eby otrzymaæ nieparzyst¹ liczbê
continue:
	mov ebx, eax						; skopiuj zawartoœæ eax do ebx
	add ebx, 2							; a nastêpnie dodaj do tej kopii 2
	
	; Obliczenie idealMaximum (do edx):
	mov ecx, eax						; tym razem skopiuj eax do ecx
	imul rcx, r11						; i pomnó¿ t¹ kopiê przez iloœæ 'pude³ek'
	mov edx, ecx						; skopiuj wynik do edx
	imul ecx, eax						; a orygina³ pomnó¿ przez eax
	imul edx, 4							; kopiê pomnó¿ 4-krotnie
	add ecx, edx						; i dodaj j¹ do orygina³u
	mov rdx, r11						; za³aduj iloœæ 'pude³ek' do rdx
	imul edx, 3							; i pomnó¿ j¹ przez 3
	add ecx, edx						; a wynik dodaj do rejestru ecx
	cvtsi2sd xmm1, ecx					; przekonwertuj ecx na real8 i za³aduj do xmm1
	subsd xmm0, xmm1					; odejmij od sigmy^2 przekonwertowan¹ wartoœæ
	mov ecx, eax						; skopiuj eax do ecx
	imul ecx, -4						; pomnó¿ kopiê razy -4
	sub ecx, 4							; i odejmij od niej 4
	cvtsi2sd xmm1, ecx					; a wynik przekonwertuj na real8 i za³aduj do xmm1
	divsd xmm0, xmm1					; podziel xmm0 przez xmm1
	cvtsd2si edx, xmm0					; i za³aduj xmm0 jako dword do edx

	; Wype³nienie tablicy
	; odpowiednimi wielkoœciami pude³ek:
	mov rsi, r10						; za³aduj adres tablicy rozmiarów 'pude³ek' do rsi
	mov rcx, 0							; zainicjalizuj licznik (rcx) wartoœci¹ 0
fill_loop:			
	cmp rcx, r11						; porównanie licznik z liczb¹ 'pude³ek'
	je array_filled						; i zakoñcz wype³nianie jeœli równe
	mov rdi, rax						; w przeciwnym wypadku skopiuj rax do rdi
	cmp rcx, rdx						; i porownaj z licznikiem
	cmovge rdi, rbx						; jeœli licznik jest mniejszy od tej wartoœci to za³aduj rbx do rdi
	mov dword ptr[rsi + rcx * 4], edi	; i przeœlij rdi do aktualnej pozycji w tablicy
	inc rcx								; nastêpnie zinkrementuj licznik (rcx)
	jmp fill_loop						; i powróæ na pocz¹tek pêtli
array_filled: 
	ret									; koniec :)

GetBoxes endp
 
END;