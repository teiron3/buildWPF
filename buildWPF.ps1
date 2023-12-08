# init
if ($args[0] -eq "-init") {
    if ($args.Count -lt 2) {
        echo "init �̏ꍇ�A�A�v�������K�v�ł�"
        return
    }
    $args[1] > .\namespase

    if (!(Test-Path cs)) {
        md cs
    }
    if (!(Test-Path xaml)) {
        md xaml
    }
    if (!(Test-Path csproj)) {
        md csproj
    }
    if (!(Test-Path property)) {
        md property
    }
    return
}

# build
if ($args.count -eq 1 -and ($args[0] -eq "-build" -or $args[0] -eq "-release")) {
    if (!(Test-Path cs) -and !(Test-Path xaml) -and !(Test-Path csproj) -and !(Test-Path property) -and !(Test-Path namespase)) {
        echo "�\���t�@�C���ƃf�B���N�g��������܂���"
        echo " -init 'namespace' �ŏ��������Ă�������"
        return
    }
    rm .\*.cs
    rm .\*.xaml
    rm .\*.csproj
    cp .\cs\*.cs .
    cp .\xaml\*.xaml .
    $namespace = [string](Get-Content .\namespase)
    $initcsstring
    Get-ChildItem .\xaml\*.xaml | % {
        if ($_.name -eq "MainWindow.xaml") {
            $initcsstring += @"
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
        }
    }
"@
            continue
        }
        if ( $_.name -match "xaml$") {
            $class = ""
            type $_ | % {
                if ($class -eq "" -and $_ -match "^ *<[a-zA-Z_]") {
                    $class = [Regex]::match($_, "<[a-zA-Z_]+[ >]").Replace("<", "").Replace(">", "").Replace(" ", "")
                } 
            }
            $initcsstring += @"
    public partial class {0} : {1}
    {
        public {0}()
        {
            InitializeComponent();
        }
    }
"@ -f $_name.Replace(".xaml", ""), $class
        }
    }
    @"
using System;
using System.ComponentModel;
using System.Windows;
using System.Windows.Controls;
namespace {0}
{
{1}
}
"@ -f $namespace, $initcsstring > .\initxaml.cs

    
    C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe .\*.csproj 


    # makeMainWindowFile
    if ($args.count -eq 1 -and $args[0] -eq "-makeMainWindow") {
        if (!(Test-Path namespase)) {
            echo "�\���t�@�C��������܂���"
            echo " -init 'namespace' �ŏ��������Ă�������"
            return
        }
        if (Test-Path .\xaml\MainWindow.xaml) {
            echo "MainWindow.xaml �͊��ɑ��݂��܂�"
            echo "�V�����쐬����ꍇ�́A�����̃t�@�C�����폜���Ă�������"
            return
        }
        $namespace = [string](Get-Content .\namespase)
        $xaml = [string] @"
<Window x:Class=""{0}.MainWindow""
    xmlns=""http://schemas.microsoft.com/winfx/2006/xaml/presentation""
    xmlns:x=""http://schemas.microsoft.com/winfx/2006/xaml""
    xmlns:d=""http://schemas.microsoft.com/expression/blend/2008""
    xmlns:mc=""http://schemas.openxmlformats.org/markup-compatibility/2006""
    mc:Ignorable=""d""
    xmlns:local=""clr-namespace:{0}""
    Width=""200""
    Height=""200"">
</Window>
"@ -f $namespace
        $xaml > .\xaml\MainWindow.xaml
        return
    }

    # makeControlFile
    if ($args[0] -eq "-makeControl") {
        if (!(Test-Path namespase)) {
            echo "�\���t�@�C��������܂���"
            echo " -init 'namespace' �ŏ��������Ă�������"
            return
        }
        if ($args.Count -lt 3) {
            echo "Control �̃N���X���ƌp�����̃N���X���w�肵�Ă�������"
            echo " -makeUserControl 'ClassName' 'InheritanceClassName'"
            return
        }
        if (Test-Path $args[1] + ".xaml") {
            echo $args[1] + ".xaml �͊��ɑ��݂��܂�"
            echo "�V�����쐬����ꍇ�́A�����̃t�@�C�����폜���Ă�������"
            return
        }
    
        $namespace = [string](Get-Content .\namespase)
        $xaml = [string] @"
<{2} x:Class=""{0}.{1}""
    xmlns=""http://schemas.microsoft.com/winfx/2006/xaml/presentation""
    xmlns:x=""http://schemas.microsoft.com/winfx/2006/xaml""
    xmlns:mc=""http://schemas.openxmlformats.org/markup-compatibility/2006""
    xmlns:local=""clr-namespace:{0}"">
</{2}> 
"@ -f $namespace, $args[1], $args[2]
        $f = ".\xaml\{0}.xaml" -f $args[1]
        $xaml > $f
    }