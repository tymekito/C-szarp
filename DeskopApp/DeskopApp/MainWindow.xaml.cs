using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace DeskopApp
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private float number1 = 0;//Total
        private float number2 = 0;//subtotal
        private float inputNumber = 0;
        private string operation = "";

        private void DisplayResult(float number)
        {
            this.Sum.Text = number.ToString();
        }
        public MainWindow()
        {
            InitializeComponent();
            this.Title = "Hello World";
            this.WindowStartupLocation = WindowStartupLocation.CenterScreen;

        }
        private void Window_MouseMove(object sender, MouseEventArgs e)
        {

        }
        private void AddToNumber(float number)
        {
            if (operation.Equals(""))
            {
                number1 = (number1 * 10) + number;
                this.DisplayResult(number1);
            }
            else
            {
                number2 = (number2 * 10) + number;
                this.DisplayResult(number2);
            }

        }
        private void btnPositiveNegative_Click()
        {
            if (operation.Equals(""))
            {
                number1 *= -1;
                this.DisplayResult(number1);
            }
            else
            {
                number2 *= -1;
                this.DisplayResult(number2);
            }
        }
        private void Button_Click(object sender, RoutedEventArgs e)
        {

            switch ((sender as Button).Tag.ToString())
            {
                case "Button_9":
                    inputNumber = 9;
                    AddToNumber(inputNumber);
                    break;
                case "Button_8":
                    inputNumber = 8;
                    AddToNumber(inputNumber);
                    break;
                case "Button_7":
                    inputNumber = 7;
                    AddToNumber(inputNumber);
                    break;
                case "Button_6":
                    inputNumber = 6;
                    AddToNumber(inputNumber);
                    break;
                case "Button_5":
                    inputNumber = 5;
                    AddToNumber(inputNumber);
                    break;
                case "Button_4":
                    inputNumber = 4;
                    AddToNumber(inputNumber);
                    break;
                case "Button_3":
                    inputNumber = 3;
                    AddToNumber(inputNumber);
                    break;
                case "Button_2":
                    inputNumber = 2;
                    AddToNumber(inputNumber);
                    break;
                case "Button_1":
                    inputNumber = 1;
                    AddToNumber(inputNumber);
                    break;
                case "Button_0":
                    inputNumber = 0;
                    AddToNumber(inputNumber);
                    break;
                case "Button_Reset":
                    number2 = 0;
                    number1 = 0;
                    operation = "";
                    DisplayResult(number2);
                    break;
                case "Button_Equals":
                    Find_Operation(operation);
                    break;
                case "Button_Plus":
                    DisplayResult(number2);
                    operation = "+";
                    break;
                case "Button_Minus":
                    operation = "-";
                    DisplayResult(number2);
                    break;
                case "Button_Multiply":
                    operation = "*";
                    DisplayResult(number2);
                    break;
                case "Button_Divide":
                    operation = "/";
                    DisplayResult(number2);
                    break;
                case "Plus_Minus":
                    btnPositiveNegative_Click();
                    break;
                default:
                    break;
            }
        }
        private void Find_Operation(string operationChar)
        {
            switch (operationChar)
            {
                case "+":
                    DisplayResult(number1 += number2);
                    break;
                case "-":
                    DisplayResult(number1 -= number2);
                    break;
                case "*":
                    DisplayResult(number1 *= number2);
                    break;
                case "/":
                    DisplayResult(number1 /= number2);
                    break;
                default:
                    break;
            }
            number2 = 0;
        }
    }
}
