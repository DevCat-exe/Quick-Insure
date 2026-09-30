; Quick Insure Windows installer (Inno Setup 6.3 or newer).
; Compile with: ISCC.exe windows\installer.iss
; The release version is read from the QUICK_INSURE_APP_VERSION environment
; variable, which the release workflow fills from the release tag. Inno Setup
; 6.7 removed the old /DAppVersion= command line define.

#ifndef AppVersion
  #define AppVersion GetEnv("QUICK_INSURE_APP_VERSION")
#endif

#if AppVersion == ""
  #error Set the QUICK_INSURE_APP_VERSION environment variable, for example "2.2.0", before compiling.
#endif

#define MyAppName "Quick Insure"
#define MyAppPublisher "Devcat-exe"
#define MyAppExeName "quick_insure.exe"
#define MyAppVersion AppVersion
; Inno Setup requires a four part numeric version for the setup file itself.
#define MyAppVersionQuad AppVersion + ".0"

[Setup]
AppId={{D1A2B3C4-E5F6-7890-ABCD-1234567890AB}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
VersionInfoVersion={#MyAppVersionQuad}
VersionInfoCompany={#MyAppPublisher}
VersionInfoProductName={#MyAppName}
VersionInfoDescription={#MyAppName} Setup
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
AllowNoIcons=yes
OutputDir=..\build\release-assets
OutputBaseFilename=quick_insure_windows_setup
SetupIconFile=runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
