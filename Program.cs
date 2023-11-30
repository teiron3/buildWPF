//コンソールとファイル操作の名前空間を指定
using System;
using System.IO;
using System.Reflection;

//正規表現の名前空間を指定
using System.Text.RegularExpressions;
//StringBuilderクラスを使用するための名前空間を指定
using System.Text;

//名前空間を指定
namespace buildWPF
{
    partial class Program
    {
        //メインメソッド
        static void Main(string[] args)
        {
            //"-h"オプションが指定された場合
            if (args.Length == 1 && args[0] == "-h")
            {
                //ヘルプを表示
                Console.WriteLine("buildWPF.exe [options]");
                Console.WriteLine("options:");
                Console.WriteLine("  -h: ヘルプを表示");
                Console.WriteLine("  -v: バージョンを表示");
                Console.WriteLine("  -c: csprojファイルを作成");
                Console.WriteLine("  -x: xamlファイルをコピー");
                Console.WriteLine("  -a: csprojファイルを作成し、xamlファイルをコピー");
                return;
            }

            //.csprojファイルの有無を確認
            //カレントディレクトリの.csprojファイルを取得
            string[] files = Directory.GetFiles(Directory.GetCurrentDirectory(), "*.csproj");
            //.csprojファイルが存在しない場合
            if (files.Length == 0)
            {
                //csprojファイルを作成するメソッドを呼び出す
                createCsproj(Directory.GetCurrentDirectory());
            }
            //カレントディレクトリのxamlファイルとcsファイルを削除
            foreach (string file in Directory.GetFiles(Directory.GetCurrentDirectory(), "*.xaml"))
            {
                File.Delete(file);
            }
            foreach (string file in Directory.GetFiles(Directory.GetCurrentDirectory(), "*.cs"))
            {
                File.Delete(file);
            }

            //"xaml"フォルダが存在しない場合は終了する
            if (!Directory.Exists("xaml"))
            {
                Console.WriteLine("xamlフォルダが存在しません。");
                return;
            }
            //"cs"フォルダが存在しない場合は終了する
            if (!Directory.Exists("cs"))
            {
                Console.WriteLine("csフォルダが存在しません。");
                return;
            }
            //"xaml"フォルダ内にapp.xamlファイルとMainWindow.xamlが存在すれば、２つのファイルをコピーする
            //2つのファイルうちどちらかが存在しない場合は終了する
            if (File.Exists("xaml\\app.xaml") && File.Exists("xaml\\MainWindow.xaml"))
            {
                //app.xamlファイルをコピー
                File.Copy("xaml\\app.xaml", "app.xaml", true);
                //MainWindow.xamlファイルをコピー
                File.Copy("xaml\\MainWindow.xaml", "MainWindow.xaml", true);
            }
            else
            {
                Console.WriteLine("xamlフォルダ内にapp.xamlファイルまたはMainWindow.xamlファイルが存在しません。");
                return;
            }

            //"xaml"フォルダ内のファイルのうち、app.xamlとMainWindow.xaml以外のファイルをコピーする
            //List<string> FileListを作成し、app.xamlとMainWindow.xaml以外のファイルの拡張子を除いたファイル名を追加する
            List<string> FileList = new List<string>();
            foreach (string file in Directory.GetFiles("xaml"))
            {
                //app.xamlとMainWindow.xaml以外のファイルの拡張子を除いたファイル名を追加する
                if (Path.GetFileName(file) != "app.xaml" && Path.GetFileName(file) != "MainWindow.xaml")
                {
                    FileList.Add(Path.GetFileNameWithoutExtension(file));
                    //ファイルをコピー
                    File.Copy(file, Path.GetFileName(file), true);
                }
            }

            //xaml.csファイルを作成する
            StreamWriter sw = File.CreateText("xaml.cs");
            //xaml.csファイルに書き込む
            sw.WriteLine("using System.Windows;");
            sw.WriteLine("namespace ns");
            sw.WriteLine("{");
            sw.WriteLine("    public partial class MainWindow : Window");
            sw.WriteLine("    {");
            //"xaml"フォルダ内にViewModel.csファイルが存在すれば、ViewModelクラスの変数vmを宣言する
            sw.WriteLine("    ViewModel vm;");
            sw.WriteLine("        public MainWindow()");
            sw.WriteLine("        {");
            sw.WriteLine("            InitializeComponent();");
            //"xaml"フォルダ内にViewModel.csファイルが存在すれば、ViewModelクラスのインスタンスを作成する
            sw.WriteLine("            if (File.Exists(\"xaml\\ViewModel.cs\"))");
            sw.WriteLine("            vm = new ViewModel();");
            sw.WriteLine("        }");
            sw.WriteLine("    }");
            //FileListの要素からファイル名を取得し、xaml.csファイルに書き込む
            //継承クラスはUserControlにする
            foreach (string file in FileList)
            {
                sw.WriteLine("    public partial class " + file + " : UserControl");
                sw.WriteLine("    {");
                sw.WriteLine("        public " + file + "()");
                sw.WriteLine("        {");
                sw.WriteLine("            InitializeComponent();");
                sw.WriteLine("        }");
                sw.WriteLine("    }");
            }
            sw.WriteLine("}");
            //ファイルを閉じる
            sw.Close();

            //一時的にコード内容を保存するstringbuilder codestringbuilderを宣言する
            var codestringbuilder = new StringBuilder();
            codestringbuilder.AppendLine("using System.Windows.Input;");
            codestringbuilder.AppendLine("namespace ns");
            codestringbuilder.AppendLine("    public partial class ViewModel/n    {/n");

            //"cs"フォルダ内のcsファイルをコピーする
            foreach (string file in Directory.GetFiles("cs"))
            {
                //ファイルをコピー
                File.Copy(file, Path.GetFileName(file), true);
                //ファイル名の頭に"Methods"が付いていれば、一行ずつ読み込んで該当する文字列があれば処理を行う
                if (Path.GetFileName(file).StartsWith("Methods"))
                {
                    foreach (string line in File.ReadLines(Path.GetFileName(file)))
                    {
                        //空白を除いた行の頭にpublicがあった場合
                        if (line.Trim().StartsWith("public"))
                        {
                            //先頭から最初の"("までの文字列を取得する
                            string method = line.Substring(0, line.IndexOf("(") - 1).Trim();
                            //文字列の後ろから最初の" "までの文字列を取得する
                            string methodname = method.Substring(method.LastIndexOf(" ") + 1);

                            //methodnameからICommandを作成する文字列を作成し、codestringbuilderに追加する
                            codestringbuilder.AppendLine(string.Format("private ICommand _{0});", methodname));
                            codestringbuilder.AppendLine(string.Format("public ICommand {0}", methodname));
                            codestringbuilder.AppendLine(string.Format("{"));
                            codestringbuilder.AppendLine(string.Format("    get"));
                            codestringbuilder.AppendLine(string.Format("    {"));
                            codestringbuilder.AppendLine(string.Format("        if (_{0} == null)", methodname));
                            codestringbuilder.AppendLine(string.Format("        {"));
                            codestringbuilder.AppendLine(string.Format("            _{0} = new MakeICommandClass(MethodsClass.{0})", methodname));
                            codestringbuilder.AppendLine(string.Format("        }"));
                            codestringbuilder.AppendLine(string.Format("        return _{0});", methodname));
                            codestringbuilder.AppendLine(string.Format("    }"));
                            codestringbuilder.AppendLine(string.Format("}"));
                        }
                    }
                }
            }
            codestringbuilder.AppendLine("    }\n}");
            //command.csファイルを作成する
            StreamWriter sw2 = File.CreateText("command.cs");
            //command.csファイルに書き込む
            //partial ViewModelクラス内にコードを追加する
            sw2.WriteLine(codestringbuilder.ToString());
            //ファイルを閉じる
            sw2.Close();


            //"attribute"フォルダが存在する場合は処理を行う

            if (Directory.Exists("attribute"))
            {
                //処理の内容はattributeフォルダ内のファイルからattribute.csファイルを作成する

                //codestringbuilderを初期化する
                codestringbuilder = new StringBuilder();
                codestringbuilder.AppendLine("using System.Windows.Input;");
                codestringbuilder.AppendLine("namespace ns");
                codestringbuilder.AppendLine("    public partial class ViewModel/n    {/n");
                //一時的にコード内容を保存するstringbuilder codestringbuilderを宣言する
                //attributeフォルダ内のファイルを読み込み、attribute.csファイルに書き込む
                foreach (string file in Directory.GetFiles("attribute"))
                {
                    //ファイルを読み込む
                    foreach (string line in File.ReadLines(file))
                    {
                        //最初の=の前の文字列を取得する
                        string attribute = line.Substring(0, line.IndexOf("=") - 1).Trim();
                        //取得した文字列の後ろから最初の" "までの文字列を取得する
                        string attributename = attribute.Substring(attribute.LastIndexOf(" ") + 1);
                        //lineの文字列をattributenameの先頭に"_"を付ける
                        codestringbuilder.AppendLine(string.Format("private {0};", line.Replace(attributename, "_" + attributename)));
                        codestringbuilder.AppendLine(string.Format("public {0}{", attribute));
                        codestringbuilder.AppendLine(string.Format("    get{return _{0};}", attributename));
                        codestringbuilder.AppendLine(string.Format("    set"));
                        codestringbuilder.AppendLine(string.Format("    {"));
                        codestringbuilder.AppendLine(string.Format("        if (_{0} != value)", attributename));
                        codestringbuilder.AppendLine(string.Format("        {"));
                        codestringbuilder.AppendLine(string.Format("            _{0} = value;", attributename));
                        codestringbuilder.AppendLine(string.Format("            OnPropertyChanged(nameof({0})));", attributename));
                        codestringbuilder.AppendLine(string.Format("        }"));
                        codestringbuilder.AppendLine(string.Format("    }"));
                        codestringbuilder.AppendLine(string.Format("}"));
                    }
                }
                codestringbuilder.AppendLine("    }\n}");
                //attribute.csファイルを作成する
                StreamWriter sw3 = File.CreateText("attribute.cs");
                sw3.WriteLine(codestringbuilder.ToString());
                //ファイルを閉じる
                sw3.Close();
            }
        }

        //csprojファイルを作成するメソッド
        static void createCsproj(string path)
        {
            //csprojファイルを作成
            StreamWriter sw = File.CreateText("template.csproj");
            //csprojファイルに書き込む
            sw.WriteLine("<Project Sdk=\"Microsoft.NET.Sdk\">");
            sw.WriteLine("< PropertyGroup >");
            sw.WriteLine("< OutputType > WinExe </ OutputType >");
            sw.WriteLine("< TargetFramework > net48 - windows </ TargetFramework >");
            sw.WriteLine("< UseWPF > true </ UseWPF > ");
            sw.WriteLine("</ PropertyGroup >");
            sw.WriteLine("</Project>");
            //ファイルを閉じる
            sw.Close();
        }
    }
}