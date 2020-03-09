using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Karteczki
{
   public partial class Form1 : Form
   {
        int windowX = 0, windowY = 0, mouseX = 0, mouseY = 0;
      public Form1()
      {
         InitializeComponent();
      }

      private void borderToolStripMenuItem_Click(object sender, EventArgs e)
      {
         if(FormBorderStyle == FormBorderStyle.None)
         {
            FormBorderStyle = FormBorderStyle.FixedToolWindow;
         }
         else
         {
            FormBorderStyle = FormBorderStyle.None;
         }
            
      }

      private void newCardToolStripMenuItem_Click(object sender, EventArgs e)
      {
         new Form1().Show();
      }
        
      private void deleteCardToolStripMenuItem_Click(object sender, EventArgs e)
      {
         Close();
      }

      private void alwaysOnTopToolStripMenuItem_Click(object sender, EventArgs e)
      {
         if(TopMost == false)
            TopMost = true;
         else
            TopMost = false;
      }

      private void exitToolStripMenuItem_Click(object sender, EventArgs e)
      {
         Application.Exit();
      }

        private void pictureBox1_MouseDown(object sender, MouseEventArgs e)
        {
            windowX = Location.X;
            windowY = Location.Y;
            mouseX = e.X;
            mouseY = e.Y;
        }

        private void pictureBox1_MouseMove(object sender, MouseEventArgs e)
        {
            if(e.Button==MouseButtons.Left)
            {
                Location = new Point(Location.X + (e.X - mouseX), Location.Y + (e.Y - mouseY));
            }
        }

        private void saveToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (saveFileDialog1.ShowDialog() == DialogResult.OK)
                richTextBox1.SaveFile(saveFileDialog1.FileName);
        }

        private void openToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (openFileDialog1.ShowDialog() == DialogResult.OK)
                richTextBox1.LoadFile(openFileDialog1.FileName);
        }

        private void centerToolStripMenuItem_Click(object sender, EventArgs e)
        {
            richTextBox1.SelectionAlignment = HorizontalAlignment.Center;
        }

        private void leftToolStripMenuItem_Click(object sender, EventArgs e)
        {
            richTextBox1.SelectionAlignment = HorizontalAlignment.Left;
        }

        private void rightToolStripMenuItem_Click(object sender, EventArgs e)
        {
            richTextBox1.SelectionAlignment = HorizontalAlignment.Right;
        }

        private void aboutToolStripMenuItem_Click(object sender, EventArgs e)
      {
         MessageBox.Show( "O programie");
      }

      private void fontToolStripMenuItem_Click(object sender, EventArgs e)
      {
         fontDialog1.ShowDialog();
         richTextBox1.SelectionFont = fontDialog1.Font;
      }

      private void colorToolStripMenuItem_Click(object sender, EventArgs e)
      {
         colorDialog1.ShowDialog();
         richTextBox1.SelectionColor = colorDialog1.Color;
      }
   }
}






