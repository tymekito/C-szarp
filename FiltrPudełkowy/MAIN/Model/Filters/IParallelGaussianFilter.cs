using System;
using System.Drawing;
using System.Threading.Tasks;

namespace Pl.Bbit.GaussianFilterApp.Model.Filters
{
    public interface IParallelGaussianFilter
    {
        double Sigma { get; set; }
        ParallelOptions ParallelOptions { get; set; }
        Bitmap ApplyFilter(Bitmap bitmap);
        TimeSpan Measurement { get; }
    }
}
