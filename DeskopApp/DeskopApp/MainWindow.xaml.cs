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
        private long total = 0;//Total
        private long subtotal = 0;//subtotal
        private long inputNumber = 0;
        private string operation = ""; // variable represent operation 
        /**
         * Display number in parameters in TextBox 
         */
        private void DisplayResult(float number)
        {
            this.Sum.Text = number.ToString();       
        }
        /**
         * Main window implementation
         */
        public MainWindow()
        {
            InitializeComponent();
            this.WindowStartupLocation = WindowStartupLocation.CenterScreen;

        }
        /**
         * Calculator logic takes one arhument number
         */ 
        private void AddToNumber(long number)
        {
            // if dont click operation so add it to Total 
            if (operation.Equals(""))
            {
                total = (total * 10) + number;
                this.DisplayResult(total);
            }
            else
            {
                // add number to subSum
                subtotal = (subtotal * 10) + number;
                this.DisplayResult(subtotal);
            }

        }
        // multiply number to change value (positive to negative)
        private void btnPositiveNegative_Click()
        {
            if (operation.Equals(""))
            {
                total *= -1;
                this.DisplayResult(total);
            }
            else
            {
                subtotal *= -1;
                this.DisplayResult(subtotal);
            }
        }
        /*
         * Find input symbol and do operation
         */ 
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
                    subtotal = 0;
                    total = 0;
                    operation = "";
                    DisplayResult(subtotal);
                    break;
                case "Button_Equals":
                    Find_Operation(operation);
                    break;
                case "Button_Plus":
                    DisplayResult(subtotal);
                    operation = "+";
                    break;
                case "Button_Minus":
                    operation = "-";
                    DisplayResult(subtotal);
                    break;
                case "Button_Multiply":
                    operation = "*";
                    DisplayResult(subtotal);
                    break;
                case "Button_Divide":
                    operation = "/";
                    DisplayResult(subtotal);
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
                    DisplayResult(total += subtotal);
                    break;
                case "-":
                    DisplayResult(total -= subtotal);
                    break;
                case "*":
                    DisplayResult(total *= subtotal);
                    break;
                case "/":
                    DisplayResult(total /= subtotal);
                    break;
                default:
                    break;
            }
            //after operation reset subtotal becouse user want input another number
            subtotal = 0;
        }
    }
}
