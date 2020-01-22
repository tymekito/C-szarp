using Pl.Bbit.GaussianFilterApp.Model;
using Pl.Bbit.GaussianFilterApp.Model.Filters;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Text;

namespace Statystyk
{
    class Program
    {
        private const string Assembly = "assembly";
        private const string HL = "hl";

        static void Main(string[] args)
        {
            //struct with 4 values
            Configuration config = new Configuration();

            try
            {
                //string
                config.InputPath = args[0];
                config.MaxThreadsCount = int.Parse(args[1]);
                config.IterationCount = int.Parse(args[2]);
                config.Sigma = double.Parse(args[3]);
                //Run program with arguments
                Run(config);
            }
            catch (Exception ex)
            {
                if(ex is IndexOutOfRangeException || ex is FormatException)
                {
                    Console.WriteLine("Please provide us with 4 args: <filepath> <maxThreadsCount> <iterationCount> <sigma>");
                } else
                {
                    Console.Error.WriteLine(ex.Message);
                    Console.Write(ex.StackTrace);
                }
            }
        }
        //przekazanie argumentów i puszczenie próbnych funkcji
        private static void Run(Configuration config)
        {
            //przekazanie wczytanej bitmapy
            Bitmap bitmap = new Bitmap(config.InputPath);
            //co to za kolekcja??
            Dictionary<int, IList<TimeSpan>> results;
            //przekazujemy parametry a metoda zwraca nam odpowedni filtrm getter dla filtru
            IParallelGaussianFilter filter = GetFilter(Assembly);
            //ustawienie przekazanych wartosci 
            filter.Sigma = config.Sigma;
            results = RunFilter(filter, bitmap, config.MaxThreadsCount, config.IterationCount);
            SaveResults(config, bitmap, results, Assembly);

            filter = GetFilter(HL);
            filter.Sigma = config.Sigma;
            results = RunFilter(filter, bitmap, config.MaxThreadsCount, config.IterationCount);
            SaveResults(config, bitmap, results, HL);
            
        }
   
        private static Dictionary<int, IList<TimeSpan>> RunFilter(IParallelGaussianFilter filter, Bitmap bitmap, int maxThreadsCount, int iterationCount)
        {
            Dictionary<int, IList<TimeSpan>> results = new Dictionary<int, IList<TimeSpan>>();

            //wykonujemy operacje na 1,2,3...,maxThreadsCount wątkach
            for (int i = 1; i <= maxThreadsCount; i++)
            {
                Console.WriteLine($"Thread count: {i}");
                results.Add(i, new List<TimeSpan>(iterationCount));
               //i liczba współbierznych procesów obsługująca dany proces
               filter.ParallelOptions.MaxDegreeOfParallelism = i;

               // for (int j = 0; j < iterationCount; j++)
              //  {

                    bitmap = filter.ApplyFilter(bitmap);
                    //czas operacji filtru
                    results[i].Add(filter.Measurement);
              // }
            }
            bitmap.Save(@"C:\Users\kazim\Desktop\Studia\JA\Projekt\Źródła\Statystyk\Image2.bmp", ImageFormat.Bmp);
            return results;
        }

        private static IParallelGaussianFilter GetFilter(string implementation)
        {
            IFilterProvider filterProvider = new FilterProviderImpl();
            switch(implementation.ToLower())
            {
                case Assembly:
                    return filterProvider.GetAssemblyImplementation();
                case HL:
                    return filterProvider.GetHighLevelImplementation();
            }

            throw new ArgumentException("Wrong implementation name!");
        }
       
        // wypisanie parametrow na konsole
        private static void SaveResults(Configuration config, Bitmap bitmap, IDictionary<int, IList<TimeSpan>> results, string implIdentifier)
        {
            string resultPath = $"{config.InputPath}_{implIdentifier}.txt";
           
            //tworzenie wyniku
            StringBuilder builder = new StringBuilder();

            builder.AppendLine($"File: {config.InputPath}, size: {bitmap.Width}x{bitmap.Height} (width x height).");
            builder.AppendLine($"Iterations: {config.IterationCount}, sigma: {config.Sigma}.");

            builder.AppendLine();
            builder.AppendLine("Threads;Min [ms];Max [ms];Average [ms]; StDev [ms]");

            for(int i = 1; i <= config.MaxThreadsCount; i++)
            {
                IList<TimeSpan> timeSpans = results[i];

                TimeSpan min = timeSpans.Min();
                TimeSpan max = timeSpans.Max();
                TimeSpan average = new TimeSpan((long)timeSpans.Average(t => t.Ticks));
                TimeSpan standardDeviation = CalculateStandardDeviation(timeSpans);
                builder.AppendLine($"{i};{min.TotalMilliseconds};{max.TotalMilliseconds};{average.TotalMilliseconds};{standardDeviation.TotalMilliseconds}");
            }
            
            File.WriteAllText(resultPath, builder.ToString());
       
        }

        private static TimeSpan CalculateStandardDeviation(IEnumerable<TimeSpan> values)
        {
            TimeSpan result = new TimeSpan();
            int count = values.Count();
            if (count > 1)
            {
                double average = values.Average(t => t.Ticks);
                double sum = values.Sum(t => (t.Ticks - average) * (t.Ticks - average));
                double ticksResult = Math.Sqrt(sum / count);
                result = new TimeSpan((long)ticksResult);
            }

            return result;
        }
    }
}
