$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
# help
if ($args[0] -eq "-help") {
    echo "	-init 'namespace' で初期化"
    echo "	-makeMainWindow で MainWindow.xaml を作成"
    echo "	-makeControl 'ClassName' 'InheritanceClassName' で Control.xaml を作成"
    echo "	-makeMethod 'MethodName' で MethodClass.cs を作成"
    echo "	-build でビルド"
    echo "	-release でリリースビルド"
    return
}

# init
if ($args[0] -eq "-init") {
    if ($args.Count -lt 2) {
        echo "init の場合、アプリ名が必要です"
        return
    }
    $args[1] > .\namespase
    'cs', 'xaml', 'csproj', 'property' | % {
        if (!(Test-Path $_)) {
            md $_
        }
    }
}

# makeMainWindowFile
if ($args[0] -eq "-makeMainWindow") {
    if (!(Test-Path namespase)) {
        echo "構成ファイルがありません"
        echo " -init 'namespace' で初期化してください"
        return
    }
    if (Test-Path .\xaml\MainWindow.xaml) {
        echo "MainWindow.xaml は既に存在します"
        echo "新しく作成する場合は、既存のファイルを削除してください"
        return
    }
    $namespace = [string](Get-Content .\namespase)
    $xaml = [string] @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    mc:Ignorable="d"
    xmlns:local="clr-namespace:{0}"
    x:Class="{0}.MainWindow"
    Width="200"
    Height="200">
</Window>
"@ -f $namespace
    $xaml > .\xaml\MainWindow.xaml
    return
}

# makeControlFile
if ($args[0] -eq "-makeControl") {
    if (!(Test-Path namespase)) {
        echo "構成ファイルがありません"
        echo " -init 'namespace' で初期化してください"
        return
    }
    if ($args.Count -lt 3) {
        echo "Control のクラス名と継承元のクラスを指定してください"
        echo " -makeControl 'ClassName' 'InheritanceClassName'"
        return
    }
    if (Test-Path ($args[1] + ".xaml")) {
        echo $args[2] + ".xaml は既に存在します"
        echo "新しく作成する場合は、既存のファイルを削除してください"
        return
    }

    $namespace = [string](Get-Content .\namespase)
    $xaml = [string] @"
<{1} x:Class="{0}.{2}"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:local="clr-namespace:{0}">
</{1}> 
"@ -f $namespace, $args[1], $args[2]
    $f = ".\xaml\{0}.xaml" -f $args[2]
    $xaml > $f
}

# makeMethodFile
if ($args[0] -eq "-makeMethod") {
    if (!(Test-Path namespase)) {
        echo "構成ファイルがありません"
        echo " -init 'namespace' で初期化してください"
        return
    }
    if ($args.Count -lt 2) {
        echo "メソッド名を指定してください"
        echo " -makeMethod 'MethodName'"
        return
    }
    $namespace = [string](Get-Content .\namespase)
    $cs = [string] @"
using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Threading;
using System.Windows.Input;
using System.ComponentModel;
using System.Collections.ObjectModel;
using System.Linq;
namespace {0}
{{
    public partial class MethodClass
    {{
        public static void {1}(ViewModel vm, object parameter)
        {{
        }}
    }}
}}
"@ -f $namespace, $args[1]
    $f = ".\cs\method{0}.cs" -f $args[1]
    $cs > $f
}

# build
if ($args[0] -eq "-build" -or $args[0] -eq "-release") {
    if (!(Test-Path cs) -and !(Test-Path xaml) -and !(Test-Path csproj) -and !(Test-Path property) -and !(Test-Path namespase)) {
        echo "構成ファイルとディレクトリがありません"
        echo " -init 'namespace' で初期化してください"
        return
    }
    rm .\*.cs
    rm .\*.xaml
    rm .\*.csproj
    cp .\cs\*.cs .
    cp .\xaml\*.xaml .
    $outputpath = $args[0].replace("-", "")
    $namespace = [string](Get-Content .\namespase)
    
    ## make initxaml.cs
    $initcsstring = ""
    $filename = ''
    Get-ChildItem .\xaml\*.xaml | % {
        $filename = $_.Name
        $a = Get-Content $_ | ? { $_ -match "^ *<[a-zA-Z]" }
        $b = ""
        $c = ""
        if ($a.GetType() = 'String') {
            $b = ([regex]::match($a.replace("<", "").Trim(), "^[^\s/>]+")).Value
        }
        else {
            $b = ([regex]::match($a[0].replace("<", "").Trim(), "^[^\s/>]+")).Value
        } 
        if ($b -eq "Window") {
            $c = "this.DataContext  = new ViewModel();"
        }
     
        $initcsstring += @"
    public partial class {0} : {1}
    {{
        public {0}()
        {{
            InitializeComponent();
            {2}
        }}
    }}
"@ -f $_.name.Replace(".xaml", ""), $b, $c
    }

    @"
using System;
using System.ComponentModel;
using System.Windows;
using System.Windows.Controls;
namespace {0}
{{
{1}
}}
"@ -f $namespace, $initcsstring > .\initxaml.cs

    ##make viemodel_base.cs
    $head = @"
using System;
using System.Windows;
using System.Windows.Threading;
using System.Windows.Input;
using System.ComponentModel;
using System.Windows.Controls;
using System.Collections.ObjectModel;
using System.Linq;
namespace {0}
"@ -f $namespace
    $body = @"
{
    public partial class ViewModel : INotifyPropertyChanged
    {
        Action action = () => {};
        public event PropertyChangedEventHandler PropertyChanged;
        private void NotifyPropertyChanged(string info)
        {
            if (PropertyChanged != null)
            {
                PropertyChanged(this, new PropertyChangedEventArgs(info));
                Application.Current.Dispatcher.Invoke(
                        action,
                        DispatcherPriority.Background, new object[] { }
                );
            }
        }
    }
    public class MakeCommandClass : ICommand
    {
        ViewModel vm;
        Action<ViewModel, object> execmd;
        public MakeCommandClass(ViewModel arg, Action<ViewModel, object> argdelegate)
        {
            vm = arg;
            execmd = argdelegate;
        }
        public event EventHandler CanExecuteChanged;
        public bool CanExecute(object parameter) { return true; }
        public void Execute(object parameter) { execmd(vm, parameter); }
    }
}
"@
    $head + $body > .\viemodel_base.cs
    
    ## make viewmodel_property.cs
    $body = "{public partial class ViewModel{`n"
    Get-ChildItem .\property\*.tsv | Get-content | % {
        $a = $_.split("`t")
        if ($a[0] -match 'ObservableCollection') {
            $body += "public {0} {1} {{ get; set; }} = new {0}();`n" -f $a[0], $a[1]
        }
        else {
            $body += "private {0} _{1} = {2};`n" -f $a[0], $a[1], $a[2]
            $body += @"
            public {0} {1} {{
                get {{ return _{1}; }}
                set {{
                    if(_{1} == value){{
                        return;
                    }}else{{
                        _{1} = value;
                        NotifyPropertyChanged("{1}");
                    }}
                }}
            }}`n
"@ -f $a[0], $a[1]
        }
    }
    $body += "}}"
    $head + $body > .\viemodel_property.cs
    
    ## make viewmodel_command.cs
    $body = "{public partial class ViewModel{`n"
    $a = Get-ChildItem .\cs\method*.cs | Get-content | ? { $_ -match "public static void" } | % {
        [regex]::match($_.replace("public static void", "").Trim() , "^[^\s(]+").Value
    }
    $a | % {
        $body += @"
        private ICommand _$a; public ICommand $a{
            get{
                if(_$a == null){
                    _$a = new MakeCommandClass(this, new Action<ViewModel, object>(MethodClass.$a));
                }
                return _$a;
            }
        }
"@
    }
    Get-ChildItem .\property\*.tsv | Get-content | ? { $_.split("`t")[1] -match "Visibility" } | % {
        $pro = $_.split("`t")[1]
        $c = $_.split("`t")[1] + "Change"
        $p1 = $_.split("`t")[2]
        $p2 = $_.split("`t")[3]
        $body += @"
        private ICommand _$c; public ICommand $c{
            get{
                if(_$c == null){
                    _$c = new MakeCommandClass(
                        this, new Action<ViewModel, object>((vm, obj) => vm.$pro = (vm.$pro == $p1) ? $p2 : $p1
                    ));
                }
                return _$c;
            }
        }
"@
    }
    $body += "}}"
    $head + $body > .\viemodel_command.cs
        
    ## make csproj
    $body = @"
<Project DefaultTargets="Build"
     xmlns="http://schemas.microsoft.com/developer/msbuild/2003"
     ToolsVersion="4.0">
    <PropertyGroup>
        <Configuration>Debug</Configuration>
        <TargetFrameworkVersion>v4.8</TargetFrameworkVersion>
        <Platform>AnyCPU</Platform>
        <RootNamespace>$namespace</RootNamespace>
        <AssemblyName>$namespace</AssemblyName>
        <OutputType>WinExe</OutputType>
        <OutputPath>.\$outputpath</OutputPath>
    </PropertyGroup>
    <ItemGroup>
        <Reference Include="System" />
        <Reference Include="System.Xaml" />
        <Reference Include="WindowsBase" />
        <Reference Include="PresentationCore" />
        <Reference Include="PresentationFramework" />
    </ItemGroup>

    <!-- xaml -->
    <ItemGroup>
        <ApplicationDefinition Include="Application.xaml" />`n
"@
    Get-ChildItem .\xaml\*.xaml | % {
        $body += "        <Page Include=`"{0}`" />`n" -f $_.Name
    }
    $body += @"
    </ItemGroup>
    <!-- cs -->
    <ItemGroup>
"@
    Get-ChildItem *.cs | % {
        $body += "        <Compile Include=`"{0}`" />`n" -f $_.Name
    } 
    $body += "  </ItemGroup>`n"
    Get-ChildItem .\csproj\*.csproj | get-content | % { $body += $_ }
    $body += @"
    <Import Project="`$(MSBuildBinPath)\Microsoft.CSharp.targets" />
</Project>
"@
    $body > "$namespace.csproj"
    
    ## make Application.xaml
    @"
<Application
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    StartupUri="MainWindow.xaml"
    />
"@ > .\Application.xaml

    
    C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe "$namespace.csproj"
}



