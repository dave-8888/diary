#ifndef ReleaseDir
  #error ReleaseDir define is required. Run ISCC with /DReleaseDir=...
#endif

#ifndef OutputDir
  #error OutputDir define is required. Run ISCC with /DOutputDir=...
#endif

#ifndef MyAppVersion
  #define MyAppVersion "0.2.0"
#endif

#ifndef MyOutputBaseFilename
  #define MyOutputBaseFilename "Diary-Setup"
#endif

#define MyAppId "{{8AA3FC87-7B95-4A20-B263-B77D3C01F7D7}"
#define MyAppName "日记"
#define MyAppPublisher "Diary MVP"
#define MyAppExeName "diary_mvp.exe"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Diary MVP
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\{#MyAppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDir}
OutputBaseFilename={#MyOutputBaseFilename}
SetupIconFile=..\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "chinesesimp"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; Flags: unchecked

[Files]
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "启动 {#MyAppName}"; Flags: nowait postinstall skipifsilent
