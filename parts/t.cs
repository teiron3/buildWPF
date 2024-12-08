
using System;
using System.Windows;
using System.Windows.Input;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Threading;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;

namespace test
{
    public class FileDropAttachedBehavior
    {
        public static ICommand GetCommand(DependencyObject obj)
        {
            return (ICommand)obj.GetValue(CommandProperty);
        }
        public static void SetCommand(DependencyObject obj, ICommand value)
        {
            obj.SetValue(CommandProperty, value);
        }
        // Using a DependencyProperty as the backing store for Command.  This enables animation, styling, binding, etc...
        public static readonly DependencyProperty CommandProperty =
            DependencyProperty.RegisterAttached("Command", typeof(ICommand), typeof(FileDropAttachedBehavior), new PropertyMetadata(null, OnCommandChanged));

        private static void OnCommandChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            // Commandプロパティが設定されたら、ファイルドロップを受け付けるための設定を行う
            var element = d as UIElement;
            if (element == null)
                return;

            var cmd = GetCommand(element);
            if (cmd != null)
            {
                element.AllowDrop = true;
                element.PreviewDragOver += element_PreviewDragOver;
                element.Drop += element_Drop;
            }
            else
            {
                element.AllowDrop = false;
                element.PreviewDragOver -= element_PreviewDragOver;
                element.Drop -= element_Drop;
            }
        }

        static void element_PreviewDragOver(object sender, DragEventArgs e)
        {
            // ドロップ使用とするものがファイルの時のみ受け付ける。
            if (e.Data.GetData(DataFormats.FileDrop) != null)
            {
                e.Effects = DragDropEffects.Copy;
            }
            else
            {
                e.Effects = DragDropEffects.None;
            }
            e.Handled = true;
        }

        static void element_Drop(object sender, DragEventArgs e)
        {
            var element = sender as UIElement;
            if (element == null)
                return;

            // ドロップされたファイルパスを引数としてコマンド実行
            var cmd = GetCommand(element);
            var fileInfos = e.Data.GetData(DataFormats.FileDrop) as string[];
            if (fileInfos != null && cmd.CanExecute(null))
                cmd.Execute(fileInfos);
        }
    }
}