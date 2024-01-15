function Invoke-buildWPF {
    param(
        [switch]$help,
        [switch]$init,
        [switch]$makeMainWindow,
        [switch]$makeControl,
        [switch]$addReference,
        [switch]$build,
        [switch]$release,

        [string]$namespace = '',
        [string]$InheritanceClassName = '',
        [string]$ClassName = '',
        [string]$makeMethod = '',
        [string]$dll = '',
        [string]$using = ''
    )
    
    if ( -not($help -or $init -or $makeMainWindow -or $makeControl -or $addReference -or $build -or $release)) {
        $help = $true
    }
    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
    #region scriptblocks
    # xaml ���쐬���邽�߂̃X�N���v�g�u���b�N
    $script:namespace = $namespace
    $script:InheritanceClassName = $InheritanceClassName
    $script:ClassName = $ClassName

    $xaml = {
        [string] @"
<{1}
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    mc:Ignorable="d"
    xmlns:local="clr-namespace:{0}"
    x:Class="{0}.{2}"
    Width="200"
    Height="200">
<!-- add initcode
{3}
-->
<!-- add classcode
-->
</{1}>
"@ -f $script:namespace, $script:InheritanceClassName, $script:ClassName, $script:initcode > .\xaml\$script:ClassName.xaml
    }
    #endregion

    #region help
    if ($help) {
        echo "	-init 'namespace' �ŏ�����"
        echo "	-makeMainWindow �� MainWindow.xaml ���쐬"
        echo "	-makeControl 'ClassName' 'InheritanceClassName' �� Control.xaml ���쐬"
        echo "	-makeMethod 'MethodName' �� MethodClass.cs ���쐬"
        echo "`t-addReference 'dllFilePath' 'using' �ŎQ�Ƃ�ǉ�"
        echo "	-build �Ńf�o�b�O�r���h"
        echo "	-release �Ń����[�X�r���h"
        echo ""
        echo "  �v���p�e�B�ptsv��[�^��]_[�I�u�W�F�N�g��]_[�����l]_[�ύX�l(visibility�̂�)]�ō쐬"
        echo "  �v���p�e�B����Visibility���܂ޏꍇ�AVisibilityChange�Ƃ����R�}���h���쐬�����"
        echo "  ���O��Visibility���܂ރv���p�e�B�����l�́AVisibility.Visible �� Visibility.Collapsed �� Visibility.Hidden �̂�"

        return
    }
    #endregion

    #region init
    if ($init) {
        if ($namespace.Length -eq 0) {
            echo "init �̏ꍇ�A�A�v�������K�v�ł�"
            return
        }
        $namespace > .\namespase
        'cs', 'xaml', 'csproj', 'property' | % {
            if (-not (Test-Path $_)) {
                md $_
            }
        }
        return
    }
    #endregion

    #region makeMainWindowFile
    if ($makeMainWindow) {
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
        $script:namespace = [string](Get-Content .\namespase)
        $script:initcode = "this.DataContext  = new ViewModel();`nInitializeComponent();"
        $script:InheritanceClassName = 'Window'
        $script:ClassName = 'MainWindow'
        & $xaml
        return
    }
    #endregion

    #region makeControlFile
    if ($makeControl) {
        if (!(Test-Path namespase)) {
            echo "�\���t�@�C��������܂���"
            echo " -init 'namespace' �ŏ��������Ă�������"
            return
        }
        else {
            $script:namespace = [string](Get-Content .\namespase)
        }
        if ($script:InheritanceClassName.Length -eq 0 -or $script:ClassName.Length -eq 0) {
            echo "-Control �̃N���X���ƌp�����̃N���X���w�肵�Ă�������"
            echo " -makeControl -ClassName 'ClassName' -InheritanceClassName 'InheritanceClassName'"
            return
        }
        if (Test-Path ("./xaml/$script:ClassName.xaml")) {
            echo "$script:ClassName.xaml �͊��ɑ��݂��܂�"
            echo "�V�����쐬����ꍇ�́A�����̃t�@�C�����폜���Ă�������"
            return
        }
        
        $script:initcode = 'InitializeComponent();'
        & $xaml
    }
    #endregion

    #region makeMethodFile
    if ($makeMethod.Length -gt 0) {
        if (!(Test-Path namespase)) {
            echo "�\���t�@�C��������܂���"
            echo " -init 'namespace' �ŏ��������Ă�������"
            return
        }
        else {
            $namespace = [string](Get-Content .\namespase)
        }
        [string] @"
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
"@ -f $namespace, $makeMethod > ".\cs\method$makeMethod.cs" 
    }
    #endregion

    #region addReference
    if ($addReference) {
        if ($dll.Length -eq 0 -or $using.Length -eq 0) {
            echo "-addReference -dll 'dllFilePath' -using 'using' �ŎQ�Ƃ�ǉ�"
            return
        }
        @"
    <ItemGroup>
        <Reference Include="$using">
            <HintPath>$dll</HintPath>
        </Reference>
    </ItemGroup>
"@ >> ".\csproj\$using.csproj"
    }
    #endregion

    #region build
    if ($build -or $release) {
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
        if ($release) {
            $outputpath = "release"
        }
        else {
            $outputpath = "debug"
        }
        $namespace = [string](Get-Content .\namespase)
    
        ## make initxaml.cs
        $initcsstring = ""
        Get-ChildItem .\xaml\*.xaml | % {
            $raw = Get-Content $_ -Raw
            $a = $raw | ? { $_ -match "^ *<[a-zA-Z]" } | % { ([regex]::match($_.replace("<", "").Trim(), "^[^\s/>]+")).Value }
            $b = if ($a.GetType() = 'String') { $a } else { $a[0] } 
            echo test
            echo $raw
            $c = ([regex]::match($raw, "<!-- add initcode.*?-->", "singleline,ignorecase").Value).replace("<!-- add initcode", "").replace("-->", "").Trim()
            $d = ([regex]::match($raw, "<!-- add classcode.*?-->", "singleline,ignorecase").Value).replace("<!-- add classcode", "").replace("-->", "").Trim()
     
            $initcsstring += @"
    public partial class {0} : {1}
    {{
        public {0}()
        {{ //
            {2}
        }}
        {3}
    }}
"@ -f $_.name.Replace(".xaml", ""), $b, $c, $d
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
        $body = "{`npublic partial class ViewModel{`n"
        Get-ChildItem .\property\*.tsv | Get-content | % {
            $a = $_.split("`t")
            if ($a[0] -match 'ObservableCollection') {
                $body += "private {0} _{1} = new {0}();`n" -f $a[0], $a[1]
                $body += "public {0} {1} {{ get _{1}; }};`n" -f $a[0], $a[1]
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
        $body = "{`npublic partial class ViewModel{`n"
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
}