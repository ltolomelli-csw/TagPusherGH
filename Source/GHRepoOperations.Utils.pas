unit GHRepoOperations.Utils;

interface

uses
  Vcl.Controls,
  System.SysUtils,
  System.TypInfo,
  GHRepoOperations.Constants,
  GHRepoOperations.Types;

type
  TGHReleaseTypeDecode = class
    class function PairFromEnum(const AEnum: TGHReleaseType): TPairGHReleaseType;
    class function PairFromDescr(const ADescr: string): TPairGHReleaseType;
  end;

  TGHVCLUtils = class
    class procedure EnableControlsAndChilds(AControl: TWinControl; const AEnable, ANested: Boolean);
  end;

implementation

{ TGHReleaseTypeDecode }

class function TGHReleaseTypeDecode.PairFromDescr(const ADescr: string): TPairGHReleaseType;
begin
  if SameText(ADescr, 'null') then
    Result.Create(grtPreRelease, ADescr)
  else
  if ADescr.IsEmpty then
    Result.Create(grtNormal, ADescr)
  else
  if SameText(ADescr, 'Latest') then
    Result.Create(grtLatest, ADescr)
  else
  if SameText(ADescr, 'Pre-release') then
    Result.Create(grtPreRelease, ADescr)
  else
    raise Exception.CreateFmt('Descrizione %s non gestita', [ADescr.QuotedString]);
end;

class function TGHReleaseTypeDecode.PairFromEnum(const AEnum: TGHReleaseType): TPairGHReleaseType;
begin
  case AEnum of
    grtNull:   Result.Create(AEnum, 'null');
    grtNormal: Result.Create(AEnum, '');
    grtLatest: Result.Create(AEnum, 'Latest');
    grtPreRelease: Result.Create(AEnum, 'Pre-release');
    else
      raise Exception.CreateFmt(
        'Enumerato %s non gestito', [GetEnumName(TypeInfo(TGHReleaseType), Ord(AEnum)).QuotedString]
      );
  end;
end;

{ TGHVCLUtils }

class procedure TGHVCLUtils.EnableControlsAndChilds(AControl: TWinControl;
  const AEnable, ANested: Boolean);
var
  I: Integer;
begin
  // abilito/disabilito il componente e i suoi eventuali figli, se richiesto e se presenti
  AControl.Enabled := AEnable;
  for I := 0 to AControl.ControlCount -1 do
  begin
    if ANested and (AControl.Controls[I] is TWinControl) then
    begin
      if (TWinControl(AControl.Controls[I]).ControlCount > 0) then
        EnableControlsAndChilds(TWinControl(AControl.Controls[I]), AEnable, ANested);
    end;
    AControl.Controls[I].Enabled := AEnable;
  end;
end;

end.
