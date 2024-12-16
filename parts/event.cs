using System.Collections.ObjectModel;
using System.Windows;

namespace $namespace
{
	public partial class MainWindow : Window
	{
		private void FileListBox_Drop(object sender, DragEventArgs e)
		{
			if (e.Data.GetDataPresent(DataFormats.FileDrop))
			{
				var fileNames = (string[])e.Data.GetData(DataFormats.FileDrop);
				foreach (var name in fileNames)
				{
					//処理
				}
			}
		}

		private void FileListBox_DragOver(object sender, DragEventArgs e)
		{
			if (e.Data.GetDataPresent(DataFormats.FileDrop))
			{
				e.Effects = DragDropEffects.All;
			}
			else
			{
				e.Effects = DragDropEffects.None;
			}
			e.Handled = true;
		}
	}
}