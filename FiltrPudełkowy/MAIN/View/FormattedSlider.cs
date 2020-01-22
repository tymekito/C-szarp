using System.Reflection;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;

namespace Pl.Bbit.GaussianFilterApp.View
{
    /// <summary>
    /// Interfejs dla obiektów formatujących tooltipy.
    /// </summary>
    interface IToolTipConverter
    {
        string Convert(double value);
    }

    /// <summary>
    /// Slider z możliwością formatowania tooltipów.
    /// </summary>
    class FormattedSlider : Slider
    {
        private ToolTip _autoToolTip;

        public ToolTip AutoToolTip
        {
            get
            {
                if (_autoToolTip == null)
                {
                    FieldInfo field = typeof(Slider).GetField(
                        "_autoToolTip",
                        BindingFlags.NonPublic | BindingFlags.Instance);
                    _autoToolTip = field.GetValue(this) as ToolTip;
                }
                return _autoToolTip;
            }
        }

        public IToolTipConverter AutoToolTipConverter { get; set; }
        
        protected override void OnThumbDragStarted(DragStartedEventArgs e)
        {
            base.OnThumbDragStarted(e);
            FormatAutoToolTipContent();
        }

        protected override void OnThumbDragDelta(DragDeltaEventArgs e)
        {
            base.OnThumbDragDelta(e);
            FormatAutoToolTipContent();
        }

        private void FormatAutoToolTipContent()
        {
            AutoToolTip.Content = AutoToolTipConverter?.Convert(Value) ?? Value.ToString();
        }
    }
}
