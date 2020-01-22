;///////////////////////////////////////////////////////////////////////////////
;	Biblioteka zawiera nast�puj�ce procedury:
;	- rozmycie w poziomie (BoxBlurHorizontal),
;	- rozmycie w pionie (BoxBlurVertical),
;	- obliczenie wielko�ci 'pude�ek' dla przebieg�w algorytmu (GetBoxes).
;/////////////////////////////////////////////////////////////////////////////
OPTION CASEMAP:NONE					

.CONST								; segment dla sta�ych
	twelve_d real8 12.0				; sta�a liczbowa 12.0 w real8
	one_d real8 1.0					; sta�a liczbowa 1.0 w real8

.CODE
;*****************************************************************
;* Makro s�u��ca do za�adowania piksela w formacie RGBA (DWORD) 32 z bufora wskazanego przez source i pozycji wskazanej
;* przez offset do rejestru docelowego sse (sseDest), przy pomocy rejestru og�lnego przeznaczania dest i wyzerowanego rejestru sse,
;* wskazywanego przez ss0.
;******************************************************************
LOADPIXEL MACRO source, offset, dest, sseDest, sse0 
	mov dest, dword ptr[source + offset]; pobierz warto�� elementu z bufora wyj�ciowego na podstawie rejestru �r�d�owego i zadanego offsetu
	movd sseDest, dest					; skopiuj j� do docelowego rejestru sse
	punpcklbw sseDest, sse0				; wypakuj 32 bity do 64 bit�w w docelowym rejestrze sse, w kt�rym wszystkie �wiartki s� na 0
	punpcklwd sseDest, sse0				; wypakuj 64 bity do 128 bit�w w docelowym rejestrze sse, w kt�rym wszystkie �wiartki s� na 0
ENDM

;*****************************************************************
;* Makro s�u��ce do za�adowania obliczonego piksela z rejestru sse sseSource do bufora wskazywanego przez rejestr dest i offset.
;* U�ywane s� tak�e rejestry:
;* - sseTemp - do tymczasowych oblicze� w rejestrze sse, 
;* - sseWeight - rejestr z wag� pikseli,
;* - sse0 - wyzerowany rejestr sse,
;* - temp - tymczasowy rejestr og�lnego przeznaczenia.
;******************************************************************
DIVANDUNLOADPIXEL MACRO sseTemp, sseSource, sseWeight, sse0, temp, dest, offset
	movdqa sseTemp, sseSource			; przekopiuj warto�� z rejestru sse, kt�ry zawiera warto�� do zapisu w buforze do roboczego rejestru sse
	cvtdq2ps sseTemp, sseTemp			; przekonwertuj �wiartki w roboczym rejestrze z dword na real4
	divps sseTemp, sseWeight			; podziel ka�d� �wiartk� przez rejestr sse zawieraj�cy wag�
	cvttps2dq sseTemp, sseTemp			; przekonwertuj �wiartki w roboczym rejestrze z real4 na dword z obci�ciem
	packusdw sseTemp, sse0				; zapakuj 128 bit�w do 64 bitowych s��w
	packuswb sseTemp, sse0				; zapakuj 64 bity do 32 bitowych s��w
	movd temp, sseTemp					; przepisz warto�� z roboczego rejestru sse do roboczego rejestru og�lnego przeznaczenia
	mov dword ptr[dest + offset], temp	; zapisz warto�� do bufora wyj�ciowego
ENDM

;*****************************************************************
;* Wykonuje przebieg filtru 'box filter' dla wierszy w obrazie. Przekazywane argumenty:
;* - adres kana�u wej�ciowego (channelPtr),
;* - adres kana�u wyj�ciowego (outputChannelPtr),
;* - szeroko�� wiersza (rowWidth),
;* - promie� (radius);
;******************************************************************
BoxBlurHorizontal proc uses rax rbx rcx rdx rsi rbp rdi channelPtr: PTR DWORD, outputChannelPtr: PTR DWORD, rowWidth: DWORD, radius: DWORD
	; zapis argument�w funkcji do wolnych rejestr�w:
	mov rsi, rcx							; zapisz adres kana�u wej�ciowego do rsi
	mov rdi, rdx							; zapisz adres kana�u wyj�ciowego do rdi
	mov r12, r8								; zapisz szeroko�� wiersza do r12
	mov r13, r9								; zapisz promie� do r13

	xor rdx, rdx							; wyzeruj rejestr rdx
	mov rax, r12							; pobierz szeroko�� wiersza do rax
	shr rax, 1								; podziel przez 2 zaokr�glaj�c w d� (przesu� bity w prawo o jedn� pozycj�)
	dec rax									; a nast�pnie zdekrementuj
	cmovs rax, rdx							; wyzeruj rejestr rax je�li jest ujemny
	mov rax, r13							; pobierz promie� do rdx
	mov r13, rax							; zapisz promie� do rejestru r13, kt�ry przechowuje warto�� promienia dla przebiegu algorytmu
	shl rax, 1								; podw�j promie� w rejestrze rax (przesuwaj�cy bity o jedn� pozycj� w lewo)
	inc rax									; zinkrementuj uzyskuj�c �rednic� 'pude�ka'
	movd xmm7, rax							; za�aduj �rednic� do rejestru xmm7, w kt�rym pozostanie do ko�ca procedury
	shufps xmm7, xmm7, 0					; skopiuj �rednic� do ka�dego 32-bitowego kana�u (4 identyczne �wiartki w rejestrze xmm7)
	cvtdq2ps xmm7, xmm7						; przekonwertuj warto�ci �rednicy zawartych w �wiartkach w rejestrze xmm7 z dword na real4

	mov r8, 0								; zapisz zero do r8 - rejestru z indeksem dla elementu wyj�ciowego
	mov r9, 0								; zapisz zero do r9 - rejestru z indeksem dla elementu o promie� na lewo od wyj�ciowego
	mov r10, r13							; zapisz warto�� promienia do r10 - rejestru z indeksem dla elementu na prawo od wyj�ciowego

	; Przetwarzanie kana�u:
	xorps xmm0, xmm0						; wyzeruj rejestr xmm0, kt�ry b�dzie s�u�y� do operacji pakowania i rozpakowywania
	xorps xmm3, xmm3						; wyzeruj rejestr xmm3 - rejestr przeznaczony na warto�� wyj�ciow�
	LOADPIXEL rsi, 0, ebx, xmm1, xmm0		; za�aduj piksel najbardziej na lewo do rejestru xmm1
	mov rax, r12							; za�aduj szeroko�� wiersza do rax
	dec rax									; nast�pnie j� zdekrementuj
	LOADPIXEL rsi, rax * 4, ebx, xmm2, xmm0	; za�aduj ostatni piksel w wierszu do rejestru xmm2
	mov rax, r13							; za�aduj promie� do rax
	inc rax									; nast�pnie go zinkrementuj
	movd xmm4, rax							; i zapisz do rejestru xmm4
	shufps xmm4, xmm4, 0					; i przetasuj (shuffle) rejestr, tak by wyst�pi� w ka�dej �wiartce jako dword
	movdqa xmm3, xmm1						; skopiuj piksel najbardziej na lewo do rejestru xmm3
	pmulld xmm3, xmm4						; przemn� przez promie� + 1 (warto�� w rejestrze xmm4)
	
	xor rcx, rcx							; wyzeruj rejestr rcx, kt�ry b�dzie licznikiem dla p�tli nr 1
loop_1:
	cmp rcx, r13							; por�wnaj licznik z promieniem
	jnb end_loop_1							; je�li nie jest mniejszy zako�cz p�tl�
	LOADPIXEL rsi, rcx * 4, eax, xmm4, xmm0	; za�aduj kolejny piksel w wierszu z bufora �r�d�owego do rejestru xmm4
	paddusw xmm3, xmm4						; i dodaj go do sumy skumulowanej w rejestrze xmm3
	inc rcx									; a nast�pnie zinkrementuj licznik
	jmp loop_1								; i powr�� na pocz�tek p�tli
end_loop_1:

	xor rcx, rcx							; wyzeruj rejestr rcx, kt�ry b�dzie licznikiem dla p�tli nr 2
loop_2:
	cmp rcx, r13							; por�wnaj licznik z promieniem
	jg end_loop_2							; i je�li jest wi�kszy zako�cz p�tl�
	LOADPIXEL rsi, r10 * 4, eax, xmm4, xmm0	; w przeciwnym wypadku pobierz warto�� piksela na prawo o promie� od aktualnie obliczanego i zapisz do rejestru xmm4
	paddusw xmm3, xmm4						; i dodaj go do sumy skumulowanej w rejestrze xmm3
	psubusw xmm3, xmm1						; a nast�pnie odejmij od tej sumy warto�� piksela najbardziej na lewo
	inc r10									; zinkrementuj indeks elementu najbardziej na prawo
	; podziel skumulowan� sum� przez sum� wag i zapisz do odpowiedniego elementu bufora wyj�ciowego:
	
	DIVANDUNLOADPIXEL xmm4, xmm3, xmm7, xmm0, eax, rdi, r8 * 4

	inc r8									; zinkrementuj indeks elementu wyj�ciowego
	inc rcx									; zinkrementuj licznik p�tli
	jmp loop_2								; i powr�� na pocz�tek p�tli
end_loop_2:

	mov rcx, r13							; pobierz promie� do rxc, rejestru licznika dla p�tli nr 3
	imul rcx, -2							; przemn� przez -2
	add rcx, r12							; dodaj szeroko�� wiersza
	dec rcx									; a nast�pnie zdekrementuj
	js end_loop_3							; i je�li mniejsze od zera pomi� p�tl�
loop_3:
	jz end_loop_3							; je�li licznik jest r�wny zero zako�cz p�tl�
	LOADPIXEL rsi, r10 * 4, eax, xmm4, xmm0 ; pobierz piksel o promie� na prawo i zapisz do rejestru xmm4
	paddusw xmm3, xmm4						; dodaj go do sumy skumulowanej
	inc r10									; zinkrementuj indeks elementu o promie� na prawo od aktualnie przetwarzanego
	LOADPIXEL rsi, r9 * 4, eax, xmm4, xmm0	; pobierz piksel o promie� na lewo i zapisz do rejestru xmm4
	psubusw xmm3, xmm4						; i odejmij go od sumy skumulowanej
	inc r9									; zinkrementuj indeks elementu o promie� na lewo od aktualnie przetwarzanego
	; podziel skumulowan� sum� przez sum� wag i zapisz do odpowiedniego elementu bufora wyj�ciowego:
	DIVANDUNLOADPIXEL xmm4, xmm3, xmm7, xmm0, eax, rdi, r8 * 4
	inc r8									; zinkrementuj indeks elementu aktualnie przetwarzanego
	dec rcx									; zdekerementuj licznik
	jmp loop_3								; wr�� na pocz�tek p�tli
end_loop_3:

	mov rcx, r13							; pobierz promie� do rxc, rejestru licznika dla p�tli nr 3
	add rcx, 0								; wykonaj operacj� �eby ustawi� flagi potrzebne przy skokach
	js end_loop_4							; i je�li jest mniejszy od zera to pomi� p�tl�
loop_4:
	jz end_loop_4							; je�li licznik jest r�wno zero to zako�cz p�tl�
	paddusw xmm3, xmm2						; dodaj do sumy skumulowanej warto�� piksela najbardziej na prawo
	LOADPIXEL rsi, r9 * 4, eax, xmm4, xmm0  ; pobierz piksel o promie� na lewo i zapisz do rejestru xmm4
	psubusw xmm3, xmm4						; odejmij warto�� tego piksela od sumy skumulowanej
	inc r9									; zinkrementuj indeks elementu o promie� na lewo
	; podziel skumulowan� sum� przez sum� wag i zapisz do odpowiedniego elementu bufora wyj�ciowego:
	DIVANDUNLOADPIXEL xmm4, xmm3, xmm7, xmm0, eax, rdi, r8 * 4 
	inc r8									; zinkrementuj indeks elementu aktualnie przetwarzanego
	dec rcx									; zdekrementuj licznik p�tli
	jmp loop_4								; i powr�� na pocz�tek p�tli		
end_loop_4:
	ret										; koniec :)

BoxBlurHorizontal endp

;*****************************************************************
;* Wykonuje przebieg filtru 'box filter' dla kolumn w obrazie. Przekazywane argumenty:
;* - adres kana�u wej�ciowego (channelPtr),
;* - adres kana�u wyj�ciowego (outputChannelPtr),
;* - szeroko�� wiersza (rowWidth),
;* - wysoko�� (height),
;* - promie� (radius);
;******************************************************************
BoxBlurVertical proc uses rax rbx rcx rdx rsi rbp rdi channelPtr: PTR DWORD, outputChannelPtr: PTR DWORD, rowWidth: DWORD, height: DWORD, radius: DWORD
	; zapis argument�w funkcji do wolnych rejestr�w:
	mov rsi, rcx							; zapisz adres kana�u wej�ciowego do rsi
	mov rdi, rdx							; zapisz adres kana�u wyj�ciowego do rdi
	mov r12, r8								; zapisz szeroko�� wiersza do r12
	mov r13d, dword ptr [rbp + 48]			; zapisz promie� do r13
	mov r14, r9								; zapisz wysoko�� obrazka do r14

	xor rdx, rdx							; wyzeruj rejestr rdx
	mov rax, r12							; za�aduj wysoko�� obrazka do rax
	shr rax, 1								; podziel przez 2 (przesu� bity w prawo o jedn� pozycj�)
	dec rax									; a nast�pnie zdekrementuj
	cmovs rax, rdx							; wyzeruj rejestr rax je�li jest ujemny
	mov rdx, r13							; pobierz promie� do rdx
	cmp rdx, rax							; por�wnaj promie� z rejestrem rax (po�owa szeroko�ci wiersza - 1)
	cmovb rax, rdx							; je�li jest mniejszy to za�aduj do rax jako promie�
	mov r13, rax							; zapisz promie� do rejestru r13, kt�ry przechowuje warto�� promienia dla przebiegu algorytmu
	shl rax, 1								; podw�j promie� w rejestrze rax (przesuwaj�cy bity o jedn� pozycj� w lewo)
	inc rax									; zinkrementuj uzyskuj�c �rednic� 'pude�ka'
	movd xmm7, rax							; za�aduj �rednic� do rejestru xmm7, w kt�rym pozostanie do ko�ca procedury
	shufps xmm7, xmm7, 0					; skopiuj �rednic� do ka�dego 32-bitowego kana�u (4 identyczne �wiartki w rejestrze xmm7)
	cvtdq2ps xmm7, xmm7						; przekonwertuj warto�ci �rednicy zawartych w �wiartkach w rejestrze xmm7 z dword na real4
	
	mov r8, 0								; zapisz zero do r8 - rejestru z indeksem dla elementu wyj�ciowego
	mov r9, 0								; zapisz zero do r9 - rejestru z indeksem dla elementu o promie� w g�r� od wyj�ciowego
	mov r10, r13							; zapisz warto�� promienia do r10 - rejestru z indeksem dla elementu o promie� w d� od wyj�ciowego
	imul r10, r12							; pomn� ten indeks przez szeroko�� wiersza
	
	; Przetwarzanie kana�u:
	xorps xmm0, xmm0						; wyzeruj rejestr xmm0, kt�ry b�dzie s�u�y� do operacji pakowania i rozpakowywania
	xorps xmm3, xmm3						; wyzeruj rejestr xmm3 - rejestr przeznaczony na warto�� wyj�ciow�
	LOADPIXEL rsi, 0, ebx, xmm1, xmm0		; za�aduj pierwszy piksel w kolumnie do rejestru xmm1
	mov rax, r14							; za�aduj wysoko�� obrazu do rax
	dec rax									; nast�pnie j� zdekrementuj
	imul rax, r12							; i pomn� przez szeroko�� wiersza
	LOADPIXEL rsi, rax * 4, ebx, xmm2, xmm0	; za�aduj ostatni piksel w kolumnie do rejestru xmm2
	mov rax, r13							; za�aduj promie� do rax
	inc rax									; nast�pnie go zinkrementuj
	movd xmm4, rax							; i zapisz do rejestru xmm4
	shufps xmm4, xmm4, 0					; i przetasuj (shuffle) rejestr, tak by wyst�pi� w ka�dej �wiartce jako dword
	movdqa xmm3, xmm1						; skopiuj pierwszy piksel w kolumnie do rejestru xmm3
	pmulld xmm3, xmm4						; przemn� przez promie� + 1 (warto�� w rejestrze xmm4)

	xor rcx, rcx							; wyzeruj rejestr rcx, kt�ry b�dzie licznikiem dla p�tli nr 1
loop_1:
	cmp rcx, r13							; por�wnaj licznik z promieniem
	jnb end_loop_1							; je�li nie jest mniejszy zako�cz p�tl�
	mov rax, rcx							; skopiuj warto�� licznika do rax
	imul rax, r12							; i pomn� przez szeroko�� wiersza
	LOADPIXEL rsi, rax * 4, ebx, xmm4, xmm0	; za�aduj piksel z wiersza ni�ej do rejestru xmm4
	paddusw xmm3, xmm4						; i dodaj go do sumy skumulowanej w rejestrze xmm3
	inc rcx									; a nast�pnie zinkrementuj licznik
	jmp loop_1								; i powr�� na pocz�tek p�tli
end_loop_1:

	xor rcx, rcx							; wyzeruj rejestr rcx, kt�ry b�dzie licznikiem dla p�tli nr 2
loop_2:
	cmp rcx, r13							; por�wnaj licznik z promieniem
	jg end_loop_2							; i je�li jest wi�kszy zako�cz p�tl�
	LOADPIXEL rsi, r10 * 4, eax, xmm4, xmm0	; w przeciwnym wypadku pobierz warto�� piksela o promie� w d� od aktualnie obliczanego i zapisz do rejestru xmm4
	paddusw xmm3, xmm4						; i dodaj go do sumy skumulowanej w rejestrze xmm3
	psubusw xmm3, xmm1						; a nast�pnie odejmij od tej sumy warto�� piksela najbardziej na lewo
	add r10, r12							; dodaj szeroko�� wiersza do indeksu elementu o promie� ni�ej
	; podziel skumulowan� sum� przez sum� wag i zapisz do odpowiedniego elementu bufora wyj�ciowego:
	DIVANDUNLOADPIXEL xmm4, xmm3, xmm7, xmm0, eax, rdi, r8 * 4
	add r8, r12								; dodaj szeroko�� wiersza do indeksu elementu wyj�ciowego
	inc rcx									; zinkrementuj licznik p�tli
	jmp loop_2								; i powr�� na pocz�tek p�tli
end_loop_2:

	mov rcx, r13							; pobierz promie� do rxc, rejestru licznika dla p�tli nr 3
	imul rcx, -2							; przemn� przez -2
	add rcx, r14							; dodaj wysoko�� obrazka
	dec rcx									; a nast�pnie zdekrementuj
	js end_loop_3							; i je�li mniejsze od zera pomi� p�tl�
loop_3:
	jz end_loop_3							; je�li licznik jest r�wny zero zako�cz p�tl�
	LOADPIXEL rsi, r10 * 4, eax, xmm4, xmm0 ; pobierz piksel o promie� w d� i zapisz do rejestru xmm4
	paddusw xmm3, xmm4						; dodaj go do sumy skumulowanej
	add r10, r12							; dodaj szeroko�� do indeksu o promie� w d� ni�ej
	LOADPIXEL rsi, r9 * 4, eax, xmm4, xmm0	; pobierz piksel o promie� w g�r� i zapisz do rejestru xmm4
	psubusw xmm3, xmm4						; i odejmij go od sumy skumulowanej
	add r9, r12								; dodaj szeroko�� wiersza do indeksu elementu o promie� w g�r� od aktualnie przetwarzanego
	; podziel skumulowan� sum� przez sum� wag i zapisz do odpowiedniego elementu bufora wyj�ciowego:
	DIVANDUNLOADPIXEL xmm4, xmm3, xmm7, xmm0, eax, rdi, r8 * 4
	add r8, r12								; dodaj szeroko�� wiersza do indeksu elementu aktualnie przetwarzanego
	dec rcx									; zdekerementuj licznik
	jmp loop_3								; wr�� na pocz�tek p�tli
end_loop_3:

	mov rcx, r13							; pobierz promie� do rxc, rejestru licznika dla p�tli nr 3
	add rcx, 0								; wykonaj operacj� �eby ustawi� flagi potrzebne przy skokach
	js end_loop_4							; i je�li jest mniejszy od zera to pomi� p�tl�
loop_4:
	jz end_loop_4							; je�li licznik jest r�wno zero to zako�cz p�tl�
	paddusw xmm3, xmm2						; dodaj do sumy skumulowanej warto�� piksela w najni�szym wierszu
	LOADPIXEL rsi, r9 * 4, eax, xmm4, xmm0  ; pobierz piksel o promie� do g�ry i zapisz do rejestru xmm4
	psubusw xmm3, xmm4						; odejmij warto�� tego piksela od sumy skumulowanej
	add r9, r12								; dodaj szeroko�� wiersza do indeksu elementu o promie� na lewo
	; podziel skumulowan� sum� przez sum� wag i zapisz do odpowiedniego elementu bufora wyj�ciowego:
	DIVANDUNLOADPIXEL xmm4, xmm3, xmm7, xmm0, eax, rdi, r8 * 4 
	add r8, r12								; dodaj szeroko�� wiersza do indeksu elementu aktualnie przetwarzanego
	dec rcx									; zdekrementuj licznik p�tli
	jmp loop_4								; i powr�� na pocz�tek p�tli		
end_loop_4:
	ret										; koniec :)

BoxBlurVertical endp

;*****************************************************************
;* Do zadanej tablicy (boxesArr) �aduje obliczone wielko�ci 'pude�ek' u�ywane przy realizacji filtru Gaussa.
;* Pozosta�ymi argumentami s�: 
;* - liczba pude�ek (boxesCount),
;* - sigma (sigma);
;******************************************************************
GetBoxes proc uses rax rbx rcx rdx rsi rdi boxesArr: PTR QWORD, boxesCount: DWORD, sigma: real8

	mov r10, rcx						; wska�nik na tablic� rozmiar�w do r10
	mov r11, rdx						; ilo�� 'pude�ek' do r11
	movsd xmm0, xmm2					; sigma do xmm0 u2
	mulsd xmm0, xmm0					; podnie� sigm� do kwadratu
	cvtsi2sd xmm1, r11					; za�aduj liczb� 'pude�ek' przekonwertowan� w locie na real8 do xmm1
	mulsd xmm0, twelve_d				; przemn� sigm�^2 * 12.0
	movdqa xmm2, xmm0					; skopiuj wynik do xmm2
	divsd xmm2, xmm1					; podziel kopi� przez liczb� 'pude�ek'
	addsd xmm2, one_d					; a nast�pnie dodaj do niej 1.0
	sqrtsd xmm2, xmm2					; i oblicz pierwiastek kwadratowy
	cvttsd2si eax, xmm2					; przekonwertuj t� kopi� do dword (obcinaj�c w d�) i za�aduj do eax
	test eax, 80000001h					; sprawd�, czy wynik jest podzielny przez 2 
	jnz continue						; pomi� je�li niepodzielny przez 2
	dec eax								; w przeciwnym razie zdekrementuj �eby otrzyma� nieparzyst� liczb�
continue:
	mov ebx, eax						; skopiuj zawarto�� eax do ebx
	add ebx, 2							; a nast�pnie dodaj do tej kopii 2
	
	; Obliczenie idealMaximum (do edx):
	mov ecx, eax						; tym razem skopiuj eax do ecx
	imul rcx, r11						; i pomn� t� kopi� przez ilo�� 'pude�ek'
	mov edx, ecx						; skopiuj wynik do edx
	imul ecx, eax						; a orygina� pomn� przez eax
	imul edx, 4							; kopi� pomn� 4-krotnie
	add ecx, edx						; i dodaj j� do orygina�u
	mov rdx, r11						; za�aduj ilo�� 'pude�ek' do rdx
	imul edx, 3							; i pomn� j� przez 3
	add ecx, edx						; a wynik dodaj do rejestru ecx
	cvtsi2sd xmm1, ecx					; przekonwertuj ecx na real8 i za�aduj do xmm1
	subsd xmm0, xmm1					; odejmij od sigmy^2 przekonwertowan� warto��
	mov ecx, eax						; skopiuj eax do ecx
	imul ecx, -4						; pomn� kopi� razy -4
	sub ecx, 4							; i odejmij od niej 4
	cvtsi2sd xmm1, ecx					; a wynik przekonwertuj na real8 i za�aduj do xmm1
	divsd xmm0, xmm1					; podziel xmm0 przez xmm1
	cvtsd2si edx, xmm0					; i za�aduj xmm0 jako dword do edx

	; Wype�nienie tablicy
	; odpowiednimi wielko�ciami pude�ek:
	mov rsi, r10						; za�aduj adres tablicy rozmiar�w 'pude�ek' do rsi
	mov rcx, 0							; zainicjalizuj licznik (rcx) warto�ci� 0
fill_loop:			
	cmp rcx, r11						; por�wnanie licznik z liczb� 'pude�ek'
	je array_filled						; i zako�cz wype�nianie je�li r�wne
	mov rdi, rax						; w przeciwnym wypadku skopiuj rax do rdi
	cmp rcx, rdx						; i porownaj z licznikiem
	cmovge rdi, rbx						; je�li licznik jest mniejszy od tej warto�ci to za�aduj rbx do rdi
	mov dword ptr[rsi + rcx * 4], edi	; i prze�lij rdi do aktualnej pozycji w tablicy
	inc rcx								; nast�pnie zinkrementuj licznik (rcx)
	jmp fill_loop						; i powr�� na pocz�tek p�tli
array_filled: 
	ret									; koniec :)

GetBoxes endp
 
END;