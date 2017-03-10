unit MainView;

interface

uses
  System.Classes,
  System.Actions,
  FMX.Graphics,
  FMX.ActnList,
  FMX.Forms,
  FMX.Edit,
  FMX.EditBox,
  FMX.NumberBox,
  FMX.StdCtrls,
  FMX.Controls,
  FMX.ListBox,
  FMX.Layouts,
  FMX.Controls.Presentation,
  FMX.MultiView,
  FMX.Types,
  FMX.StdActns,
  FMX.MediaLibrary.Actions,
  FMX.ImageLayout;

type
  TForm1 = class(TForm)
    MultiView1: TMultiView;
    btnDrawerView: TButton;
    ToolBar1: TToolBar;
    ListBox1: TListBox;
    ListBoxItem1: TListBoxItem;
    ListBoxItem2: TListBoxItem;
    ListBoxItem3: TListBoxItem;
    swBounceAnimation: TSwitch;
    swAutoHideScrollbars: TSwitch;
    swAnimateDecelerationRate: TSwitch;
    ListBoxItem4: TListBoxItem;
    swMouseWheelZoom: TSwitch;
    ListBoxItem5: TListBoxItem;
    edBounceElasticity: TNumberBox;
    ListBoxItem6: TListBoxItem;
    edImageScale: TNumberBox;
    ImageLayout1: TImageLayout;
    ActionList1: TActionList;
    OpenImageAction: TAction;
    btnClearImage: TSpeedButton;
    ClearImageAction: TAction;
    TakePhotoFromLibraryAction: TTakePhotoFromLibraryAction;
    TakePhotoFromCameraAction: TTakePhotoFromCameraAction;
    btnPictureFromMediaCamera: TButton;
    btnPictureFromMediaLibrary: TButton;
    procedure ImageLayout1ImageChanged(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure edBounceElasticityChange(Sender: TObject);
    procedure swBounceAnimationSwitch(Sender: TObject);
    procedure swAutoHideScrollbarsSwitch(Sender: TObject);
    procedure swAnimateDecelerationRateSwitch(Sender: TObject);
    procedure swMouseWheelZoomSwitch(Sender: TObject);
    procedure edImageScaleChange(Sender: TObject);
    procedure OpenImageActionExecute(Sender: TObject);
    procedure ClearImageActionExecute(Sender: TObject);
    procedure TakePhotoFromLibraryActionDidFinishTaking(Image: TBitmap);
    procedure TakePhotoFromCameraActionDidFinishTaking(Image: TBitmap);
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses
{$IFNDEF NEXTGEN}
  System.UITypes,
  FMX.Dialogs,
{$ENDIF}
  System.SysUtils;

procedure TForm1.FormCreate(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}

{$IFNDEF NEXTGEN}
  btnPictureFromMediaLibrary.Action := OpenImageAction;
{$ENDIF NEXTGEN}

  MultiView1.Mode := TMultiViewMode.Drawer;
end;

procedure TForm1.edImageScaleChange(Sender: TObject);
begin
  ImageLayout1.ImageScale := edImageScale.Value;
end;

procedure TForm1.ImageLayout1ImageChanged(Sender: TObject);
begin
  edImageScale.OnChange := nil;
  try
    edImageScale.Value := ImageLayout1.ImageScale;
  finally
    edImageScale.OnChange := edImageScaleChange;
  end;
end;

procedure TForm1.OpenImageActionExecute(Sender: TObject);
{$IFNDEF NEXTGEN}
var
  OpenDialog: TOpenDialog;
{$ENDIF NEXTGEN}
begin
{$IFNDEF NEXTGEN}
  OpenDialog := TOpenDialog.Create(nil);
  try
    OpenDialog.Filter := TBitmapCodecManager.GetFilterString;
    OpenDialog.Options := [TOpenOption.ofPathMustExist, TOpenOption.ofFileMustExist, TOpenOption.ofReadOnly];
    if OpenDialog.Execute then
      ImageLayout1.Image.LoadFromFile(OpenDialog.FileName);
  finally
    OpenDialog.Free;
  end;
{$ENDIF NEXTGEN}
end;

procedure TForm1.ClearImageActionExecute(Sender: TObject);
begin
  ImageLayout1.ClearImage;
end;

procedure TForm1.edBounceElasticityChange(Sender: TObject);
begin
  ImageLayout1.BounceElasticity := edBounceElasticity.Value;
end;

procedure TForm1.swBounceAnimationSwitch(Sender: TObject);
begin
  ImageLayout1.BounceAnimation := swBounceAnimation.IsChecked;
end;

procedure TForm1.swAutoHideScrollbarsSwitch(Sender: TObject);
begin
  ImageLayout1.AutoHideScrollbars := swAutoHideScrollbars.IsChecked;
end;

procedure TForm1.swAnimateDecelerationRateSwitch(Sender: TObject);
begin
  ImageLayout1.AnimateDecelerationRate := swAnimateDecelerationRate.IsChecked;
end;

procedure TForm1.swMouseWheelZoomSwitch(Sender: TObject);
begin
  ImageLayout1.MouseWheelZoom := swMouseWheelZoom.IsChecked;
end;

procedure TForm1.TakePhotoFromCameraActionDidFinishTaking(Image: TBitmap);
begin
  ImageLayout1.Image := Image;
end;

procedure TForm1.TakePhotoFromLibraryActionDidFinishTaking(Image: TBitmap);
begin
  ImageLayout1.Image := Image;
end;

end.
