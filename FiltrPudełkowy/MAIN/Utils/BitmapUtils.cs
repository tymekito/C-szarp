using System.Drawing;
using System.IO;
using System.Windows.Media.Imaging;

namespace Pl.Bbit.GaussianFilterApp.Utils
{
    public static class BitmapUtils
    {
        public static Bitmap BitmapFromSource(BitmapSource bitmapSource)
        {
            using (MemoryStream memoryStream = new MemoryStream())
            {
                BitmapEncoder encoder = new BmpBitmapEncoder();
                encoder.Frames.Add(BitmapFrame.Create(bitmapSource));
                encoder.Save(memoryStream);
                return new Bitmap(memoryStream);
            }
        }

        public static BitmapSource SourceFromBitmap(Bitmap bitmap)
        {
            System.Drawing.Imaging.BitmapData bitmapData = bitmap.LockBits(
                new Rectangle(0, 0, bitmap.Width, bitmap.Height),
                System.Drawing.Imaging.ImageLockMode.ReadOnly, bitmap.PixelFormat);

            BitmapSource bitmapSource = BitmapSource.Create(
                bitmapData.Width, bitmapData.Height,
                bitmap.HorizontalResolution, bitmap.VerticalResolution,
                System.Windows.Media.PixelFormats.Bgra32, null,
                bitmapData.Scan0, bitmapData.Stride * bitmapData.Height, bitmapData.Stride);

            bitmap.UnlockBits(bitmapData);
            return bitmapSource;
        }

        public static Bitmap BitmapToBgra32(Bitmap bitmap)
        {
            if (bitmap.PixelFormat == System.Drawing.Imaging.PixelFormat.Format32bppArgb)
            {
                return bitmap;
            }
            else
            {
                Bitmap reformattedBitmap = new Bitmap(bitmap.Width, bitmap.Height,
                    System.Drawing.Imaging.PixelFormat.Format32bppArgb);

                using (System.Drawing.Graphics graphics = System.Drawing.Graphics.FromImage(reformattedBitmap))
                {
                    graphics.DrawImage(bitmap, new Rectangle(0, 0, reformattedBitmap.Width, reformattedBitmap.Height));
                }

                return reformattedBitmap;
            }
        }

        public static Bitmap BitmapToArgb32(Bitmap bitmap)
        {
            if (bitmap.PixelFormat == System.Drawing.Imaging.PixelFormat.Format32bppArgb)
            {
                return bitmap;
            }
            else
            {
                Bitmap reformattedBitmap = new Bitmap(bitmap.Width, bitmap.Height,
                    System.Drawing.Imaging.PixelFormat.Format32bppArgb);

                using (System.Drawing.Graphics graphics = System.Drawing.Graphics.FromImage(reformattedBitmap))
                {
                    graphics.DrawImage(bitmap, new Rectangle(0, 0, reformattedBitmap.Width, reformattedBitmap.Height));
                }

                return reformattedBitmap;
            }
        }
    }
}
