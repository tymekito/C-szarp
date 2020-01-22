using Pl.Bbit.GaussianFilterApp.View;
using System;
using System.Globalization;
using System.Windows.Data;

namespace Pl.Bbit.GaussianFilterApp.Converters
{
    /// <summary>
    /// Konwerter dopasowujący wartość do widocznej wartości na UI, w kontrolce Slidera.
    /// </summary>
    class SigmaSliderValueConverter : IValueConverter
    {
        /// <summary>
        /// Skala konwersji.
        /// </summary>
        public const double ConversionFactor = 0.25;

        /// <summary>
        /// Odwrócona skala konwersji.
        /// </summary>
        public const double ConversionFactorReversed = 1 / ConversionFactor;

        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return (double)value * ConversionFactorReversed;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return (double)value * ConversionFactor;
        }
    }
}
