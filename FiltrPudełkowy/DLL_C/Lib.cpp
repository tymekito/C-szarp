// Biblioteka cpp.cpp : Definiuje eksportowane funkcje dla aplikacji DLL.

#include "stdafx.h"
#include <math.h>
//int size bo 1 int to 4 char 
#define INT_SIZE 4

// Wykonuje rozmycie w poziomie (dla wiersza) dla danego kanału.
void BoxBlurHorizontalBytes(unsigned char *input, unsigned char *output, int width, int radius, int diameter) {
	// indeks początkowy
	int rowStartIndex = 0;
	// indeks na prawo o promień od aktualnego (bądź granica obrazu)
	int rightBoundIndex = rowStartIndex + radius * INT_SIZE;
	// indeks na lewo o promień od aktualnego (bądź granica obrazu)
	int leftBoundIndex = rowStartIndex;
	// indeks aktualnie przetwarzanego piksela
	int index = rowStartIndex;

	// wartość kanału najbardziej na lewo
	unsigned char leftmostValue = input[rowStartIndex];
	// wartość kanału najbardziej na prawo w wierszu
	unsigned char rightmostValue = input[rowStartIndex + (width - 1) * INT_SIZE];
	// suma skumulowana dla aktualnego piksela
	int value = (radius + 1) * leftmostValue;

	// kontynuacja liczenia sumy skumulowanej dla pierwszego piksela do promienia
	for (int i = 0; i < radius; i++)
	{
		value += input[(rowStartIndex + i) * INT_SIZE];
	}

	// dla pierwszych pikseli w wierszu(w zakresie promienia)
	for (int i = 0; i <= radius; i++)
	{
		// dodaj kolejną wartość kanału po prawej stronie i odejmij wartość najbardziej na lewo, tak aby uzyskac sume radius pixeli
		value += input[rightBoundIndex] - leftmostValue;
		// przesuń indeks na kolejną wartość
		rightBoundIndex += INT_SIZE;
		// oblicz wartość docelową
		unsigned char targetValue = (unsigned char)(value / diameter);
		// zapisz wartość do bufora wyjściowego
		output[index] = targetValue;
		// przesuń indeks aktualnie przetwarzanego elementu
		index += INT_SIZE;
	}
	//piksel w prawo do końca wiersza  
	for (int i = radius + 1; i < width - radius; i++)
	{
		// dodaj kolejną wartość kanału po prawej stronie i odejmij wartość wskazywaną przez lewy indeks
		value += input[rightBoundIndex] - input[leftBoundIndex];
		// przesuń indeksy na kolejne wartości:
		rightBoundIndex += INT_SIZE;
		leftBoundIndex += INT_SIZE;
		// oblicz wartość docelową
		unsigned char targetValue = (unsigned char)(value / diameter);
		// zapisz wartość do bufora wyjściowego
		output[index] = targetValue;
		// przesuń indeks aktualnie przetwarzanego elementu
		index += INT_SIZE;
	}

	// dla ostatnich pikseli w wierszu(w zakresie promienia)
	for (int i = width - radius; i < width; i++)
	{
		// dodaj wartość kanału najbardziej na prawo i odejmij wartość wskazywaną przez lewy indeks
		value += rightmostValue - input[leftBoundIndex];
		// przesuń indeks na kolejną wartość
		leftBoundIndex += INT_SIZE;
		// oblicz wartość docelową
		unsigned char targetValue = (unsigned char)(value / diameter);
		// zapisz wartość do bufora wyjściowego
		output[index] = targetValue;
		// przesuń indeks aktualnie przetwarzanego elementu
		index += INT_SIZE;
	}
}

// Wykonuje rozmycie w pionie (dla kolumny) dla danego kanału. 
void BoxBlurVerticalBytes(unsigned char *input, unsigned char *output, int width, int height, int radius, int diameter) {
	// indeks początkowy
	int columnStartIndex = 0;
	// indeks o promień 'w górę' (bądź granica obrazu)
	int topBoundIndex = columnStartIndex;
	// indeks o promień 'w dół' (bądź granica obrazu)
	int bottomBoundIndex = columnStartIndex + (width * radius * INT_SIZE);
	// indeks aktualnie przetwarzanego elementu
	int index = columnStartIndex;

	// wartość kanału w pierwszym wierszu kolumny
	unsigned char topmostValue = input[columnStartIndex];
	// wartość kanału w ostatnim wierszu kolumny
	unsigned char bottommestValue = input[columnStartIndex + (width * (height - 1) * INT_SIZE)];
	// suma skumulowana dla danego piksela
	int value = (radius + 1) * topmostValue;

	// kontynuacja obliczenia sumy skumulowanej dla pierwszego elementu
	for (int j = 0; j < radius; j++)
	{
		value += input[columnStartIndex + (j * width * INT_SIZE)];
	}

	// obliczanie wartości wyjściowych dla elementów w zakresie promienia od pierwszego elementu
	for (int j = 0; j <= radius; j++)
	{
		// dodaj wartości elementów o promień w dół od aktualnego elementu i odejmij wartość pierwszego w kolumnie
		value += input[bottomBoundIndex] - topmostValue;
		// oblicz wartość wyjściową
		unsigned char targetValue = (unsigned char)(value / diameter);
		// zapisz wartość wyjściową
		output[index] = targetValue;

		// zwiększ dolny indeks
		bottomBoundIndex += width * INT_SIZE;
		// zwiększ indeks aktualnie przetwarzanego elementu
		index += width * INT_SIZE;
	}

	for (int j = radius + 1; j < height - radius; j++)
	{
		value += input[bottomBoundIndex] - input[topBoundIndex];
		// oblicz wartość wyjściową
		unsigned char targetValue = (unsigned char)(value / diameter);
		// zapisz wartość wyjściową
		output[index] = targetValue;

		// zwiększ górny indeks
		topBoundIndex += width * INT_SIZE;
		// zwiększ dolny indeks
		bottomBoundIndex += width * INT_SIZE;
		// zwiększ indeks aktualnie przetwarzanego elementu
		index += width * INT_SIZE;
	}

	// dla ostatnich pikseli w kolumnie (w zakresie promienia)
	for (int j = height - radius; j < height; j++)
	{
		value += bottommestValue - input[topBoundIndex];
		// oblicz wartość wyjściową
		unsigned char targetValue = (unsigned char)(value / diameter);
		// zapisz wartość wyjściową
		output[index] = targetValue;

		// zwiększ górny indeks
		topBoundIndex += width * INT_SIZE;
		// zwiększ indeks aktualnie przetwarzanego elementu
		index += width * INT_SIZE;
	}
}

extern "C" {
	// Oblicza wielkości pudełek dla zadanej ilości i sigmy, a następnie ładuje do tablicy boxes.
	__declspec(dllexport) void GetBoxes(int *boxes, int count, double sigma) {
		// obliczenie idealnej szerokości pudełka zgodnie z zadanym wzorem
		// wzór na uzyskanie idealnej syerokości filtru uśredniającaego, który odpowiada odchyleniu standardowemu filtru gaussa
		double idealWidth = sqrt((12 * sigma * sigma / count) + 1); //kernel szerokość jądra
		//Zaokrąglij w dół i zrzutuj na int 
		int width = (int)floor(idealWidth);
		// szerokość powinna być nieparzysta ponieważ zawsze chcemy aby środkowy pixel miał przypisany wynik
		if (width % 2 == 0)
		{
			width--;
		}
		// zwiększenie szerokości o 2 ponieważ będziemy przechodzić 3 filtrami dla obrazu
		int incrementedWidth = width + 2;

		// obliczenie idealnego maksimum z zadanego wzoru
		double idealMaximum = (12 * sigma * sigma - count * width * width - 4 * count * width - 3 * count) / (-4 * width - 4);
		// zaokrąglanie (>=0,5) liczbę podwójnej precyzji idealMaximum w liczbę całkowitą
		int maximum = (int)round(idealMaximum);

		for (int i = 0; i < count; i++) {
			// obliczanie i-tego elementu tablicy wielkości pudełek
			boxes[i] = i < maximum ? width : incrementedWidth;

		}
	}

	// Dokonuj rozmycia filtrem box filter w poziomie (dla wiersza).
	__declspec(dllexport) void BoxBlurHorizontal(int *input, int *output, int width, int radius) {
		// będziemy traktować wejście/wyjście jako bajty
		//reinterpret_cast zmiana jednego wskaźnika na drugi
		unsigned char *byteInput = reinterpret_cast<unsigned char*>(input);
		unsigned char *byteOutput = reinterpret_cast<unsigned char*>(output);

		// jeśli wartości wejściowe są niepoprawne zakończ procedurę
		if (width <= 0) {
			return;
		}

		// zabezpieczenie przed zbyt dużym lub ujemnym promieniem
		 radius = max(0, min(radius, width / 2 - 1));

		// obliczenie uśrednienia dla pixeli liczba musi być nie parzysta bo pod uwage bierzemy również pixel wynikowy
		int diameter = (radius + radius + 1);

		// wywołaj odpowiednią procedurę dla każdego kanału ARGB
		BoxBlurHorizontalBytes(byteInput, byteOutput, width, radius, diameter);
		BoxBlurHorizontalBytes(byteInput + 1, byteOutput + 1, width, radius, diameter);
		BoxBlurHorizontalBytes(byteInput + 2, byteOutput + 2, width, radius, diameter);
		BoxBlurHorizontalBytes(byteInput + 3, byteOutput + 3, width, radius, diameter);
	}

	__declspec(dllexport) void BoxBlurVertical(int *input, int *output, int width, int height, int radius) {
		// będziemy traktować wejście/wyjście jako bajty
		unsigned char *byteInput = reinterpret_cast<unsigned char*>(input);
		unsigned char *byteOutput = reinterpret_cast<unsigned char*>(output);

		// jeśli wartości wejściowe są niepoprawne zakończ procedurę
		if (width <= 0 || height <= 0) {
			return;
		}

		// zabezpieczenie przed zbyt dużym lub ujemnym promieniem
		radius = max(0, min(radius, height / 2 - 1));
		// obliczenie średnicy
		int diameter = (radius + radius +1);
		
		// wywołaj odpowiednią procedurę dla każdego kanału ARGB
		BoxBlurVerticalBytes(byteInput, byteOutput, width, height, radius, diameter);
		BoxBlurVerticalBytes(byteInput + 1, byteOutput + 1, width, height, radius, diameter);
		BoxBlurVerticalBytes(byteInput + 2, byteOutput + 2, width, height, radius, diameter);
		BoxBlurVerticalBytes(byteInput + 3, byteOutput + 3, width, height, radius, diameter);
	}
}

