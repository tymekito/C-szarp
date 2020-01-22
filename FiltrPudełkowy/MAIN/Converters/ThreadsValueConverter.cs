using System;
using System.Globalization;
using System.Windows.Data;

namespace Pl.Bbit.GaussianFilterApp.Converters
{
    /// <summary>
    /// Konwerter dla wyświetlania wybranej ilości wątków.
    /// </summary>
    class ThreadsValueConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            int threadsCount = (int)value;
            return $"Wątki: {threadsCount,2:###}";
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
