using GalaSoft.MvvmLight.Command;
using System.ComponentModel;
using System.Drawing;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media.Imaging;
using Pl.Bbit.GaussianFilterApp.Utils;
using System.Threading.Tasks;
using System.Diagnostics;
using System;
using Pl.Bbit.GaussianFilterApp.Model;
using System.IO;
using Pl.Bbit.GaussianFilterApp.Model.Filters;

namespace Pl.Bbit.GaussianFilterApp.ViewModel
{
    // powiadomienie o zmianie wartośći właściowości programu
    class ImageWindowViewModel : INotifyPropertyChanged
    {
        private readonly IFilterProvider _filterProvider;

        private string _title;
        private FilterChoice _selectedFilter;
        private double _sigma;
        private int _threads;
        private bool _isProcessing;
        private Bitmap _sourceBitmap;
        private BitmapSource _sourceImage;
        private BitmapSource _filteredImage;
        private TimeSpan? _assemblyFilterTiming;
        private TimeSpan? _HLFilterTiming;
        private RelayCommand<DragEventArgs> _imageDrop;
        private RelayCommand _applyFilter;
        private RelayCommand _saveImage;

        private IParallelGaussianFilter _filterImpl = null;
        private FilterChoice? _previousFilterChoice = null;

        public string Title
        {
            get => _title;
            set
            {
                _title = value;
                OnPropertyChanged();
            }
        }

        public FilterChoice SelectedFilter
        {
            get => _selectedFilter;
            set
            {
                _selectedFilter = value;
                OnPropertyChanged();
            }
        }

        public double Sigma
        {
            get => _sigma;
            set
            {
                _sigma = value;
                OnPropertyChanged();
            }
        }

        public int Threads
        {
            get => _threads;
            set
            {
                _threads = value;
                OnPropertyChanged();
            }
        }

        public bool IsProcessing
        {
            get => _isProcessing;
            set
            {
                _isProcessing = value;
                OnPropertyChanged();
                _applyFilter.RaiseCanExecuteChanged();
                _saveImage.RaiseCanExecuteChanged();
            }
        }

        public BitmapSource SourceImage
        {
            get => _sourceImage;
            set
            {
                _sourceImage = value;
                OnPropertyChanged();
                _applyFilter.RaiseCanExecuteChanged();
            }
        }

        public BitmapSource FilteredImage
        {
            get => _filteredImage;
            set
            {
                _filteredImage = value;
                OnPropertyChanged();
                _saveImage.RaiseCanExecuteChanged();
            }
        }

        public TimeSpan? AssemblyFilterTiming
        {
            get => _assemblyFilterTiming;
            set
            {
                _assemblyFilterTiming = value;
                OnPropertyChanged();
            }
        }

        public TimeSpan? HLFilterTiming
        {
            get => _HLFilterTiming;
            set
            {
                _HLFilterTiming = value;
                OnPropertyChanged();
            }
        }

        public ICommand ImageDrop
        {
            get
            {
                if (_imageDrop == null)
                {
                    _imageDrop = new RelayCommand<DragEventArgs>((eventArgs) =>
                    {
                        LoadImage(eventArgs);
                    });
                }
                return _imageDrop;
            }
        }

        public ICommand ApplyFilter
        {
            get
            {
                if (_applyFilter == null)
                {
                    _applyFilter = new RelayCommand(() =>
                    {
                        ApplyFilterAsync();
                    }, () =>
                    {
                        return SourceImage != null && !IsProcessing;
                    });
                }
                return _applyFilter;
            }
        }
        
        public ICommand SaveImage
        {
            get
            {
                if (_saveImage == null)
                {
                    _saveImage = new RelayCommand(() =>
                    {
                        DisplaySaveFileDialog();
                    }, () =>
                    {
                        return FilteredImage != null && !IsProcessing;
                    });
                }
                return _saveImage;
            }
        }

        public event EventHandler<Exception> ExceptionEvent;
        public event EventHandler SaveFileDialogEvent;
        public event PropertyChangedEventHandler PropertyChanged;

        public ImageWindowViewModel(IFilterProvider filterProvider)
        {
            Title = "Wygładzanie krawędzi obrazu";
            _filterProvider = filterProvider;

            SelectedFilter = FilterChoice.HighLevelFilter;
            Sigma = 4.0;
            Threads = HardwareUtils.GetNumberOfLogicalProcessors();
        }

        public void SaveImageToFile(string filePath)
        {
            if(FilteredImage == null)
            {
                return;
            }

            FileStream fileStream = null;
            try
            {
                fileStream = new FileStream(filePath, FileMode.Create);
                BitmapEncoder encoder = new BmpBitmapEncoder();
                encoder.Frames.Add(BitmapFrame.Create(FilteredImage));
                encoder.Save(fileStream);
            } catch(Exception)
            {
                ExceptionEvent?.Invoke(this, new Exception("Nie udało się zapisać pliku!"));
            } finally
            {
                //sprawdź czy null jeśli nie, to zezów na dostęp do obiektu
                fileStream?.Dispose();
            }
        }

        private void LoadImage(DragEventArgs eventArgs)
        {
            if (eventArgs.Data.GetDataPresent(DataFormats.FileDrop))
            {
                try
                {
                    string imagePath = ((string[])eventArgs.Data.GetData(DataFormats.FileDrop))[0];
                
                    Bitmap bitmap = new Bitmap(imagePath);
                    Bitmap reformattedBitmap = BitmapUtils.BitmapToBgra32(bitmap);
                    BitmapSource bitmapSource = BitmapUtils.SourceFromBitmap(reformattedBitmap);
                    bitmapSource.Freeze();

                    _sourceBitmap = reformattedBitmap;
                    SourceImage = bitmapSource;
                    FilteredImage = null;
                    AssemblyFilterTiming = null;
                    HLFilterTiming = null;
                } catch(Exception ex)
                {
                    ExceptionEvent?.Invoke(this, new Exception($"Błąd przy ładowaniu obrazu: {ex.Message}"));
                }
            }
        }

        private async void ApplyFilterAsync()
        {
            FilteredImage = null;
            IParallelGaussianFilter filter = null;

            try
            {
                filter = GetCurrentFilter();
            } catch(LibraryException ex)
            {
                ExceptionEvent?.Invoke(this, ex);
            }

            if (filter != null)
            {
                try
                {
                    IsProcessing = true;
                    Bitmap bitmap = _sourceBitmap;
                    Bitmap bitmapClone = (Bitmap)bitmap.Clone();

                    Bitmap bitmapResult = await Task.Run(() => filter.ApplyFilter(bitmap));
                    FilteredImage = BitmapUtils.SourceFromBitmap(bitmapResult);

                    if (SelectedFilter == FilterChoice.AssemblyFilter)
                    {
                        AssemblyFilterTiming = filter.Measurement;
                    }
                    else
                    {
                        HLFilterTiming = filter.Measurement;
                    }
                } catch(Exception)
                {
                    ExceptionEvent?.Invoke(this, new Exception("Obraz jest za duży!"));
                } finally
                {
                    IsProcessing = false;
                }
                
            }
        }

        private void DisplaySaveFileDialog()
        {
            SaveFileDialogEvent?.Invoke(this, new EventArgs());
        }

        private IParallelGaussianFilter GetCurrentFilter()
        {
            if(_previousFilterChoice != SelectedFilter || _filterImpl == null)
            {

                _filterImpl = null;

                switch(SelectedFilter)
                {
                    case FilterChoice.HighLevelFilter:
                        _filterImpl = _filterProvider.GetHighLevelImplementation();
                        break;
                    case FilterChoice.AssemblyFilter:
                        _filterImpl = _filterProvider.GetAssemblyImplementation();
                        break;
                }
            }

            _filterImpl.Sigma = Sigma;
            _filterImpl.ParallelOptions.MaxDegreeOfParallelism = Threads;

            _previousFilterChoice = SelectedFilter;
            return _filterImpl;
        }

        protected virtual void OnPropertyChanged([CallerMemberName] string property = "")
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(property));
        }
    }
}
