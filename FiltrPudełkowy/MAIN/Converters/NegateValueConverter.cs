using System;
using System.Globalization;
using System.Windows.Data;

namespace Pl.Bbit.GaussianFilterApp.Converters
{
    /// <summary>
    /// Konwerter odwracający wartość logiczną.
    /// </summary>
    class NegateValueConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return !(bool)value;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return !(bool)value;
        }
    }
}
