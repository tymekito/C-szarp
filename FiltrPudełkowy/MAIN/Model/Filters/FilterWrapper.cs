using Pl.Bbit.GaussianFilterApp.Utils;
using System;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Security;
using System.Threading.Tasks;

namespace Pl.Bbit.GaussianFilterApp.Model.Filters
{
    // Klasa wrapper dla implementacji filtrów.

    unsafe class FilterWrapper : IParallelGaussianFilter
    {
        //zwalnia załadowane DLL zmiejszając ich liczbę więzów referncyjnych
        [DllImport("kernel32.dll")]
        public static extern bool FreeLibrary(IntPtr hModule);
        //Pobiera adres wyeksportowanej funkcji lub zmiennej z określonej DLL o nazwie procedureName 
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetProcAddress(IntPtr hModule, string procedureName);
        //importuje podaną funkcję, wywołanie jej czyści stos wywołań
        [DllImport("msvcrt.dll", EntryPoint = "memcpy", CallingConvention = CallingConvention.Cdecl, SetLastError = false),
            SuppressUnmanagedCodeSecurity]
        //zewnętrzna funkcja systemowa kopiuje jeden fragment pamięci w inne miejsce o określonym rozmiarze
        private static unsafe extern void* CopyMemory(void* destination, void* source, ulong lenght);
        // mówi w jakiej kolejności będą przekazywane argumenty do funkcji
        [UnmanagedFunctionPointer(CallingConvention.StdCall)]
        private delegate void GetBoxesDelegate(uint* buffer, uint boxesCount, double sigma);

        [UnmanagedFunctionPointer(CallingConvention.StdCall)]
        private delegate void BoxBlurHorizontalDelegate(uint* input, uint* output, uint width, uint radius);

        [UnmanagedFunctionPointer(CallingConvention.StdCall)]
        private delegate void BoxBlurVerticalDelegate(uint* input, uint* output, uint width, uint height, uint radius);

        private readonly Stopwatch _stopWatch = new Stopwatch();

        private IntPtr _library;
        private GetBoxesDelegate _getBoxes;
        private BoxBlurHorizontalDelegate _boxBlurHorizontal;
        private BoxBlurVerticalDelegate _boxBlurVertical;
        //rownolegle chodzace wątki
        public ParallelOptions ParallelOptions { get; set; } = new ParallelOptions();
        public double Sigma { get; set; }
        public int Boxes { get; set; }

        public TimeSpan Measurement => _stopWatch.Elapsed;
       
        //różne sposoby tworzenia obiektu
        public FilterWrapper(IntPtr library) : this(library, 1.0)
        { }

        public FilterWrapper(IntPtr library, double sigma) : this(library, sigma, 3)
        { }

        public FilterWrapper(IntPtr library, double sigma, int boxes)
        {
            _library = library;
             Sigma = sigma;
             Boxes = boxes;

            // Pobieramy adresy wszystkich potrzebnych funkcji
            //znajduje w lib funkcje o takie nazwie
            IntPtr getBoxes = GetProcAddress(_library, "GetBoxes");
            IntPtr boxBlurHorizontal = GetProcAddress(_library, "BoxBlurHorizontal");
            IntPtr boxBlurVertical = GetProcAddress(_library, "BoxBlurVertical");

            if(getBoxes != IntPtr.Zero)
            {
                _getBoxes = (GetBoxesDelegate)Marshal.GetDelegateForFunctionPointer(getBoxes, typeof(GetBoxesDelegate));
            }
            else
            {
                throw new LibraryException("GetBoxes() not found!");
            }

            if (boxBlurHorizontal != IntPtr.Zero)
            {
                _boxBlurHorizontal = (BoxBlurHorizontalDelegate)Marshal.GetDelegateForFunctionPointer(boxBlurHorizontal, typeof(BoxBlurHorizontalDelegate));
            }
            else
            {
                throw new LibraryException("BoxBlurHorizontal() not found!");
            }

            if (boxBlurVertical != IntPtr.Zero)
            {
                _boxBlurVertical = (BoxBlurVerticalDelegate)Marshal.GetDelegateForFunctionPointer(boxBlurVertical, typeof(BoxBlurVerticalDelegate));
            }
            else
            {
                throw new LibraryException("BoxBlurVertical() not found!");
            }
        }
        /*
         * Zbindowane pod przycisk, konwertujemy bitmape z formatu wejsciowego na nasz który będziemy mogli przerobic
         */
        public Bitmap ApplyFilter(Bitmap bitmap)
        {

            uint* input = null;
            uint* output = null;

            try
            {
                // Konwertujemy bitmapę do formatu 32-bitowego (argb)
                Bitmap bitmapInArgb = BitmapUtils.BitmapToArgb32(bitmap);

                int width = bitmapInArgb.Width;
                int height = bitmapInArgb.Height;
                //Pole bitmapy
                int size = width * height;

                Rectangle imageRectangle = new Rectangle(0, 0, width, height);
                BitmapData bitmapData = bitmapInArgb.LockBits(imageRectangle, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
                //int zawiera 4 byte, 1 byte 8 bitów
                int byteSize = Marshal.SizeOf(typeof(uint)) * size;

                // Alokujemy niezarządzaną tablicę dla danych wejściowych/wyjściowych, rzutując obiekt na wsk unisigned int ustawiając wskaźnik na naszą zmienna input
                input = (uint*)Marshal.AllocHGlobal(byteSize).ToPointer();
                output = (uint*)Marshal.AllocHGlobal(byteSize).ToPointer();
                void* bitmapPtr = bitmapData.Scan0.ToPointer();
                //kopiuje pamieć do input z bitmapPtr
                CopyMemory(input, bitmapPtr, (ulong)byteSize);

                bitmapInArgb.UnlockBits(bitmapData);

                // Resetujemy stoper i go startujemy
                _stopWatch.Reset();
                //sprawdzamy ile czas oricedura ProcessImage zajmie czasu
                _stopWatch.Start();

                // Właściwe przetwarzanie:
                uint* result = ProcessImage(input, output,
                    (uint)width, (uint)height, Sigma, Boxes);

                _stopWatch.Stop();
                // zapisanie nowej bitmapy i zwolnienie pamieci

                Bitmap bitmapResult = new Bitmap(width, height, PixelFormat.Format32bppArgb);
                BitmapData resultData = bitmapResult.LockBits(new Rectangle(0, 0, width, height), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
                //kopiowanie pamieci
                CopyMemory(resultData.Scan0.ToPointer(), result, (uint)(resultData.Stride * resultData.Height));
                bitmapResult.UnlockBits(resultData);

                return bitmapResult;
            } finally
            {
                //zwolnienie pamięci
                Marshal.FreeHGlobal(new IntPtr(input));
                Marshal.FreeHGlobal(new IntPtr(output));
            }
        }

        private uint* ProcessImage(uint* input, uint* output,
            uint width, uint height, double sigma, int boxesCount)
        {
            int boxesByteSize = Marshal.SizeOf(typeof(uint)) * boxesCount;
            uint* boxes = (uint*)Marshal.AllocHGlobal(boxesByteSize).ToPointer();

            try
            {
                //idealny promien rozmycia
                //trzy warstwy z różnymi promieniami rozmycia 
                _getBoxes(boxes, (uint)boxesCount, sigma);

                for (int i = 0; i < boxesCount; i++)
                {
                 uint radius =(boxes[1] - 1) / 2;
                 ProcessHorizontal(input, output, width, height, radius);
              
                //czemu na odwrót?
                ProcessVertical(output, input, width, height, radius);
                }
            } finally
            {
                //usuniecie zalokowanej pamieci
                Marshal.FreeHGlobal(new IntPtr(boxes));
            }
            

            return input;
        }

        private void ProcessHorizontal(uint* input, uint* output, uint width, uint height, uint radius)
        {
            //wykonywane dla 
            //for rownoległych obliczen tyle ile w argumecie ParallelOptions
            //wykonuje sie tyle ile jest hight dla każdego wiersza
            //początkowy numer i, warunek zakończenia, ilość wykonywanych równolegle procesów, 
            Parallel.For(0, height, ParallelOptions, (i) =>
            {

                //zacznij petle oddalona o offset
                 uint offset = (uint)(i * width);
                _boxBlurHorizontal(input + offset, output + offset, width, radius);
            });

        }

        private void ProcessVertical(uint* input, uint* output, uint width, uint height, uint radius)
        {
            Parallel.For(0, width, ParallelOptions, (i) =>
            {
                //do zrobienia wyrazenie lambda
                _boxBlurVertical(input + i, output + i, width, height, radius);
            });
        }
        


        ~FilterWrapper()
        {
            FreeLibrary(_library);
            GC.SuppressFinalize(this);

        }


    }
}
