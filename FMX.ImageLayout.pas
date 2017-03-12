unit FMX.ImageLayout;

interface

uses
  System.Classes,
  System.Types,
  FMX.Graphics,
  FMX.Types,
  FMX.Controls,
  FMX.Layouts,
  FMX.MaterialSources,
  FMX.InertialMovement;

type
{$REGION 'TCustomImageLayout'}
  /// <summary> Layout that displays an Image and implements Zoom and Pan Gestures </summary>
  TCustomImageLayout = class(TControl)
  private
    FScrollBox: TScrollBox;
    FImageSource: TTextureMaterialSource;
    FImageSurface: TLayout;
    FImageOriginalSize: TPointF;
    FImageScale: Single;
    FZoomStartDistance: Integer;
    FMouseWheelZoom: Boolean;
    FOnImageChanged: TNotifyEvent;

    function GetAnimateDecelerationRate: Boolean;
    function GetAutoHideScrollbars: Boolean;
    function GetBounceAnimation: Boolean;
    function GetBounceElasticity: Double;
    function GetImage: TBitmap;
    function GetAniCalculations: TAniCalculations;

    procedure SetAnimateDecelerationRate(const Value: Boolean);
    procedure SetAutoHideScrollbars(const Value: Boolean);
    procedure SetBounceAnimation(const Value: Boolean);
    procedure SetBounceElasticity(const Value: Double);
    procedure SetImage(const Value: TBitmap);
    procedure SetImageScale(const Value: Single);
    procedure SetMouseWheelZoom(const Value: Boolean);
    procedure SetOnImageChanged(const Value: TNotifyEvent);

    procedure InitImageSurface;
    procedure InitScrollBox;
    procedure InitInertialMovement;

    procedure ImageChanged(Sender: TObject);
    procedure ImageSurfacePainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);

    procedure CalcImageSize;
    /// <summary> Disables ScrollBox touch tracking </summary>
    procedure DisableTouchTracking;
    /// <summary> Enables ScrollBox touch tracking </summary>
    procedure EnableTouchTracking;
  protected const
    DefaultMouseWheelZoom = True;
    DefaultAnimateDecelerationRate = True;
    DefaultAutoHideScrollbars = True;
    DefaultBounceAnimation = True;
    DefaultBounceElasticity = 100;
    DefaultImageScale = 1.0;
  protected
    procedure Loaded; override;
    procedure Paint; override;
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean); override;
    procedure DoGesture(const EventInfo: TGestureEventInfo; var Handled: Boolean); override;

    procedure Change; virtual;
    procedure HandlePan(const EventInfo: TGestureEventInfo); virtual;
    procedure HandleZoom(const EventInfo: TGestureEventInfo); virtual;

    /// <summary> Container for the TBitmap we're drawing </summary>
    property ImageSource: TTextureMaterialSource read FImageSource;
    /// <summary> Layout where the Image is drawn </summary>
    property ImageSurface: TLayout read FImageSurface;
    /// <summary> Scrollbox that handles the Panning Gesture </summary>
    property ScrollBox: TScrollBox read FScrollBox;
    /// <summary> AniCalculations from ScrollBox component </summary>
    property AniCalculations: TAniCalculations read GetAniCalculations;
    /// <summary> The last stored TGestureEventInfo.Distance on a Zoom Gesture Event </summary>
    property PriorZoomDistance: Integer read FZoomStartDistance write FZoomStartDistance;
    property ImageOriginalSize: TPointF read FImageOriginalSize;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ClearImage;
    /// <summary> Determines whether the mouse scroll should trigger a Zoom Gesture Event </summary>
    /// <remarks> Only works on Desktop </remarks>
    property MouseWheelZoom: Boolean read FMouseWheelZoom write SetMouseWheelZoom;
    /// <summary> Specifies whether the inertial movement shoud take into account the DecelerationRate </summary>
    property AnimateDecelerationRate: Boolean read GetAnimateDecelerationRate write SetAnimateDecelerationRate;
    /// <summary> Hides scrollbars when inertial is stopped; Shows them when it starts, and when it ends,
    /// gradually hide them </summary>
    property AutoHideScrollbars: Boolean read GetAutoHideScrollbars write SetAutoHideScrollbars;
    /// <summary> Determines whether a corner of the scrolling viewport can be dragged inside the visible area </summary>
    property BounceAnimation: Boolean read GetBounceAnimation write SetBounceAnimation;
    /// <summary> Velocity of the BounceAnimation </summary>
    property BounceElasticity: Double read GetBounceElasticity write SetBounceElasticity;
    /// <summary> The Image displayed by the control </summary>
    property Image: TBitmap read GetImage write SetImage;
    /// <summary> Scale applied to the image; the higher the value, more zoom is applied to the image </summary>
    property ImageScale: Single read FImageScale write SetImageScale;
    /// <summary> Fired when the Image or the ImageScale properties are changed </summary>
    property OnImageChanged: TNotifyEvent read FOnImageChanged write SetOnImageChanged;
  end;
{$ENDREGION}

{$REGION 'TImageLayout'}
  TImageLayout = class(TCustomImageLayout)
  published
    property Align;
    property Visible;
    property MouseWheelZoom;
    property AnimateDecelerationRate;
    property AutoHideScrollbars;
    property BounceAnimation;
    property BounceElasticity;
    property Image;
    property ImageScale;
    property OnImageChanged;
  end;
{$ENDREGION}

procedure Register;

implementation

uses
  System.UITypes,
  System.Math;

{$REGION 'TCustomImageLayout'}

constructor TCustomImageLayout.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FImageSource := TTextureMaterialSource.Create(Self);
  CanParentFocus := True;
  HitTest := True;
  MouseWheelZoom := DefaultMouseWheelZoom;
  Touch.InteractiveGestures := [TInteractiveGesture.Zoom, TInteractiveGesture.Pan];
  InitScrollBox;
  InitImageSurface;
  InitInertialMovement;
  SetAcceptsControls(False);
  Image.OnChange := ImageChanged;
end;

procedure TCustomImageLayout.Paint;
begin
  inherited Paint;
  if (csDesigning in ComponentState) and not Locked then
    DrawDesignBorder;
end;

procedure TCustomImageLayout.Change;
begin
  if Assigned(FOnImageChanged) then
    FOnImageChanged(Self);
end;

procedure TCustomImageLayout.ClearImage;
begin
  Image.Clear(TAlphaColorRec.Null);
end;

{$REGION 'Private fields initialization'}

procedure TCustomImageLayout.InitScrollBox;
begin
  FScrollBox := TScrollBox.Create(Self);
  ScrollBox.Parent := Self;
  ScrollBox.ShowScrollBars := True;
  ScrollBox.Align := TAlignLayout.Client;
  ScrollBox.DisableMouseWheel := True;
  ScrollBox.Locked := True;
  ScrollBox.Stored := False;
  ScrollBox.Touch.InteractiveGestures := [];
end;

procedure TCustomImageLayout.Loaded;
begin
  inherited Loaded;
  CalcImageSize;
end;

procedure TCustomImageLayout.InitImageSurface;
begin
  FImageSurface := TLayout.Create(Self);
  ImageSurface.Parent := ScrollBox;
  ImageSurface.Position.Point := TPointF.Zero;
  ImageSurface.Locked := True;
  ImageSurface.Stored := False;
  ImageSurface.HitTest := False;
  ImageSurface.OnPainting := ImageSurfacePainting;
end;

procedure TCustomImageLayout.InitInertialMovement;
begin
  AniCalculations.BeginUpdate;
  try
    AniCalculations.Averaging := True;
    AnimateDecelerationRate:= DefaultAnimateDecelerationRate;
    BounceAnimation := DefaultBounceAnimation;
    AutoHideScrollbars := DefaultAutoHideScrollbars;
    BounceElasticity := DefaultBounceElasticity;
    EnableTouchTracking;
  finally
    AniCalculations.EndUpdate;
  end;
end;

{$ENDREGION}

{$REGION 'Gesture handling'}

procedure TCustomImageLayout.DoGesture(const EventInfo: TGestureEventInfo; var Handled: Boolean);
begin
  Handled := True;
  case EventInfo.GestureID of
    igiPan: HandlePan(EventInfo);
    igiZoom: HandleZoom(EventInfo);
  else
    inherited DoGesture(EventInfo, Handled);
  end;
end;

procedure TCustomImageLayout.HandlePan(const EventInfo: TGestureEventInfo);
begin
  EnableTouchTracking;
end;

procedure TCustomImageLayout.HandleZoom(const EventInfo: TGestureEventInfo);
var
  S: Single;
begin
  DisableTouchTracking;

  if TInteractiveGestureFlag.gfBegin in EventInfo.Flags then
    PriorZoomDistance := EventInfo.Distance;

  if not((TInteractiveGestureFlag.gfBegin in EventInfo.Flags) or
         (TInteractiveGestureFlag.gfEnd in EventInfo.Flags)) then
  begin
    S := ((EventInfo.Distance - PriorZoomDistance) * ImageScale) / PointF(Width, Height).Length;
    PriorZoomDistance := EventInfo.Distance;
    ImageScale := ImageScale + S;
  end;
end;

{$ENDREGION}

{$REGION 'Controls Callbacks'}

procedure TCustomImageLayout.ImageChanged(Sender: TObject);
begin
  CalcImageSize;
end;

procedure TCustomImageLayout.ImageSurfacePainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
  ImageSurface.Canvas.DrawBitmap(Image, RectF(0, 0, ImageOriginalSize.X, ImageOriginalSize.Y), ARect, 1);
end;

procedure TCustomImageLayout.MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
var
  BounceAnimationValue: Boolean;
begin
  if MouseWheelZoom then
  begin
    BounceAnimationValue := BounceAnimation;
    try
      BounceAnimation := False;
      ImageScale := ImageScale + ((WheelDelta * ImageScale) / PointF(Width, Height).Length);
      Handled := True;
    finally
      BounceAnimation := BounceAnimationValue;
    end;
  end
  else
    Handled := False;
end;

{$ENDREGION}

{$REGION 'Image Handling'}

procedure TCustomImageLayout.CalcImageSize;
var
  R: TRectF;
  ImageScaleRatio: Single;
begin
  FImageOriginalSize := PointF(Image.Width, Image.Height);
  if FImageOriginalSize.IsZero then
    FImageOriginalSize := PointF(Width, Height);

  R := RectF(0, 0, FImageOriginalSize.X, FImageOriginalSize.Y);
  R.FitInto(ScrollBox.BoundsRect, ImageScaleRatio);
  ImageScale := 1 / ImageScaleRatio;
end;

procedure TCustomImageLayout.SetImage(const Value: TBitmap);
begin
  ImageSource.Texture.Assign(Value);
end;

procedure TCustomImageLayout.SetImageScale(const Value: Single);
const
  MinScale = 0.01;
  MaxScale = 20.0;
var
  PriorViewportPositionF, C: TPointF;
  PriorImageScale, NewImageScale: Single;
begin
  NewImageScale := Min(Max(Value, MinScale), MaxScale);
  PriorImageScale := FImageScale;
  FImageScale := NewImageScale;
  if PriorImageScale <> 0 then
    PriorImageScale := FImageScale / PriorImageScale
  else
    PriorImageScale := FImageScale;

  C := PointF(ScrollBox.Width, ScrollBox.Height);
  PriorViewportPositionF := AniCalculations.ViewportPositionF;

  ImageSurface.BeginUpdate;
  try
    ImageSurface.Width := ImageOriginalSize.X * FImageScale;
    ImageSurface.Height := ImageOriginalSize.Y * FImageScale;
  finally
    ImageSurface.EndUpdate;
  end;

  PriorViewportPositionF := PriorViewportPositionF + (C * 0.5);
  ScrollBox.Content.BeginUpdate;
  try
    ScrollBox.RealignContent;
    AniCalculations.ViewportPositionF := (PriorViewportPositionF * PriorImageScale) - (C * 0.5);
  finally
    ScrollBox.Content.EndUpdate;
  end;

  Change;
end;

{$ENDREGION}

{$REGION 'AniCalculations'}

procedure TCustomImageLayout.DisableTouchTracking;
begin
  AniCalculations.TouchTracking := [];
end;

procedure TCustomImageLayout.EnableTouchTracking;
begin
  AniCalculations.TouchTracking := [ttVertical, ttHorizontal];
end;

function TCustomImageLayout.GetAniCalculations: TAniCalculations;
begin
  Result := ScrollBox.AniCalculations;
end;

function TCustomImageLayout.GetAnimateDecelerationRate: Boolean;
begin
  Result := AniCalculations.Animation;
end;

function TCustomImageLayout.GetAutoHideScrollbars: Boolean;
begin
  Result := AniCalculations.AutoShowing;
end;

function TCustomImageLayout.GetBounceAnimation: Boolean;
begin
  Result := AniCalculations.BoundsAnimation;
end;

function TCustomImageLayout.GetBounceElasticity: Double;
begin
  Result := AniCalculations.Elasticity;
end;

procedure TCustomImageLayout.SetAnimateDecelerationRate(const Value: Boolean);
begin
  AniCalculations.Animation := Value;
end;

procedure TCustomImageLayout.SetAutoHideScrollbars(const Value: Boolean);
begin
  AniCalculations.AutoShowing := Value;
end;

procedure TCustomImageLayout.SetBounceAnimation(const Value: Boolean);
begin
  AniCalculations.BoundsAnimation := Value;
end;

procedure TCustomImageLayout.SetBounceElasticity(const Value: Double);
begin
  AniCalculations.Elasticity := Value;
end;

{$ENDREGION}

function TCustomImageLayout.GetImage: TBitmap;
begin
  Result := ImageSource.Texture;
end;

procedure TCustomImageLayout.SetMouseWheelZoom(const Value: Boolean);
begin
  FMouseWheelZoom := Value;
end;

procedure TCustomImageLayout.SetOnImageChanged(const Value: TNotifyEvent);
begin
  FOnImageChanged := Value;
end;

{$ENDREGION}

procedure Register;
begin
  RegisterComponents('Layouts', [TImageLayout]);
end;

end.
