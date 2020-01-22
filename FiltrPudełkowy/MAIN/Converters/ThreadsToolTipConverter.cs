using Pl.Bbit.GaussianFilterApp.View;
using System;

namespace Pl.Bbit.GaussianFilterApp.Converters
{
    /// <summary>
    /// Konwerter dla wyświetlanego tooltipa z ilością wątków.
    /// </summary>
    class ThreadsToolTipConverter : IToolTipConverter
    {
        public string Convert(double value)
        {
            int threads = (int)Math.Round(value);
            return $"Liczba wątków: {threads}";
        }
    }
}
