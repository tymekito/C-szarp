   M S B A M L   `   `   `  ����G  CFiltr Gaussa, Version=1.0.0.0, Culture=neutral, PublicKeyToken=nullO,clr-namespace:Pl.Bbit.GaussianFilterApp.ViewPl.Bbit.GaussianFilterApp.View  5   	   Q-clr-namespace:Pl.Bbit.GaussianFilterApp.ModelPl.Bbit.GaussianFilterApp.Model  5	   	   [2clr-namespace:Pl.Bbit.GaussianFilterApp.Converters$Pl.Bbit.GaussianFilterApp.Converters  5
   	   O Kmscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e0891&clr-namespace:System;assembly=mscorlibSystem 5   	   +    %Pl.Bbit.GaussianFilterApp.ImageWindow   5   	   R NWindowsBase, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35\ XPresentationFramework, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35W SPresentationCore, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35D 9http://schemas.microsoft.com/winfx/2006/xaml/presentation    5   	   R NSystem.Xaml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089:x,http://schemas.microsoft.com/winfx/2006/xaml     5   	   @d2http://schemas.microsoft.com/expression/blend/2008     5   	   Jmc;http://schemas.openxmlformats.org/markup-compatibility/2006     5   	   c _System.Windows.Interactivity, Version=4.5.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35Bi:http://schemas.microsoft.com/expression/2010/interactivity  5   	   b ^GalaSoft.MvvmLight.Platform, Version=5.4.1.0, Culture=neutral, PublicKeyToken=5f873c45e98af8a1*cmd http://www.galasoft.ch/mvvmlight  5   	   7view,clr-namespace:Pl.Bbit.GaussianFilterApp.View  5   	   9model-clr-namespace:Pl.Bbit.GaussianFilterApp.Model  5	   	   C
converters2clr-namespace:Pl.Bbit.GaussianFilterApp.Converters  5
   	   3system&clr-namespace:System;assembly=mscorlib  5   	     � WindowStartupLocation$  CenterScreen=�5   	   $	��400��5   &   $	��550��66   $	��550��6E   $	��650��6R   
���i�� � Title 6	   ��  �� Path$ Title� � 	Resources 5       �� 
TargetType �� Property �� Value   AssemblyFilterTiming  HLFilterTiming:  4Pl.Bbit.GaussianFilterApp.Converters.TimingConverter  TimingConverter?  9Pl.Bbit.GaussianFilterApp.Converters.NegateValueConverter  NegateValueConverterE  ?Pl.Bbit.GaussianFilterApp.Converters.FilterChoiceValueConverter  FilterChoiceValueConverterD  >Pl.Bbit.GaussianFilterApp.Converters.SigmaSliderValueConverter  SigmaSliderValueConverterF  @Pl.Bbit.GaussianFilterApp.Converters.ThreadsSliderValueConverter  ThreadsSliderValueConverter>  8Pl.Bbit.GaussianFilterApp.Converters.SigmaValueConverter  SigmaValueConverter@  :Pl.Bbit.GaussianFilterApp.Converters.ThreadsValueConverter  ThreadsValueConverter@  :Pl.Bbit.GaussianFilterApp.Converters.SigmaToolTipConverter 	 SigmaToolTipConverterB	  <Pl.Bbit.GaussianFilterApp.Converters.ThreadsToolTipConverter 
 ThreadsToolTipConverter��%�  '��       &	  g     &	 �     &	 �     &	 �     &	 �     &	 �     &	     &	      &	 3    &		 F    &	
 Y    �� 5   
   PaddingBorder��" ��6'   .�5      ��  �@��Padding$ 6,6,6,6q�6(   5      ��5   
   Język asemblerowy��6H   ��5   
   Język wysokiego poziomu��6H     5   
   6%     5   
   6*     5   
   60     5   
   6/     5   
   61     5   
   6)     5   
   6+     5   
   6+   	  5   
   6-   5       .��5"      �  � RowDefinitions 5#   
   �� 5$      $��* �6   �� 5%      $
��Auto �6   �� 5&      $
��Auto �6   �� 5'      $
��Auto �6   �� 5(      $
��Auto �6    � ColumnDefinitions 5+   
   �� 5,      $��* �6   �� 5-      $��* �6   .+�50   
   �� 	 �� Padding$	 0,0,0,6q�6   ._�52      ]� 
������ 
 J� 	AllowDrop
 6   �� $ IsProcessing� �� 	Converter# [ .
  (System.Windows.Interactivity.Interaction 
  Triggers 55      /  )System.Windows.Interactivity.EventTrigger  56         	EventName$
 Drop��6%   .  (System.Windows.Interactivity.TriggerBase   Actions. 57      /  )GalaSoft.MvvmLight.Command.EventToCommand     PassEventArgsToCommand .    Command 6-   �� *	ImageDrop+58      59      .+�5<      �� $��1q�6   $��Stretch=�6-   $��Stretch=�6I   $	��307��6g   ��5>      L� 5?       j� Viewport$ 0,0,8,8�6'    j� ViewportUnits$ Absolute=�6:    j� TileMode$
 Tile=�6S    L� Drawing 5A      I� 5B   "   .��5C   &   �  � Brush
 ����� � Geometry 5D   *   � 5E   .   .��5F   2   ��  �� Rect$ 	0,0,50,50�6D   �� 5H   2   $ 50,50,50,50�6D   5I   /   5K   '   5L   #   5N      ._�5P      �� $��
0,-39,0,-7q�6@   $	��307��6T   ��6   �� $ SourceImage�6T   5Q      5R      5S      �� 5U   
   $	 6q�6   $��1��6   ._�5V      �� .+�5W      	�  	� 	GroupName$ FilterChoice��6   $��Algorytm C++��67   
��� ���$
��Bold"�5X   2   $��20��5[   a    d� 	IsChecked 5Y      �� *SelectedFilter+# [ 2  ,Pl.Bbit.GaussianFilterApp.Model.FilterChoice   HighLevelFilter �� ConverterParameter# Z 5[   a   	� 5]      $ FilterChoice��6   $��Algorytm Asembler��67   
��� ���$
��Bold"�5^   2   $��18��5a   `    5_      �� *SelectedFilter+# [    AssemblyFilter# Z 5a   `   5b      5c      �� 5d   
    �� TextAlignment$ Center=�6   $��Drag me here!��6-   $
��Bold"�6B   $��20(�6T   $��56,0,60,318q�6b    J� RenderTransformOrigin$ -0.688,-0.52&�6w   �� 5e   
   $	 6q�6   $��2��6   ._�5f      �  5g      �� 5h      $
��Auto �6'   �� 5i      $��* �6'    5k      �� 5l      $��* �6$   �� 5m      $��* �6$   �� 5n      $��* �6$   �� 5o      $��* �6$   .+�5r      �� $��0��6   $��0��6%   ��65   �� *Sigma+# [ 4  .Pl.Bbit.GaussianFilterApp.View.FormattedSlider  5s      $��0��6'   $��1��64    � Minimum$ 0Q�6D     � Maximum$	  100Q�6P   ! �� AutoToolTipPlacement$! TopLeft=�5t   '   
���/���"   AutoToolTipConverter#" [	 5u   (   {�5v   #   �� $ IsProcessing�# [ # � Value# 5w   #   �� $ Sigma�$ �� Mode$$ TwoWay=�# [ �� 5z      $��1��6   $��0��6%   ��65   �� *	Threads+# [   5{      $��1��6'   $��1��64   $ 1Q�6D   $  64Q�6P   $! TopLeft=�5|   '   % �� IsSnapToTickEnabled% . #" [
 5~   #   {�5   #   �� $ IsProcessing�# [ # 5�   #   �� $ Threads�$$ TwoWay=�# [ 5�      5�      �� 5�   
   $	 6q�6   $��3��6   ._�5�      �� $��Zastosuj filtr��6   $
��Bold"�6.   
��� ���
�������$��6q�6h   $��Bottom=�6t   ��6�   �� $ ApplyFilter�5�      �� 5�   
   $	 6q�6   $��4��6   ._�5�      �� $��Zapisz plik��6   $
��Bold"�6+   $��6q�6=   
��� ���
�������$��Bottom=�6q   ��6�   �� $ 	SaveImage�5�      �� 5�   
   $	 6q�6   $��1��6   ._�5�      �� $ -0.261,0.586&�6<   $��4,0,0,4q�6a   ��6   �� $ FilteredImage�6a   5�      �� 5�   
   $	 6q�6   $��1��6   $��4��6-   ._�5�      �� .+�5�      �� $
��Bold"�6   $ Center=�6�   ��6.   �� $ AssemblyFilterTiming�# [ # [  6�   �� 5�      $
��Bold"�6   $ Center=�6�   ��6.   �� $ HLFilterTiming�# [ # [ 6�   5�      5�      5�      5�      