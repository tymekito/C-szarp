using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Statystyk
{
    struct Configuration
    {
        public string InputPath { get; set; }
        public int MaxThreadsCount { get; set; }
        public int IterationCount { get; set; }
        public double Sigma { get; set; }
    }
}
