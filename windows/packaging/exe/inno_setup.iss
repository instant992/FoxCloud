[Setup]
AppId={{APP_ID}}
AppVersion={{APP_VERSION}}
AppName={{DISPLAY_NAME}}
AppPublisher={{PUBLISHER_NAME}}
AppPublisherURL={{PUBLISHER_URL}}
AppSupportURL={{PUBLISHER_URL}}
AppUpdatesURL={{PUBLISHER_URL}}
DefaultDirName={{INSTALL_DIR_NAME}}
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename={{OUTPUT_BASE_FILENAME}}
Compression=lzma
SolidCompression=yes
SetupIconFile={{SETUP_ICON_FILE}}
WizardStyle=modern
PrivilegesRequired={{PRIVILEGES_REQUIRED}}
ArchitecturesAllowed={{ARCH}}
ArchitecturesInstallIn64BitMode={{ARCH}}
LanguageDetectionMethod=uilanguage

[CustomMessages]
en.RemoveUserDataText=Do you want to remove saved settings and application data?%n%nThis action cannot be undone.
ru.RemoveUserDataText=Удалить сохранённые настройки и данные приложения?%n%nЭто действие нельзя отменить.
en.AppRunningError=Flowvy is currently running.%n%nPlease close the application before uninstalling.
ru.AppRunningError=Приложение Flowvy запущено.%n%nЗакройте приложение перед удалением.

[Code]
function IsProcessRunning(ProcessName: string): Boolean;
var
  ResultCode: Integer;
begin
  Result := Exec('cmd', '/c tasklist /FI "IMAGENAME eq ' + ProcessName + '" | find /I "' + ProcessName + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := Result and (ResultCode = 0);
end;

function InitializeUninstall(): Boolean;
begin
  // Добавляем отладочные сообщения
  if IsProcessRunning('Flowvy.exe') then
  begin
    MsgBox('Найден процесс Flowvy.exe', mbInformation, MB_OK);
    MsgBox(ExpandConstant('{cm:AppRunningError}'), mbError, MB_OK);
    Result := False;
    Exit;
  end;

  if IsProcessRunning('FlowvyCore.exe') then
  begin
    MsgBox('Найден процесс FlowvyCore.exe', mbInformation, MB_OK);
    MsgBox(ExpandConstant('{cm:AppRunningError}'), mbError, MB_OK);
    Result := False;
    Exit;
  end;

  if IsProcessRunning('FlowvyHelperService.exe') then
  begin
    MsgBox('Найден процесс FlowvyHelperService.exe', mbInformation, MB_OK);
    MsgBox(ExpandConstant('{cm:AppRunningError}'), mbError, MB_OK);
    Result := False;
    Exit;
  end;

  Result := True;
end;

procedure KillProcesses;
var
  Processes: TArrayOfString;
  i: Integer;
  ResultCode: Integer;
begin
  Processes := ['Flowvy.exe', 'FlowvyCore.exe', 'FlowvyHelperService.exe'];

  for i := 0 to GetArrayLength(Processes)-1 do
  begin
    Exec('taskkill', '/f /im ' + Processes[i], '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;

function InitializeSetup(): Boolean;
begin
  KillProcesses;
  Result := True;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
  begin
    if MsgBox(ExpandConstant('{cm:RemoveUserDataText}'), mbConfirmation, MB_YESNO or MB_DEFBUTTON2) = IDYES then
      DelTree(ExpandConstant('{userappdata}\Flowvy'), True, True, True);
  end;
end;

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: {% if CREATE_DESKTOP_ICON != true %}unchecked{% else %}checkedonce{% endif %}

[Files]
Source: "{{SOURCE_DIR}}\\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\\{{DISPLAY_NAME}}"; Filename: "{app}\\{{EXECUTABLE_NAME}}"
Name: "{autodesktop}\\{{DISPLAY_NAME}}"; Filename: "{app}\\{{EXECUTABLE_NAME}}"; Tasks: desktopicon

[Registry]
; Custom URL for Flowvy
Root: HKCR; Subkey: "flowvy"; ValueType: string; ValueName: ""; ValueData: "URL:flowvy Protocol"; Flags: uninsdeletekey
Root: HKCR; Subkey: "flowvy"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCR; Subkey: "flowvy\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{{EXECUTABLE_NAME}}"" ""%1"""; Flags: uninsdeletekey

[Run]
Filename: "{app}\\{{EXECUTABLE_NAME}}"; Description: "{cm:LaunchProgram,{{DISPLAY_NAME}}}"; Flags: {% if PRIVILEGES_REQUIRED == 'admin' %}runascurrentuser{% endif %} nowait postinstall skipifsilent
