unit GHRepoOperations.Models;

interface

uses
  System.SysUtils,
  GHRepoOperations.Types;

type
  TTVNodeData = class
    IsRoot: Boolean;
    ShowCheckBox: Boolean;
    Repository: string;
    Branch: string;
    Tag: string;
    ReleaseType: TPairGHReleaseType;
  end;

  TGHCliTagModel = class
    Tag: string;
    NewTag: string;
    ReleaseType: TPairGHReleaseType;
  end;

  TGHCliRepoModel = class
    Organization: string;
    Name: string;
    Branches: TArray<string>;
    Tags: TArray<TGHCliTagModel>;

  public
    destructor Destroy; override;

    function FullName: string;
  end;

implementation

{ TGHCliRepoModel }

destructor TGHCliRepoModel.Destroy;
var
  I: Integer;
begin
  for I := 0 to High(Tags) do
    FreeAndNil(Tags[I]);

  inherited;
end;

function TGHCliRepoModel.FullName: string;
begin
  Result := Organization + '/' + Name;
end;

end.