   M S B A M L   `   `   `  ���� G  CFiltr Gaussa, Version=1.0.0.0, Culture=neutral, PublicKeyToken=nullO,clr-namespace:Pl.Bbit.GaussianFilterApp.ViewPl.Bbit.GaussianFilterApp.View  Q-clr-namespace:Pl.Bbit.GaussianFilterApp.ModelPl.Bbit.GaussianFilterApp.Model  [2clr-namespace:Pl.Bbit.GaussianFilterApp.Converters$Pl.Bbit.GaussianFilterApp.Converters  O Kmscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e0891&clr-namespace:System;assembly=mscorlibSystem +    %Pl.Bbit.GaussianFilterApp.ImageWindow   R NWindowsBase, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35\ XPresentationFramework, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35W SPresentationCore, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35D 9http://schemas.microsoft.com/winfx/2006/xaml/presentation    R NSystem.Xaml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089:x,http://schemas.microsoft.com/winfx/2006/xaml     @d2http://schemas.microsoft.com/expression/blend/2008     Jmc;http://schemas.openxmlformats.org/markup-compatibility/2006     c _System.Windows.Interactivity, Version=4.5.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35Bi:http://schemas.microsoft.com/expression/2010/interactivity  b ^GalaSoft.MvvmLight.Platform, Version=5.4.1.0, Culture=neutral, PublicKeyToken=5f873c45e98af8a1*cmd http://www.galasoft.ch/mvvmlight  7view,clr-namespace:Pl.Bbit.GaussianFilterApp.View  9model-clr-namespace:Pl.Bbit.GaussianFilterApp.Model  C
converters2clr-namespace:Pl.Bbit.GaussianFilterApp.Converters  3system&clr-namespace:System;assembly=mscorlib    � WindowStartupLocation$  CenterScreen=�$	��400��$	��550��$	��550��$	��650��
���i�� � Title ��  �� Path$ Title� � 	Resources  �� 
TargetType �� Property �� Value   AssemblyFilterTiming  HLFilterTiming:  4Pl.Bbit.GaussianFilterApp.Converters.TimingConverter  TimingConverter?  9Pl.Bbit.GaussianFilterApp.Converters.NegateValueConverter  NegateValueConverterE  ?Pl.Bbit.GaussianFilterApp.Converters.FilterChoiceValueConverter  FilterChoiceValueConverterD  >Pl.Bbit.GaussianFilterApp.Converters.SigmaSliderValueConverter  SigmaSliderValueConverterF  @Pl.Bbit.GaussianFilterApp.Converters.ThreadsSliderValueConverter  ThreadsSliderValueConverter>  8Pl.Bbit.GaussianFilterApp.Converters.SigmaValueConverter  SigmaValueConverter@  :Pl.Bbit.GaussianFilterApp.Converters.ThreadsValueConverter  ThreadsValueConverter@  :Pl.Bbit.GaussianFilterApp.Converters.SigmaToolTipConverter 	 SigmaToolTipConverterB	  <Pl.Bbit.GaussianFilterApp.Converters.ThreadsToolTipConverter 
 ThreadsToolTipConverter��%%  '��       &	  B     &	 ^     &	 �     &	 �     &	 �     &	 �     &	 �     &	 �     &	 �     &		 �     &	
 �     �� PaddingBorder��" ��.���  �@��Padding$ 6,6,6,6q���Język asemblerowy����Język wysokiego poziomu��                	  .���  � RowDefinitions �� $��* ��� $
��Auto ��� $
��Auto ��� $
��Auto ��� $
��Auto � � ColumnDefinitions �� $��* ��� $��* �.+��� 	 �� Padding$	 0,0,0,6q�._�]� 
������ 
 J� 	AllowDrop
 �� $ IsProcessing� �� 	Converter# [ .
  (System.Windows.Interactivity.Interaction 
  Triggers /  )System.Windows.Interactivity.EventTrigger     	EventName$
 Drop��.  (System.Windows.Interactivity.TriggerBase   Actions. /  )GalaSoft.MvvmLight.Command.EventToCommand     PassEventArgsToCommand .    Command �� *	ImageDrop+.+��� $��1q�$��Stretch=�$��Stretch=�$	��307����L�  j� Viewport$ 0,0,8,8� j� ViewportUnits$ Absolute=� j� TileMode$
 Tile=� L� Drawing I� .���  � Brush
 ����� � Geometry � .����  �� Rect$ 	0,0,50,50��� $ 50,50,50,50�._��� $��
0,-39,0,-7q�$	��307������ $ SourceImage��� $	 6q�$��1��._��� .+�	�  	� 	GroupName$ FilterChoice��$��Algorytm C++��
��� ���$
��Bold"�$��20�� d� 	IsChecked �� *SelectedFilter+# [ 2  ,Pl.Bbit.GaussianFilterApp.Model.FilterChoice   HighLevelFilter �� ConverterParameter# Z 	� $ FilterChoice��$��Algorytm Asembler��
��� ���$
��Bold"�$��18�� �� *SelectedFilter+# [    AssemblyFilter# Z ��  �� TextAlignment$ Center=�$��Drag me here!��$
��Bold"�$��20(�$��56,0,60,318q� J� RenderTransformOrigin$ -0.688,-0.52&��� $	 6q�$��2��._��  �� $
��Auto ��� $��* � �� $��* ��� $��* ��� $��* ��� $��* �.+��� $��0��$��0������ *Sigma+# [ 4  .Pl.Bbit.GaussianFilterApp.View.FormattedSlider  $��0��$��1�� � Minimum$ 0Q�  � Maximum$	  100Q�! �� AutoToolTipPlacement$! TopLeft=�
���/���"   AutoToolTipConverter#" [	 {��� $ IsProcessing�# [ # � Value# �� $ Sigma�$ �� Mode$$ TwoWay=�# [ �� $��1��$��0������ *	Threads+# [   $��1��$��1��$ 1Q�$  64Q�$! TopLeft=�% �� IsSnapToTickEnabled% . #" [
 {��� $ IsProcessing�# [ # �� $ Threads�$$ TwoWay=�# [ �� $	 6q�$��3��._��� $��Zastosuj filtr��$
��Bold"�
��� ���
�������$��6q�$��Bottom=����� $ ApplyFilter��� $	 6q�$��4��._��� $��Zapisz plik��$
��Bold"�$��6q�
��� ���
�������$��Bottom=����� $ 	SaveImage��� $	 6q�$��1��._��� $ -0.261,0.586&�$��4,0,0,4q����� $ FilteredImage��� $	 6q�$��1��$��4��._��� .+��� $
��Bold"�$ Center=����� $ AssemblyFilterTiming�# [ # [  �� $
��Bold"�$ Center=����� $ HLFilterTiming�# [ # [ 