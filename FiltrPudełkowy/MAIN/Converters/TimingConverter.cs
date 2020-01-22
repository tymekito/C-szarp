using System;
using System.Globalization;
using System.Windows.Data;

namespace Pl.Bbit.GaussianFilterApp.Converters
{
    /// <summary>
    /// Konwerter dla wyświetlania czasu przetwarzania algorytmu.
    /// </summary>
    class TimingConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            string info;

            if(value == null)
            {
                info = "brak";
            }
            else
            {
                TimeSpan timeSpan = (TimeSpan)value;
                double totalMilliseconds = timeSpan.TotalMilliseconds;
                info = timeSpan.TotalMilliseconds > 1000.0 ? $"{timeSpan.TotalSeconds:0.000}s" : $"{timeSpan.TotalMilliseconds:0.000}ms";
            }

            return $"{parameter}: {info}";
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
