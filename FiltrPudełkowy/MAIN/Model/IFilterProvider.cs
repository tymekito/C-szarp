using Pl.Bbit.GaussianFilterApp.Model.Filters;

namespace Pl.Bbit.GaussianFilterApp.Model
{
    //Implementation choice button
    public interface IFilterProvider
    {
        IParallelGaussianFilter GetHighLevelImplementation();
        IParallelGaussianFilter GetAssemblyImplementation();
    }
}
