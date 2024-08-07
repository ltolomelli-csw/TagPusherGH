unit GHRepoOperations.MainForm;

interface

uses
  Winapi.Windows, Winapi.ShellAPI, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Data.DB, Vcl.StdCtrls,
  Vcl.Grids, Vcl.DBGrids,
  GHRepoOperations.Models, AdvCustomControl, AdvTreeViewBase, AdvTreeViewData,
  AdvCustomTreeView, AdvTreeView, System.Actions, Vcl.ActnList, Vcl.Menus, Vcl.ComCtrls,
  System.Generics.Collections,
  System.IOUtils,
  System.Threading,
  GHRepoOperations.GHCommands,
  GHRepoOperations.MainRT,
  GHRepoOperations.Messages,
  GHRepoOperations.ProgBar,
  GHRepoOperations.TreeViewBuilder,
  GHRepoOperations.Types,
  GHRepoOperations.Utils;

type
  TFrmMain = class(TForm)
    pnlAll: TPanel;
    pnlTop: TPanel;
    pnlMain: TPanel;
    tvMain: TAdvTreeView;
    pbLoadData: TProgressBar;
    sbRepos: TStatusBar;
    pnlMainOptions: TPanel;
    cbxOrganizations: TComboBox;
    cbxTopics: TComboBox;
    lblOrganizations: TLabel;
    lblTopics: TLabel;
    pcFunctions: TPageControl;
    tbsPushNewTag: TTabSheet;
    rgNewMainTag: TRadioGroup;
    btnRepoList: TButton;
    rgOptionNewMainTag: TRadioGroup;
    pnlNewTagButtons: TPanel;
    btnNewTagExecute: TButton;
    btnNewTagClean: TButton;
    pnlTreeButtons: TPanel;
    btnSelectAll: TButton;
    btnDeselectAll: TButton;
    btnReverseSelection: TButton;
    ActionList1: TActionList;
    popupTree: TPopupMenu;
    actOpenRepoMain: TAction;
    menuOpenRepoMain: TMenuItem;
    actOpenRepoBranch: TAction;
    actOpenRepoReleases: TAction;
    menuOpenRepoBranch: TMenuItem;
    menuOpenRepoReleases: TMenuItem;
    actOpenRepoTags: TAction;
    menuOpenRepoTags: TMenuItem;
    procedure btnRepoListClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tvMainAfterUnCheckNode(Sender: TObject;
      ANode: TAdvTreeViewVirtualNode; AColumn: Integer);
    procedure tvMainAfterCheckNode(Sender: TObject;
      ANode: TAdvTreeViewVirtualNode; AColumn: Integer);
    procedure rgNewMainTagClick(Sender: TObject);
    procedure btnNewTagExecuteClick(Sender: TObject);
    procedure rgOptionNewMainTagClick(Sender: TObject);
    procedure btnNewTagCleanClick(Sender: TObject);
    procedure btnSelectAllClick(Sender: TObject);
    procedure btnDeselectAllClick(Sender: TObject);
    procedure btnReverseSelectionClick(Sender: TObject);
    procedure tvMainNodeMouseEnter(Sender: TObject;
      ANode: TAdvTreeViewVirtualNode);
    procedure tvMainNodeMouseLeave(Sender: TObject;
      ANode: TAdvTreeViewVirtualNode);
    procedure actOpenRepoMainExecute(Sender: TObject);
    procedure actOpenRepoBranchExecute(Sender: TObject);
    procedure actOpenRepoReleasesExecute(Sender: TObject);
    procedure actOpenRepoTagsExecute(Sender: TObject);
  private
    FMainRT: TGHRepoOperationsRT;
    FTreeViewBuilder: TTreeViewBuilder;
    FSelectedNode: TAdvTreeViewNode;
    procedure FillTreeView(const ARepoModels: TArray<TGHCliRepoModel>);
    procedure OnTerminateFillTreeView(Sender: TObject);
    procedure EnableBtnRepoList;
    procedure EnableBtnTreeButtons;
    procedure EnableRgOptionNewMainTag;
    procedure EnableRgNewMainTag;
    function GetNewTagOperationFromSelection: TNewTagOperation;
    function NewTagOptionOnlySelected: Boolean;
    procedure InitCompPushNewTag;
    procedure InitComponents;
    procedure OpenRepoLink(const ARepoLinkType: TRepoLinkType);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.dfm}

procedure TFrmMain.actOpenRepoBranchExecute(Sender: TObject);
begin
  OpenRepoLink(rltBranch);
end;

procedure TFrmMain.actOpenRepoMainExecute(Sender: TObject);
begin
  OpenRepoLink(rltMain);
end;

procedure TFrmMain.actOpenRepoReleasesExecute(Sender: TObject);
begin
  OpenRepoLink(rltReleases);
end;

procedure TFrmMain.actOpenRepoTagsExecute(Sender: TObject);
begin
  OpenRepoLink(rltTags);
end;

procedure TFrmMain.btnDeselectAllClick(Sender: TObject);
var
  I: Integer;
begin
  inherited;
  for I := 0 to tvMain.Nodes.Count -1 do
    tvMain.UnCheckNode(tvMain.Nodes[I], 0, True)
end;

procedure TFrmMain.btnNewTagCleanClick(Sender: TObject);
begin
  FTreeViewBuilder.CalculateNewMainTags( ntoClean, NewTagOptionOnlySelected );
end;

procedure TFrmMain.btnNewTagExecuteClick(Sender: TObject);
var
  LSelectedNodes: TArray<TAdvTreeViewNode>;
  I: Integer;
  LNode: TAdvTreeViewNode;
  LNodeData: TTVNodeData;
  LFilter: TFunc<TTVNodeData, Boolean>;
  LMainRT: TGHRepoOperationsRT;
begin
  LFilter :=
    function (ATVNodeData: TTVNodeData): Boolean
    begin
      Result := not(ATVNodeData.IsRoot);
    end;

  if not(FTreeViewBuilder.GetSelectedNodes(LFilter, LSelectedNodes)) then
    Exit;

  {TODO -o04/07/2024 -c : Sicuramente migliorabile, da capire come}
  try
    for I := 0 to High(LSelectedNodes) do
    begin
      LNode := LSelectedNodes[I];
      if FTreeViewBuilder.GetTVNodeData(LNode, LNodeData) then
      begin
        LMainRT := TGHRepoOperationsRT.Create(True);
        LMainRT.TVNodeData := LNodeData;
        LMainRT.ThreadOperation := TThreadOperation.toTagPush; {TODO -o04/07/2024 -c : recuperare in base al valore selezionato}
        LMainRT.GHRepoOpProgressBar := TGHRepoOpProgressBar.Create(pbLoadData, sbRepos.Panels[0]);
        LMainRT.Start;
      end;
    end;
  finally
    TGHVCLUtils.EnableControlsAndChilds(pnlTop, True, True);
  end;
end;

procedure TFrmMain.btnRepoListClick(Sender: TObject);
var
  LOrg, LTopic: string;
begin
  LOrg   := cbxOrganizations.Items[cbxOrganizations.ItemIndex];
  LTopic := cbxTopics.Items[cbxTopics.ItemIndex];

  // utilizzo una variabile globale alla classe cos� da farci riferimento
  // nell'evento OnTerminate
  FMainRT := TGHRepoOperationsRT.Create(True);
  FMainRT.ThreadOperation := TThreadOperation.toRepoExtraction;
  FMainRT.GHRepoOpProgressBar := TGHRepoOpProgressBar.Create(pbLoadData, sbRepos.Panels[0]);
  FMainRT.Organization := LOrg;
  FMainRT.Topic := LTopic;
  FMainRT.OnTerminate := OnTerminateFillTreeView;

  // riabilito i controlli nell'OnTerminate
  TGHVCLUtils.EnableControlsAndChilds(pnlTop, False, True);
  FMainRT.Start;
end;

procedure TFrmMain.btnReverseSelectionClick(Sender: TObject);
var
  LNode: TAdvTreeViewNode;
begin
  // ciclo su tutti i nodi
  LNode := tvMain.GetFirstRootNode;
  repeat
    LNode.Checked[0] := not(LNode.Checked[0]);
    LNode := LNode.GetNext;
  until (LNode = nil); // sono arrivato a fine albero
end;

procedure TFrmMain.btnSelectAllClick(Sender: TObject);
var
  I: Integer;
begin
  inherited;
  for I := 0 to tvMain.Nodes.Count -1 do
    tvMain.CheckNode(tvMain.Nodes[I], 0, True)
end;

constructor TFrmMain.Create(AOwner: TComponent);
begin
  inherited;
  FTreeViewBuilder := TTreeViewBuilder.Create(tvMain);
end;

destructor TFrmMain.Destroy;
begin
  FreeAndNil(FTreeViewBuilder);
  inherited;
end;

procedure TFrmMain.EnableBtnRepoList;
begin
  btnRepoList.Enabled := True;
end;

procedure TFrmMain.EnableBtnTreeButtons;
begin
  TGHVCLUtils.EnableControlsAndChilds(pnlTreeButtons, tvMain.Nodes.Count > 0, True);
end;

procedure TFrmMain.EnableRgNewMainTag;
begin
  rgNewMainTag.Enabled := (rgOptionNewMainTag.ItemIndex > -1) and rgOptionNewMainTag.Enabled;
end;

procedure TFrmMain.EnableRgOptionNewMainTag;
begin
  rgOptionNewMainTag.Enabled := (tvMain.Nodes.Count > 0);
end;

procedure TFrmMain.OnTerminateFillTreeView(Sender: TObject);
begin
  try
    FillTreeView( FMainRT.RepoModels );
  finally
    TGHVCLUtils.EnableControlsAndChilds(pnlTop, True, True);
    EnableBtnTreeButtons;
    EnableRgNewMainTag;
  end;
end;

procedure TFrmMain.OpenRepoLink(const ARepoLinkType: TRepoLinkType);
var
  LNodeData: TTVNodeData;
  LLink: string;
begin
  if Assigned(FSelectedNode) and TTreeViewBuilder.GetTVNodeData(FSelectedNode, LNodeData) then
  begin
    case ARepoLinkType of
      rltMain:      LLink := LNodeData.RepoModel.GetLink;
      rltBranch:    LLink := LNodeData.RepoModel.GetLink(LNodeData.Branch);
      rltReleases:  LLink := LNodeData.RepoModel.GetReleasesLink;
      rltTags:      LLink := LNodeData.RepoModel.GetTagsLink;
      else
        raise Exception.Create('Tipologia link non supportata');
    end;

    ShellExecute(0, 'open', PWideChar(LLink), nil, nil, SW_SHOWNORMAL);
  end;
end;

procedure TFrmMain.FillTreeView(const ARepoModels: TArray<TGHCliRepoModel>);
begin
  tvMain.BeginUpdate;
  try
    FTreeViewBuilder.LoadRepos(ARepoModels);
  finally
    tvMain.EndUpdate;
    tvMain.ExpandAll;
  end;
end;

procedure TFrmMain.FormShow(Sender: TObject);
begin
  InitComponents;
end;

function TFrmMain.GetNewTagOperationFromSelection: TNewTagOperation;
begin
  case rgNewMainTag.ItemIndex of
    0: Result := ntoIncreaseMinor;
    1: Result := ntoIncreaseFix;
    else
      Result := ntoNull;
  end;
end;

procedure TFrmMain.InitComponents;
begin
  cbxOrganizations.ItemIndex := 0;
  cbxTopics.ItemIndex := 0;

  InitCompPushNewTag;

  EnableBtnTreeButtons;
  EnableBtnRepoList;
  EnableRgOptionNewMainTag;
  EnableRgNewMainTag;

  sbRepos.Panels[0].Width := sbRepos.Width;
end;

procedure TFrmMain.InitCompPushNewTag;
begin
  rgOptionNewMainTag.ItemIndex := -1;
  rgNewMainTag.ItemIndex := -1;
end;

function TFrmMain.NewTagOptionOnlySelected: Boolean;
begin
  Result := rgOptionNewMainTag.ItemIndex = 1;
end;

procedure TFrmMain.rgNewMainTagClick(Sender: TObject);
begin
  FTreeViewBuilder.CalculateNewMainTags( GetNewTagOperationFromSelection, NewTagOptionOnlySelected );
end;

procedure TFrmMain.rgOptionNewMainTagClick(Sender: TObject);
begin
  EnableRgNewMainTag;
  rgNewMainTag.ItemIndex := -1;
end;

procedure TFrmMain.tvMainAfterCheckNode(Sender: TObject;
  ANode: TAdvTreeViewVirtualNode; AColumn: Integer);
var
  LNodeData: TTVNodeData;
begin
  if TTreeViewBuilder.GetTVNodeData(ANode.Node, LNodeData) then
    if LNodeData.IsRoot then
      tvMain.CheckNode(ANode.Node, 0, True);
end;

procedure TFrmMain.tvMainAfterUnCheckNode(Sender: TObject;
  ANode: TAdvTreeViewVirtualNode; AColumn: Integer);
var
  LNodeData: TTVNodeData;
begin
  if TTreeViewBuilder.GetTVNodeData(ANode.Node, LNodeData) then
    if LNodeData.IsRoot then
      tvMain.UnCheckNode(ANode.Node, 0, True);
end;

procedure TFrmMain.tvMainNodeMouseEnter(Sender: TObject;
  ANode: TAdvTreeViewVirtualNode);
begin
  FSelectedNode := ANode.Node;
end;

procedure TFrmMain.tvMainNodeMouseLeave(Sender: TObject;
  ANode: TAdvTreeViewVirtualNode);
begin
  FSelectedNode := nil;
end;

end.
