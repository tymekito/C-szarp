using Pl.Bbit.GaussianFilterApp.Model.Filters;
using System;
using System.Runtime.InteropServices;

namespace Pl.Bbit.GaussianFilterApp.Model
{
    public class FilterProviderImpl : IFilterProvider
    {
        //hierarchia bibliotek 3 systemowe bliblioteki potem folder

        //załadowanie biblioteki systemowej kernel32.dll funkcje podanej nazwie i przekaż do nich argumenty
        [DllImport("kernel32.dll")]
        public static extern IntPtr LoadLibrary(string dllToLoad);

        [DllImport("kernel32.dll")]
        public static extern bool FreeLibrary(IntPtr hModule);

        private const string AssemblyDllName = "DLL_ASM.dll";
        private const string HLDllName = "DLL_C.dll";

        public IParallelGaussianFilter GetAssemblyImplementation()
        {
            //ładuje wskażnik 0
            IntPtr library = IntPtr.Zero;
            try
            {
                //przekazanie wskaźnika na początek pamięci
                library = LoadLibrary(AssemblyDllName);
                // zwracamy stworzony obiekt typu FilterWrapper
                FilterWrapper filterWrapper = new FilterWrapper(library);
                return filterWrapper;
            } catch(Exception)
            {
                FreeLibrary(library);
                throw new LibraryException($"Nie udało się załadować biblioteki '{AssemblyDllName}'");
            }
        }

        public IParallelGaussianFilter GetHighLevelImplementation()
        {
            IntPtr library = IntPtr.Zero;
            try
            {
                library = LoadLibrary(HLDllName);
                FilterWrapper filterWrapper = new FilterWrapper(library);
                return filterWrapper;
            }
            catch (Exception)
            {
                FreeLibrary(library);
                throw new LibraryException($"Nie udało się załadować biblioteki '{HLDllName}'");
            }
        }
    }
}
