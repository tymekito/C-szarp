using System;
using System.Windows;
using Microsoft.Win32;
using Pl.Bbit.GaussianFilterApp.Model;
using Pl.Bbit.GaussianFilterApp.ViewModel;

namespace Pl.Bbit.GaussianFilterApp
{
    /// <summary>
    /// Logika interakcji dla klasy MainWindow.xaml
    /// </summary>
    public partial class ImageWindow : Window
    {
        private ImageWindowViewModel viewModel;

        //rozszerznie klasy ImageWindow tworząc ImageWindow xaml również pobiera kod z tej klasy obiekt tworzony z dwóch kodów
        public ImageWindow()
        {
            //inicjalizujemy komponent tworzymy nowy obiekt który zaciągnie dll
            InitializeComponent();
            IFilterProvider filterProvider = new FilterProviderImpl();
            viewModel = new ImageWindowViewModel(filterProvider);
            viewModel.ExceptionEvent += OnExceptionEvent;
            viewModel.SaveFileDialogEvent += ShowSaveFileDialog;
            DataContext = viewModel;
        }

        private void ShowSaveFileDialog(object sender, EventArgs e)
        {
            string format = "yyyyMMdd_HHmmss";
            SaveFileDialog saveFileDialog = new SaveFileDialog
            {
                FileName = $"Obrazek_{DateTime.Now.ToString(format)}",
                DefaultExt = ".bmp",
                Filter = "Bitmapy (.bmp)|*.bmp"
            };
            
            bool? result = saveFileDialog.ShowDialog();
            
            if (result == true)
            {
                viewModel.SaveImageToFile(saveFileDialog.FileName);
            }
        }
        //messageBox zamiast konsoli, alternatywne obsłużenie wyjątku
        private void OnExceptionEvent(object sender, Exception e)
        {
            MessageBox.Show(e.Message);
        }

        private void RadioButton_Checked(object sender, RoutedEventArgs e)
        {

        }
    }
}
