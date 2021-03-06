unit fFamHistory;

interface

uses

  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,

  fPage, StdCtrls, uCore, Menus, ORCtrls, ORFn, ExtCtrls, ComCtrls, rOrders,
  uConst,

  ORNet, fBase508Form, VA508AccessibilityManager, fHSplit, Data.Bind.EngExt,
  Vcl.Bind.DBEngExt, Data.Bind.Components, rFamHistory, fFamHistEdit,
  uFamHistoryGlobals, Vcl.Grids;

type

  TfrmFamHistory = class(TfrmPage)
    mnuFamHist: TMainMenu;
    mnuView: TMenuItem;
    mnuViewChart: TMenuItem;
    mnuChartCover: TMenuItem;
    mnuChartProbs: TMenuItem;
    mnuChartMeds: TMenuItem;
    mnuChartOrders: TMenuItem;
    mnuChartNotes: TMenuItem;
    mnuChartCslts: TMenuItem;
    mnuChartSurgery: TMenuItem;
    mnuChartDCSumm: TMenuItem;
    mnuChartLabs: TMenuItem;
    mnuChartReports: TMenuItem;
    mnuViewInformation: TMenuItem;
    mnuViewDemo: TMenuItem;
    mnuViewVisits: TMenuItem;
    mnuViewPrimaryCare: TMenuItem;
    mnuViewMyHealtheVet: TMenuItem;
    mnuInsurance: TMenuItem;
    mnuViewFlags: TMenuItem;
    mnuViewRemoteData: TMenuItem;
    mnuViewReminders: TMenuItem;
    mnuViewPostings: TMenuItem;
    Z1: TMenuItem;
    mnuViewActive: TMenuItem;
    mnuViewInactive: TMenuItem;
    mnuViewBoth: TMenuItem;
    mnuViewRemoved: TMenuItem;
    mnuViewFilters: TMenuItem;
    mnuViewComments: TMenuItem;
    N2: TMenuItem;
    mnuViewSave: TMenuItem;
    mnuViewRestoreDefault: TMenuItem;
    mnuAct: TMenuItem;
    mnuActNew: TMenuItem;
    Z3: TMenuItem;
    mnuActChange: TMenuItem;
    mnuActInactivate: TMenuItem;
    mnuActVerify: TMenuItem;
    N1: TMenuItem;

    mnuActAnnotate: TMenuItem;

    Z4: TMenuItem;

    mnuActRemove: TMenuItem;

    mnuActRestore: TMenuItem;

    N4: TMenuItem;

    mnuActDetails: TMenuItem;
    pnlMain: TPanel;
    capLstFamHist: TCaptionListBox;
    pnlLeft: TPanel;
    splitVert: TSplitter;
    pnlButtons: TPanel;
    btnAddNewHistoryRecord: TORAlignButton;
    Panel1: TPanel;
    Panel2: TPanel;
    sgfhist: TStringGrid;
    Label2: TLabel;
    hc: THeaderControl;
    pnlTop: TPanel;
    lstView: TORListBox;
    Splitter1: TSplitter;
    vsplit: TSplitter;
    Label1: TLabel;

    procedure btnCancelClick(Sender: TObject);

    procedure ViewInfo(Sender: TObject);

    procedure btnAddNewHistoryRecordClick(Sender: TObject);

    procedure capLstFamHistDblClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure lv1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure lstFhistDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure FormResize(Sender: TObject);
    procedure sgfhistDblClick(Sender: TObject);
    procedure ClearHistGrid;
    procedure lstViewClick(Sender: TObject);

  private

    { Private declarations }
    FMousing: TDateTime;
    FWarningShown: boolean;
    procedure LoadFHDiseaseGroups;
    procedure LoadAllFamilyHistoryRecs;
    procedure AutoSizeCol(Grid: TStringGrid; Column: Integer);
    function FoundHistRecMatch(var aRelative, aName, aVStatus,
      aCond: String): boolean;
    procedure RefreshHistoryListing;
    function BuildDiseaseCondMaster: TStrings;
    function GetFilteredDiseaseList(aList: TStrings): TStrings;
    function GetFilterdRecs(aList: TStrings): TStrings;
    function LoadFilterdRecs(aList: TStrings): boolean;

  public

    { Public declarations }
    aClickedCell: longint;
    procedure DisplayPage; override;
    procedure ShowPnlView;

  end;

var
  frmFamHistory: TfrmFamHistory;
  slCommTest,fSelectedFilters: TStrings;
  fAllFamHistory: TStringList;
  tmpRelat, tmpName, tmpStatus, tmpCurrAge, tmpDisease, tmpAgeDx, tmpDied,
    tmpComments: string;

implementation

{$R *.dfm}

uses fFrame, rProbs, rcover, fCover, fRptBox, rCore,
  fEncnt, fReportsPrint, fReports, rPCE, DateUtils, VA2006Utils,
  VA508AccessibilityRouter;

const

  CT_FAMHIST = 12; // ID for Family History tab used by frmFrame

  // column names of StringGrid

  cRelatiive = 0;
  cName = 1;
  cVStat = 2;
  cCurrAge = 3;
  cHistOf = 4;
  cAgeDx = 5;
  cAgeDied = 6;
  cComments = 7;
  cEnteredBy = 8;
  cDateMod = 9;

procedure TfrmFamHistory.btnCancelClick(Sender: TObject);
begin
  inherited;
  close;
end;

procedure TfrmFamHistory.DisplayPage;
begin
  inherited DisplayPage;
  frmFrame.ShowHideChartTabMenus(mnuViewChart);
  frmFrame.mnuFilePrint.Tag := CT_FAMHIST;
  frmFamHistory.Parent := frmFrame.pnlPage.Parent;
  frmFrame.pnlToolbar.BringToFront;
  frmFrame.pnlToolbar.Show;

  if InitPatient then
  begin
    fAllFamHistory := TStringList.Create;
    fAllFamHistory.Clear;
    FWarningShown := False;
    ShowPnlView;
    LoadFHDiseaseGroups;
    LoadAllFamilyHistoryRecs;
  end;

  if TabCtrlClicked and (ChangingTab = CT_FAMHIST) then
    FamHistTabClicked := True;

  if (btnAddNewHistoryRecord.CanFocus) and (not pnlButtons.Visible) and
    ((not PTSwitchRefresh) or FamHistTabClicked) then
    btnAddNewHistoryRecord.SetFocus;

  if PTSwitchRefresh then
    PTSwitchRefresh := False;

  if TabCtrlClicked then
    TabCtrlClicked := False;

  if FamHistTabClicked then
    FamHistTabClicked := False;

  if sgfhist.RowCount <= 1 then
  begin
    if frmFamHistEdit.Enter then
    begin
      RefreshHistoryListing;
      SetAddedHistoryRec(False);
    end;
  end;
end;

procedure TfrmFamHistory.FormResize(Sender: TObject);
begin
  inherited;
  sgfhist.ColCount := 10;
  sgfhist.FixedRows := 0;
  sgfhist.FixedCols := 0;
  sgfhist.Align := alLeft;
  hc.Sections[0].Width := 165; // relative
  hc.Sections[1].Width := 60; // name
  hc.Sections[2].Width := 88; // vital status  80
  hc.Sections[3].Width := 90; // Current age
  hc.Sections[4].Width := 180; // History of    170
  hc.Sections[5].Width := 100; // age dx
  hc.Sections[6].Width := 80; // deceased age
  hc.Sections[7].Width := 200; // comments
  hc.Sections[8].Width := 85; // Entered by   140
  hc.Sections[9].Width := 110; // Date Modified
  // hc.Sections[10].Width := 75; // Modified by

  // sgfhist.ColWidths[0] := hc.Sections[0].width+ hc.Sections[1].width+hc.Sections[2].width+2;
  sgfhist.ColWidths[0] := hc.Sections[0].Width; //relative
  sgfhist.ColWidths[1] := hc.Sections[1].Width; // name
  sgfhist.ColWidths[2] := hc.Sections[2].Width;  // vital status  80
  sgfhist.ColWidths[3] := hc.Sections[3].Width + 5;  // Current age
  sgfhist.ColWidths[4] := hc.Sections[4].Width;  // History of    170
  sgfhist.ColWidths[5] := hc.Sections[5].Width;  // age dx
  sgfhist.ColWidths[6] := hc.Sections[6].Width;  // deceased age
  sgfhist.ColWidths[7] := hc.Sections[7].Width;   // comments
  sgfhist.ColWidths[8] := hc.Sections[8].Width;   // Entered by   140
  sgfhist.ColWidths[9] := hc.Sections[9].Width;    // Date Modified
  // sgfhist.ColWidths[10] := hc.Sections[10].Width;
  if Height > Screen.Height then
    Height := Screen.Height;

end;

procedure TfrmFamHistory.LoadAllFamilyHistoryRecs;
var
  i, ii, r: Integer;
  X: string;
  aFHRec: TStringList;
begin
  for ii := 0 to lstView.Items.Count - 1 do
  begin
    if (lstView.Checked[ii]) then
    begin
      lstViewClick(self);
      exit;
    end;
  end;

  ClearHistGrid;
  aFHRec := TStringList.Create;
  aFHRec.Clear;
  FastAssign(GetAllFamilyHistoryRecords(Patient.DFN), aFHRec);

  with sgfhist do
  begin
    if aFHRec.Count = 0 then
      exit;
    r := 0;
    RowCount := aFHRec.Count + 1;
    for i := 0 to aFHRec.Count - 1 do
    begin
      X := aFHRec[i];
      if X = '1' then
        continue
      else
      begin
        Cells[cRelatiive, r] := Piece(aFHRec[i], U, 3);
        Cells[cName, r] := Piece(aFHRec[i], U, 2);
        Cells[cVStat, r] := Piece(aFHRec[i], U, 4);
        Cells[cCurrAge, r] := Piece(aFHRec[i], U, 12);
        Cells[cHistOf, r] := Piece(aFHRec[i], U, 15);
        Cells[cAgeDx, r] := Piece(aFHRec[i], U, 14);
        Cells[cAgeDied, r] := Piece(aFHRec[i], U, 5);
        Cells[cComments, r] := Piece(aFHRec[i], U, 6);
        Cells[cEnteredBy, r] := Piece(aFHRec[i], U, 8);
        Cells[cDateMod, r] := Piece(aFHRec[i], U, 17);
        // Cells[cModBy, r] := Piece(aFHRec[i], U, 18);
        inc(r);
        sgfhist.RowCount := r;
      end;
    end;
  end;
end;

procedure TfrmFamHistory.ShowPnlView;

begin
  pnlMain.BringToFront;
  pnlMain.Show;
  sgfhist.TabStop := True;
  btnAddNewHistoryRecord.TabStop := True;

  if pnlMain.Visible then

  begin

    pnlButtons.Visible := True;

  end;

  lstView.TabStop := True;

  btnAddNewHistoryRecord.TabStop := True;

end;

procedure TfrmFamHistory.ViewInfo(Sender: TObject);

begin

  inherited;

  frmFrame.ViewInfo(Sender);

end;

procedure TfrmFamHistory.RefreshHistoryListing;
begin
  LoadAllFamilyHistoryRecs;
end;

procedure TfrmFamHistory.btnAddNewHistoryRecordClick(Sender: TObject);

begin
  if frmFamHistEdit.Enter then
  begin
    RefreshHistoryListing;
    SetAddedHistoryRec(False);
  end;
end;

procedure TfrmFamHistory.Button1Click(Sender: TObject);
begin
  inherited;
  slCommTest := TStringList.Create;
  TestKNRCommLink(slCommTest);
  slCommTest.Clear;
  slCommTest.Free;
  ShowMessage('Test completed');

end;

procedure TfrmFamHistory.capLstFamHistDblClick(Sender: TObject);

begin

  inherited;

  // get selected record if record selected from list

end;

procedure TfrmFamHistory.LoadFHDiseaseGroups;
begin
  lstView.Clear;
  lstView.CheckBoxes := True;
  // lstView.Checked[-1] := False;
  FastAssign(GetFHDiseaseGrps, lstView.Items);
end;

procedure TfrmFamHistory.lstFhistDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
begin
  inherited;
  sgfhist.Font.Size := MainFontSize;
end;

procedure TfrmFamHistory.lstViewClick(Sender: TObject);
var
  i, j,g: Integer;
  X: string;
  aList, aNewList, aFilters: TStrings;
begin
  inherited;
  aList := TStringList.Create;
  aNewList := TStringList.Create;
  aFilters := TStringList.Create;
  aList.Clear;
  aFilters.Clear;
  aNewList.Clear;
  try
    for i := 0 to lstView.Items.Count - 1 do
    begin
      if (lstView.Checked[i]) then
      begin
        aList.Add(lstView.Items[i]);
      end;
    end;
    // use selected Disease Groups use the Groups IEN and Cond IEN
    // to get all Conditions whos IEN = Disease Group IEN, use that list
    // to build the new list, display to user
    if aList.Count > 0 then
    begin
    //get all conditions in the selected Disease Group selected by user
     aFilters.Assign(GetFilteredDiseaseList(aList));
     g := aFilters.Count;
      aNewlist.Assign(GetFilterdRecs(aFilters));
      g := aNewList.Count;
      if not LoadFilterdRecs(aNewList) then
        ShowMessage('Error occured loading filtered records.');
    end
    else
      LoadAllFamilyHistoryRecs;
  finally
    aList.Free;
    aNewList.Free;
    aFilters.Free;
  end;

end;

procedure TfrmFamHistory.lv1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  FMousing := Now;
end;

procedure TfrmFamHistory.sgfhistDblClick(Sender: TObject);
var
  recTmp: TGridRect;
begin
  inherited;
  // get the col values of the selected row
  recTmp := sgfhist.selection;
  aClickedCell := recTmp.Top;
  tmpRelat := sgfhist.Cells[0, aClickedCell];
  tmpName := sgfhist.Cells[1, aClickedCell];
  tmpStatus := sgfhist.Cells[2, aClickedCell];
  tmpCurrAge := sgfhist.Cells[3, aClickedCell];
  tmpDisease := sgfhist.Cells[4, aClickedCell];
  tmpAgeDx := sgfhist.Cells[5, aClickedCell];
  tmpDied := sgfhist.Cells[6, aClickedCell];
  tmpComments := sgfhist.Cells[7, aClickedCell];
  if FoundHistRecMatch(tmpRelat, tmpName, tmpStatus, tmpDisease) then
  begin
    frmFamHistEdit.LoadFromSelectedHistory;
    RefreshHistoryListing;
  end;

end;

procedure TfrmFamHistory.AutoSizeCol(Grid: TStringGrid; Column: Integer);
var
  i, W, WMax: Integer;
begin
  WMax := 0;
  for i := 0 to (Grid.RowCount - 1) do
  begin
    W := Grid.Canvas.TextWidth(Grid.Cells[Column, i]);
    if W > WMax then
      WMax := W;
  end;
  Grid.ColWidths[Column] := WMax + 5;

end;

procedure TfrmFamHistory.ClearHistGrid;
var
  i, j: Integer;
begin
  with sgfhist do
    for i := 0 to ColCount - 1 do
      for j := 0 to RowCount - 1 do
        Cells[i, j] := '0';
end;

function TfrmFamHistory.FoundHistRecMatch(var aRelative, aName, aVStatus,
  aCond: String): boolean;
var
  X, holdName, holdRelat, holdVStatus, holdCond: string;
  i: Integer;
  tmpList: TStrings;
begin
  Result := False;
  tmpList := TStringList.Create;
  tmpList.Clear;
  FastAssign(GetAllFamilyHistoryRecords(Patient.DFN), tmpList);
  try
    begin
      for i := 0 to tmpList.Count - 1 do
      begin
        X := tmpList[i];
        if X = '1' then
          continue
        else
        begin
          holdRelat := Piece(tmpList[i], U, 3);
          holdName := Piece(tmpList[i], U, 2);
          holdVStatus := Piece(tmpList[i], U, 4);
          holdCond := Piece(tmpList[i], U, 15);
          if aRelative = holdRelat then
            if aName = holdName then
              if aVStatus = holdVStatus then
                if aCond = holdCond then
                begin
                  if Not GetGlobalsInitialized then
                    Init_Global_Recs; // uFamHistoryGlobals

                  SetFirstName(holdName);
                  SetCondName(holdCond);
                  SetVitalStatus(holdVStatus);

                  SetRelationship(Piece(tmpList[i], U, 3));
                  SetAgeDeceased(Piece(tmpList[i], U, 5));
                  SetComments(Piece(tmpList[i], U, 6));
                  SetRelativeComments(Piece(tmpList[i], U, 6));
                  SetDiseaseComments(Piece(tmpList[i], U, 6));
                  SetRace(Piece(tmpList[i], U, 10));
                  SetEthnicity(Piece(tmpList[i], U, 11));
                  SetNoReply(Piece(tmpList[i], U, 12));
                  SetCurrentAge(Piece(tmpList[i], U, 12));
                  // SetCondIEN(aValue:Integer);
                  SetAgeAtDx(Piece(tmpList[i], U, 14));
                  SetJewishAncestor(Piece(tmpList[i], U, 5));
                  Result := True;
                  Break;
                end;
        end;
      end;
    end;
  finally
    tmpList.Free;
  end;
end;

function TfrmFamHistory.GetFilteredDiseaseList(aList: TStrings): TStrings;
var
  aLookat, aHoldCode, aKeepCond, aTemp, aFilterCode: string;
  i, f, ii: Integer;
  aPatientList, aFilters, aSelectedFilters: TStrings;
  ADiseaseCondMaster: TStrings;

begin
  ADiseaseCondMaster := TStringList.Create;
  aSelectedFilters := TStringList.Create;
  aFilters := TStringList.Create;
  ADiseaseCondMaster.Clear;
  aSelectedFilters.Clear;
  aFilters.Clear;

  aFilters.Assign(aList);//  --> user selected disease group(s)
  FastAssign(BuildDiseaseCondMaster, ADiseaseCondMaster);
  try
    // convert filter Group to Conditions from Disease Master
    begin
      for f := 0 to aFilters.Count - 1 do
      begin
        aFilterCode := Piece(aFilters[f], '^', 2);
        for i := 0 to ADiseaseCondMaster.Count - 1 do
        begin
          aTemp := Piece(ADiseaseCondMaster.Strings[i], '^', 2);
          aHoldCode := Piece(aTemp, ':', 2);
          if aFilterCode = aHoldCode then
          begin
            aKeepCond := Piece(ADiseaseCondMaster.Strings[i], '^', 3);
            aSelectedFilters.Add(aKeepCond);
          end;
        end;
         Result := aSelectedFilters;
    end;

    end;
  finally
//    aSelectedFilters.Free;
    aFilters.Free;
    ADiseaseCondMaster.Free;
  end;
end;

function TfrmFamHistory.BuildDiseaseCondMaster: TStrings;
var
  AGroups, aNewList: TStringList;
  AMasterDetail: TStrings;
  i, ii: Integer;
  AdisGrp, aCond: String;
begin
  aNewList := TStringList.Create;
  AGroups := TStringList.Create;
  AMasterDetail := TStringList.Create;
  aNewList.Clear;
  AGroups.Clear;
  AMasterDetail.Clear;

  FastAssign(GetFHDiseaseGrps, AGroups);

  for i := 0 to AGroups.Count - 1 do
  begin
    AdisGrp := AGroups[i];
    if Length(AdisGrp) > 0 then
    begin // get items for that group and add to list
      FastAssign(GetFHCDiseaseConditions(Piece(AdisGrp, '^', 2)), aNewList);
      for ii := 0 to aNewList.Count - 1 do
      begin
        aCond := aNewList[ii];
        AMasterDetail.Add(AdisGrp + ':' + aCond);
      end;
    end;
  end;
  Result := AMasterDetail;
end;

function TfrmFamHistory.GetFilterdRecs(aList: TStrings): TStrings;
var
  i, ii,iii: Integer;
  aCompareToCond, aKeyCond,x: String;
  aFilteredDisList, aPatHistList, aNewHistList: TStrings;
begin
  try
    aFilteredDisList := TStringList.Create;
    aFilteredDisList.Clear;
    aPatHistList := TStringList.Create;
    aPatHistList.Clear;
    aNewHistList := TStringList.Create;
    aNewHistList.Clear;
    // list of conditions used to filter History recs displayed
    aFilteredDisList.Assign(aList);
    // Patients total Fam History list to be filtered.
    FastAssign(GetAllFamilyHistoryRecords(Patient.DFN), aPatHistList);
    for i := 0 to aFilteredDisList.Count - 1 do
    begin
      aKeyCond := aFilteredDisList[i];
      for ii := 0 to aPatHistList.Count - 1 do
      begin
        aCompareToCond := Piece(aPatHistList[ii], '^', 15);
        if aKeyCond = aCompareToCond then
        begin
          aNewHistList.Add(aPatHistList[ii]);
        end;
      end;
      for iii := 0 to aNewHistList.Count-1 do
        x := aNewHistList.Strings[iii];
      Result.Assign(aNewHistList);
    end;
  finally
    aFilteredDisList.Free;
    aPatHistList.Free;
    aNewHistList.Free;
  end;

end;

function TfrmFamHistory.LoadFilterdRecs(aList: TStrings): boolean;
var
  i, r: Integer;
  X: string;
  aNewFHRec: TStrings;
begin
  Result := False;
  aNewFHRec := TStringList.Create;
  aNewFHRec.Clear;
  aNewFHRec.Assign(aList);
  try
    with sgfhist do
    begin
      if aNewFHRec.Count = 0 then
        exit;
      r := 0;
      RowCount := aNewFHRec.Count + 1;
      for i := 0 to aNewFHRec.Count - 1 do
      begin
        X := aNewFHRec[i];
        if X = '1' then
          continue
        else
        begin
          Cells[cRelatiive, r] := Piece(aNewFHRec[i], U, 3);
          Cells[cName, r] := Piece(aNewFHRec[i], U, 2);
          Cells[cVStat, r] := Piece(aNewFHRec[i], U, 4);
          Cells[cCurrAge, r] := Piece(aNewFHRec[i], U, 12);
          Cells[cHistOf, r] := Piece(aNewFHRec[i], U, 15);
          Cells[cAgeDx, r] := Piece(aNewFHRec[i], U, 14);
          Cells[cAgeDied, r] := Piece(aNewFHRec[i], U, 5);
          Cells[cComments, r] := Piece(aNewFHRec[i], U, 6);
          Cells[cEnteredBy, r] := Piece(aNewFHRec[i], U, 8);
          Cells[cDateMod, r] := Piece(aNewFHRec[i], U, 17);
          inc(r);
          sgfhist.RowCount := r;
        end;
      end;
      Result := True;
    end;
  finally
    aNewFHRec.Free;
  end;
end;

initialization

SpecifyFormIsNotADialog(TfrmFamHistory);

finalization
frmFamHistory.Release;

end.
