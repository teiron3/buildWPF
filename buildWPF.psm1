<#
.SYNOPSIS
WPFビルド用のコマンド
.DESCRIPTION
    -init -namesapce 'namespace' で初期化
	-makeMainWindow でMainWindow.xamlを作成'
	-makeControl 'ParentClassName' 'ClassName' でControl.xamlを作成
	-makeMethod 'MethodName' でMethodClass.csを作成
	-addReferencd 'dllPath' 'usingName' で参照を追加
    -addWinMD でWinMDを追加
    -addBehavior でBehaviorを追加
	-build でビルド
	-release でリリースビルド
    プロパティ用tsvは[型名]-[プロパティ名]-[初期値]-[変更値(visibilityのみ)]で作成
    プロパティ名にVisibilityを含む場合、VisibilityChangeというコマンドも作成される
    名前にVisibilityを含むプロパティが取る値は、Visibility.VisibleとVisibility.CollapsedとVisibility.Hidden
#>

function Invoke-buildWPF {
    param(
        [switch]$init,
        [string]$namespace = "",

        [switch]$makeControl,
        [switch]$makeMainWindow,
        [string]$parentClass,
        [string]$inheritanceClass,

        [switch]$makeMethod,
        [string]$MethodName = "tempMethod",

        [switch]$addReferencd,
        [string]$dllPath = "",
        [string]$usingName,
        
        [switch]$addWinMD,
        [switch]$addBehavior,

        [switch]$addContent,
        [string]$LinkPath = "",

        [switch]$build,
        [switch]$release,

        [switch]$test
    )

    begin {
        $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
        if (Test-Path ".\namespace") {
            $namespace = Get-Content ./namespace 
        }
        if (Test-Path ($PSScriptRoot + '\parts\csheader.cs')) {
            $csheader = cat ($PSScriptRoot + '\parts\csheader.cs') -raw
        }
    }
    
    end {

        #region test
        ####test space####





        ####test space####
        #endregion

        #region init
        if ($init) {
            if (Test-Path ".\namespace") {
                echo "既にプロジェクト存在します。新たに作成する場合は直下の namespaceファイルを削除してください"
                return
            }

            if ($namespace.Length -le 0) {
                "-init にはアプリ名が必要です"
                "`tInvoke-buildWPF -init -namespace 'namespase'" 
                return
            }
    
            $namespace > .\namespace
            'cs', 'xaml', 'csproj', 'property', 'dll' | ? { -not (Test-Path $_) } | % { md $_ }

            return
        }
        #endregion


        
        #region makeControl
        if ($makeControl -or $makeMainWindow) {
            if ($namespace.Length -le 0) {
                "構成ファイルがありません"
                "`t-init -namesapce 'namespace'で初期化してください"
                return
            }

            $addCsCode = ""
            $addClassCode = ""
            $addTitle = ""
            if ($makeMainWindow) {
                $parentClass = "Window"
                $InheritanceClass = "MainWindow"
                $addTitle = "Title=`"$namespace`""
                $addCsCode = "this.DataContext = (vm = new ViewModel());"
                $addClassCode = "private ViewModel vm;"
            }

            if ($makeControl) {
                if ($inheritanceClass.Length -le 0 -or $parentClass.Length -le 0) {
                    "Control の継承元クラスと作成クラスをしてください"
                    "command : buildWPF -makeControl -parenctClass parentClassName -inheritacneClass makeClassName"
                    return
                }
            
                if (Test-Path ".\xaml\$inheritanceClass.xaml") {
                    "作成しようとしているxamlファイルは既に存在しています"
                    "新たに作成する場合は元ファイルを削除するかクラス名を変更してください"
                    return
                }
            }

            cat ($PSScriptRoot + '\parts\baseControl.xaml') -Encoding utf8 | & {
                begin { $xaml = "" }
                process {
                    $xaml += $_.Replace('$parentClass', $parentClass).
                    Replace('$namespace', $namespace).
                    Replace('$inheritanceClass', $inheritanceClass).
                    Replace('$addTitle', $addTitle).
                    Replace('$addClassCode', $addClassCode).
                    Replace('$addCsCode', $addCsCode) + "`n"
                }
                end { $xaml > "./xaml/$inheritanceClass.xaml" }
            }

            # add event process
            if ($makeMainWindow) {
                cat ($PSScriptRoot + '\parts\event.cs') -Encoding utf8 | & {
                    begin { $cs = '' }
                    process {
                        $cs += $_.Replace('$namespace', $namespace) + "`n"
                    }
                    end { $cs > "./cs/event.cs" }
                }
            }
    
            return
        }
        #endregion

        #region makeMethod
        if ($makeMethod) {
            if ($namespace.Length -le 0) {
                "構成ファイルがありません"
                "command : -init -namespace 'namespace' で初期化してください"
                return
            }

            if (Test-Path ".\cs\method$MethodName.cs") {
                "同じメソッドファイルが存在します"
                "新たに作成する場合は元ファイルを削除するか名前を変更してください"
                return
            }
            
            cat ($PSScriptRoot + '\parts\baseMethodCode.cs') -Encoding utf8 | & {
                begin { $cs = $csheader }
                process {
                    $cs += $_.Replace('$namespace', $namespace).Replace('$MethodName', $MethodName) + "`n"
                }
                end { $cs > ".\cs\method$MethodName.cs" }
            }
            return;
        }
        #endregion
        


        #region addReference
        if ($addReference) {
            if (!(Test-Path .\namespace)) {
                "構成ファイルがありません"
                "command : -init appname で初期化してください"
                return
            }
            if ($dllPath.Length -le 0 -or $usingName.Length -le 0) {
                "dllPathまたはusingNameがありません"
                "command: -addReference -dllPath 'dllFullPath' -usingName 'usingName'"
            }

            cat ($PSScriptRoot + '\parts\addReference.csproj') -Encoding utf8 | & {
                begin { $cs = "" }
                process {
                    $cs += $_.Replace('$usingName', $usingName).Replace('$dllPath', $dllPath) + "`n"
                }
                end { $cs >> ".\csproj\addReference.csproj" }
            }

            return
        }
        #endregion

        
        #region addWinMD
        if ($addWinMD) {
            if (!(Test-Path .\namespace)) {
                "構成ファイルがありません"
                "command : -init appname で初期化してください"
                return
            }

            cp ($PSScriptRoot + '\dll\*.winmd') ".\dll\" 
            cp ($PSScriptRoot + '\parts\addWinMD.csproj') ".\csproj\" 
            return
        }
        #endregion
        
        #region addBehavior
        if ($addBehavior) {
            if (!(Test-Path .\namespace)) {
                "構成ファイルがありません"
                "command : -init appname で初期化してください"
                return
            }

            'Microsoft.Xaml.Behaviors.dll', 'Microsoft.Xaml.Behaviors.Design.dll', 'Microsoft.Xaml.Behaviors.DesignTools.dll' | % {
                cp ($PSScriptRoot + '\dll\' + $_) ".\dll\"
            }
            cp ($PSScriptRoot + '\parts\behavior.csproj') ".\csproj\"
            return
        }
        #endregion


        #region addContent
        if ($addContent) {
            if (!(Test-Path .\namespace)) {
                "構成ファイルがありません"
                "command : -init appname で初期化してください"
                return
            }
            if ($HintPath.Length -le 0 -or $usingName.Length -le 0) {
                "dllPathまたはusingNameがありません"
                "command: -addContent -LinkPath 'LinkPath'"
            }
            cat ($PSScriptRoot + '\parts\addContent.cspro') -Encoding utf8 | & {
                begin { $cs = "" }
                process {
                    $cs += $_.Replace('$LinkPath', $LinkPath) + "`n"
                }
                end { $cs >> ".\csproj\addReference.csproj" }
            }
            return
        }
        #endregion


        #region build
        if ($build -or $release) {

            #region pre-process
            if ($namespace.Length -le 0) {
                "構成ファイルがありません"
                "`t-init -namesapce 'namespace'で初期化してください"
                return
            }

            if ("cs", "xaml", "csproj", "property" | & {
                    begin { $flg = $True }
                    process { $lg = $flg -and (Test-Path $_) }
                    end { -not $flg }
                }) {
                "構成ファイルとディレクトリがありません"
                "-init -namespace 'namespace'で初期化してください"
                return
            }

            ".\*.cs", ".\*.xaml", ".\*.csproj" | % { rm $_ }
            ".\cs\*.cs", ".\xaml\*.xaml" | % { cp $_ . }

            $outputpath = if ($build) { "build" }else { "release" }

            #endregion

            #region make initxaml.cs
            Get-ChildItem .\xaml\*.xaml | & {
                begin {
                    $initcscodestring = ""
                }

                process {
                    $Classname = $_.Name.replace(".xaml", "")
                    $xamlcode = Get-Content $_ -Raw

                    $parentClass = [regex]::match($xamlcode, "<[a-zA-Z0-9_]+[\s/>]", [System.Text.RegularExpressions.RegexOptions]::Singleline).Value.replace("<", "")

                    $addinitcscode = [regex]::match($xamlcode, "<!-- add init cscode.*?-->", [System.Text.RegularExpressions.RegexOptions]::Singleline).Value.replace("<!-- add init cscode", "").replace("-->", "")
                
                    $addclassmembercscode = [regex]::match($xamlcode, "<!-- add class cscode.*?-->", [System.Text.RegularExpressions.RegexOptions]::Singleline).Value.replace( "<!-- add class cscode", "").replace("-->", "")
                    write-host "this :$addclassmembercscode"
                    "public partial class $Classname : $parentClass{",
                    "public $Classname(){",
                    "InitializeComponent();",
                    $addinitcscode,
                    "}",
                    $addclassmembercscode,
                    "}" | % { $initcscodestring += $_ + "`n" }
                }

                end {
                    $csheader + "namespace $namespace{`n" + $initcscodestring + "`n}" > ".\initxaml.cs"
                }
            }
            #endregion

            #region make viewmodel_base.cs
            $body = @"
namespace $namespace{
    public partial class ViewModel : INotifyPropertyChanged{
        public event PropertyChangedEventHandler PropertyChanged;
		private void NotifyPropertyChanged(string info){
			if(PropertyChanged != null){
				PropertyChanged(this, new PropertyChangedEventArgs(info));
            	Application.Current.Dispatcher.Invoke(
					new Action(() => {}),DispatcherPriority.Background, new object[]{}
				);

			}
        }
    }

    class MakeCommandClass : ICommand{
		ViewModel vm;
		Func<ViewModel, object, Task> execmd;
		public MakeCommandClass(ViewModel arg_vm, Func<ViewModel, object, Task> arg_cmd){
			vm = arg_vm;
			execmd = arg_cmd;
		}
		public event EventHandler CanExecuteChanged;
		public bool CanExecute(object parameter){return true;}
		public async void Execute(object parameter){
            await AsyncExec(vm, parameter);
        }
        private async Task AsyncExec(object parameter){
            await execmd(vm, parameter);
        }
	}
}
"@ 
            $csheader + $body > ".\viewmodel_base.cs"
            #endregion

            #region make viewmodel_property.cs
            $body = " namespace $namespace`n{ public partial class ViewModel{`n "

            Get-ChildItem .\property\*.tsv | Get-Content | % {
                $row = $_.split("`t")
                if ($row[0] -match "ObservableCollection") {
                    $body += "`t`tprivate {0} _{1} = new {0}();`n" -f $row[0], $row[1]
                    $body += "`t`tpublic {0} {1}{{ get{{ return _{1};}} }}" -f $row[0], $row[1]
                }
                else {
                    $body += "`t`tprivate {0} _{1} = {2};`n" -f $row[0], $row[1], $row[2]
                    $body += @"
        public {0} {1}{{
            get{{ return _{1};}}
            set{{
                if(_{1} == value){{
                    return;
                }}else{{
                    _{1} = value;
                    NotifyPropertyChanged("{1}");
                }}
            }}
        }}`n
"@ -f $row[0], $row[1]
                }
            }

            $body += "`t}`n}"
            $csheader + $body > .\viewmodel_property.cs
            #endregion
    
            #region make viewmodel_command.cs
            $body = @"
namespace $namespace{
    public partial class ViewModel{`n
"@
            Get-ChildItem .\cs\method*.cs | Get-Content | ? { $_ -match "public static async Task" } | % {
                [regex]::match($_.replace("public static async Task", "").Trim(), "^[^\s(]+").Value
            } | % {
                $body += @"
        private ICommand _$_; public ICommand $_{
            get{
                if(_$_ == null){
                    _$_ = new MakeCommandClass(this, new Func<ViewModel, object, Task>(MethodClass.$_));
                }
                return _$_;
            }
        } 
"@
            }

            Get-ChildItem .\property\*.tsv | Get-Content | ? { $_.split("`t")[1] -match "Visibility" } | % {
                $recode = $_.split("`t")
                $propertyname = $recode[1]
                $methodname = $propertyname + "Change"
                $value1 = $recode[2]
                $value2 = $recode[3]
                $body += @"
        private ICommand _$methodname; public ICommand $methodname{
            get{
                if(_$methodname == null){
                    _$methodname = new MakeCommandClass(
                        this,
                        new Func<ViewModel, object, Task>(
                            async (vm, obj) => { vm.$propertyname = (vm.$propertyname == $value1) ? $value2 : $value1;}
                        )
                    );
                }
                return _$methodname;
            }
        }

"@
            }
            $body += "`t}`n}"
            $csheader + $body > .\viewmodel_command.cs
            #endregion

            #region make csproj
            $body = @"
<Project
	xmlns="http://schemas.microsoft.com/developer/msbuild/2003"
	DefaultTargets="Build"
	ToolsVersion="4.0"	
>
	<PropertyGroup>
		<TargetFrameworkVersion>v4.8</TargetFrameworkVersion>
		<PlatformTarget>x64</PlatformTarget>
        <RootNamespace>$namespace</RootNamespace>
		<AssemblyName>$namespace</AssemblyName>
		<OutputType>WinExe</OutputType>
		<OutputPath>.\$outputpath</OutputPath>
	</PropertyGroup>

	<ItemGroup>
		<Reference Include="System" />
		<Reference Include="System.Data" />
		<Reference Include="System.Runtime" />
		<Reference Include="System.Xml" />
		<Reference Include="System.Xaml" />
		<Reference Include="WindowsBase" />
		<Reference Include="PresentationCore" />
		<Reference Include="PresentationFramework" />
    </ItemGroup>

    <!-- XAML -->
    <ItemGroup>
        <ApplicationDefinition Include="Application.xaml" />`n
"@
            Get-ChildItem .\xaml\*.xaml | % {
                $body += "`t`t<Page Include=`"{0}`" />`n" -f $_.Name
            }
            $body += @"
    </ItemGroup>
    <!-- cs -->
    <ItemGroup>`n
"@
            Get-ChildItem *.cs | % {
                $body += @"
        <Compile Include=`"{0}`" />`n 
"@ -f $_.Name
            }
            $body += @"
    </ItemGroup>
    <!-- Reference -->
"@
            Get-ChildItem .\csproj\*.csproj | Get-Content | % { $body += $_ + "`n" }
            $body += @"
	<Import Project="`$(MSBuildBinPath)\Microsoft.CSharp.targets" />
</Project>
"@
            $body > "$namespace.csproj"
            #endregion

            #region make Application.xaml
            cp ($PSScriptRoot + '\parts\Application.xaml') .\Application.xaml
            #endregion 

            C:\Windows\Microsoft.NET\Framework64\v4.0.30319\MSBuild
 
        }
        #endregion
    }
}