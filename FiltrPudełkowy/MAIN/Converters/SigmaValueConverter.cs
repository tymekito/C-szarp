using System;
using System.Globalization;
using System.Windows.Data;

namespace Pl.Bbit.GaussianFilterApp.Converters
{
    /// <summary>
    /// Konwerter dla wyświetlania informacji o wybranej wartości sigmy.
    /// </summary>
    class SigmaValueConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            double sigma = (double)value;
            return $"σ = {sigma,5:#0.00}";
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
