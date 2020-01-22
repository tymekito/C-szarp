using System;

namespace Pl.Bbit.GaussianFilterApp.Utils
{
    public static class HardwareUtils
    {
        //sprawdza ile rdzeni posiada procesor
        public static int GetNumberOfCores()
        {
            int coreCount = 0;
            foreach (var item in new System.Management.ManagementObjectSearcher("Select * from Win32_Processor").Get())
            {
                coreCount += int.Parse(item["NumberOfCores"].ToString());
            }
            return coreCount;
        }

        public static int GetNumberOfLogicalProcessors()
        {
            return Environment.ProcessorCount;
        }
    }
}
