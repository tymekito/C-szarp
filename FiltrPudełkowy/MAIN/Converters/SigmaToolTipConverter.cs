using Pl.Bbit.GaussianFilterApp.View;

namespace Pl.Bbit.GaussianFilterApp.Converters
{
    /// <summary>
    /// Konwerter dla wyświetlania tooltipa z wartością sigma.
    /// </summary>
    class SigmaToolTipConverter : IToolTipConverter
    {
        public string Convert(double value)
        {
            double actualValue = SigmaSliderValueConverter.ConversionFactor * value;
            return $"σ = {actualValue:0.00}";
        }
    }
}
