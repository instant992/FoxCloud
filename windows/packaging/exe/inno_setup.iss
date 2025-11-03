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
en.AppRunningWarning=Flowvy is currently running.%n%nThe installer will automatically close the application and stop all services. Do you want to continue?
ru.AppRunningWarning=Приложение Flowvy запущено.%n%nУстановщик автоматически закроет приложение%nи остановит все службы. Продолжить?
en.StoppingProcesses=Stopping Flowvy processes and services...%n%nThis may take a few moments.
ru.StoppingProcesses=Остановка процессов и служб Flowvy...%n%nЭто может занять несколько секунд.

[Code]
function IsProcessRunning(ProcessName: string): Boolean;
var
  ResultCode: Integer;
begin
  Result := Exec('cmd', '/c tasklist /FI "IMAGENAME eq ' + ProcessName + '" | find /I "' + ProcessName + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := Result and (ResultCode = 0);
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

procedure StopAllProcessesAndService;
var
  ResultCode: Integer;
  AttemptCount: Integer;
begin
  Log('Stopping all Flowvy processes and services...');

  // First, try to stop the service gracefully
  Log('Attempting to stop FlowvyHelperService...');
  Exec('sc', 'stop FlowvyHelperService', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Log('Service stop result code: ' + IntToStr(ResultCode));
  Sleep(1000); // Give it time to stop

  // Try graceful kill first with /T (terminate process tree)
  Log('Attempting graceful termination of Flowvy.exe...');
  Exec('taskkill', '/T /IM Flowvy.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(500);

  Log('Attempting graceful termination of FlowvyCore.exe...');
  Exec('taskkill', '/T /IM FlowvyCore.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(500);

  // Force kill if still running
  Log('Force terminating any remaining processes...');
  KillProcesses;

  // Wait and verify all processes stopped
  AttemptCount := 0;
  while (AttemptCount < 5) and (IsProcessRunning('Flowvy.exe') or
         IsProcessRunning('FlowvyCore.exe') or
         IsProcessRunning('FlowvyHelperService.exe')) do
  begin
    Log('Waiting for processes to stop (attempt ' + IntToStr(AttemptCount + 1) + '/5)...');
    Sleep(500);
    AttemptCount := AttemptCount + 1;
  end;

  if IsProcessRunning('Flowvy.exe') or IsProcessRunning('FlowvyCore.exe') or
     IsProcessRunning('FlowvyHelperService.exe') then
  begin
    Log('Warning: Some processes may still be running after 5 attempts');
  end
  else
  begin
    Log('All processes successfully stopped');
  end;
end;

function InitializeUninstall(): Boolean;
begin
  Log('Uninstall initializing...');

  // Stop all processes and service automatically
  StopAllProcessesAndService;

  Log('Ready to proceed with uninstall');
  Result := True;
end;

function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Log('Installation initializing - checking for running processes...');

  // Check if any Flowvy processes are running
  if IsProcessRunning('Flowvy.exe') or IsProcessRunning('FlowvyCore.exe') or
     IsProcessRunning('FlowvyHelperService.exe') then
  begin
    Log('Found running Flowvy processes');

    // Ask user for confirmation
    if MsgBox(ExpandConstant('{cm:AppRunningWarning}'), mbConfirmation, MB_YESNO or MB_DEFBUTTON1) = IDYES then
    begin
      Log('User confirmed - stopping processes...');

      // Stop service and processes automatically
      StopAllProcessesAndService;

      Log('Previous installation cleaned up');
    end
    else
    begin
      Log('User cancelled installation');
      Result := False;
      Exit;
    end;
  end
  else
  begin
    Log('No running Flowvy processes found');
  end;

  // Always try to delete old service if it exists
  Log('Removing existing FlowvyHelperService if present...');
  Exec('sc', 'delete FlowvyHelperService', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(200);

  Log('Initialization completed successfully');
  Result := True;
end;

procedure DeleteService;
var
  ResultCode: Integer;
begin
  Log('Attempting to delete FlowvyHelperService from Windows Services...');

  // Delete the service from Windows Services (already stopped in InitializeUninstall)
  if Exec('sc', 'delete FlowvyHelperService', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    Log('Service delete command executed with result code: ' + IntToStr(ResultCode));
  end
  else
  begin
    Log('Failed to execute service delete command');
  end;

  Sleep(200);
  Log('Service deletion completed');
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
  begin
    Log('Uninstall step: Removing service registration...');

    // Delete Windows service from registry (already stopped in InitializeUninstall)
    DeleteService;

    Log('Service cleanup completed, files will be removed next');
  end;

  if CurUninstallStep = usPostUninstall then
  begin
    Log('Post-uninstall: Files removed successfully');
    Log('Checking if user data should be removed...');

    if MsgBox(ExpandConstant('{cm:RemoveUserDataText}'), mbConfirmation, MB_YESNO or MB_DEFBUTTON2) = IDYES then
    begin
      Log('User chose to remove application data from %APPDATA%');
      DelTree(ExpandConstant('{userappdata}\Flowvy'), True, True, True);
      Log('Application data removed successfully');
    end
    else
    begin
      Log('User chose to keep application data in %APPDATA%');
    end;

    Log('Uninstall completed successfully');
  end;
end;

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"

[Messages]
en.StatusUninstalled=Flowvy has been successfully removed.
ru.StatusUninstalled=Программа Flowvy успешно удалена.
en.UninstalledAll=Flowvy has been successfully removed from your computer.
ru.UninstalledAll=Программа Flowvy успешно удалена с вашего компьютера.

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
