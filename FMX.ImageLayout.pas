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
{ TODO -cTImageLayout : DoubleTap Gesture isn't recognized by FMX }
{ TODO -cTImageLayout : Implement Zoom Gesture "Direction", that is, zoom to the point where
                        the gesture is located }

{$SCOPEDENUMS ON}

  /// <summary> Determines how to calculate the ImageScale property </summary>
  TImageChangeAction = (
    /// <summary> The ImageScale will be set to the best fit value. See TImageLayout.BestFit </summary>
    RecalcBestFit,
    /// <summary> The ScaleImage remains unchanged; if a new image is set, the current ImageScale is applied </summary>
    PreserveImageScale
  );

  /// <summary> Determines what type of event fired the TImageChangeEvent event handler </summary>
  TImageChangeReason = (
    /// <summary> The TImageLayout was resized, for example, when the Parent size changes </summary>
    LayoutResized,
    /// <summary> The Image property changed </summary>
    ImageChanged
  );

{$SCOPEDENUMS OFF}

  /// <summary> Fired when the Image changes. Allows to set how to calculate the ImageScale property </summary>
  TImageChangeEvent = procedure(Sender: TObject; const Reason: TImageChangeReason; var Action: TImageChangeAction) of object;

{$REGION 'TCustomImageLayout'}
  /// <summary> Layout that displays an Image and implements Zoom and Pan Gestures </summary>
  TCustomImageLayout = class(TControl)
  private const
    AbsoluteMinScale = 0.01;
    AbsoluteMaxScale = 20.0;
  private
    FScrollBox: TScrollBox;
    FImageSource: TTextureMaterialSource;
    FImageSurface: TLayout;
    FImageOriginalSize: TPointF;
    FImageScale: Single;
    FImageOriginalScale: Single;
    FZoomStartDistance: Integer;
    FMouseWheelZoom: Boolean;
    FOnImageChanged: TImageChangeEvent;
    FBounceAnimationDisableCount: Integer;
    FBounceAnimationPropertyValue: Boolean;
    FIsZooming: Boolean;

    function GetAnimateDecelerationRate: Boolean;
    function GetAutoHideScrollbars: Boolean;
    function GetBounceAnimation: Boolean;
    function GetBounceElasticity: Double;
    function GetImage: TBitmap;
    function GetAniCalculations: TAniCalculations;
    function GetIsZoomed: Boolean;

    procedure SetAnimateDecelerationRate(const Value: Boolean);
    procedure SetAutoHideScrollbars(const Value: Boolean);
    procedure SetBounceAnimation(const Value: Boolean);
    procedure SetBounceElasticity(const Value: Double);
    procedure SetImage(const Value: TBitmap);
    procedure SetImageScale(const Value: Single);
    procedure SetMouseWheelZoom(const Value: Boolean);
    procedure SetOnImageChanged(const Value: TImageChangeEvent);

    procedure InitImageSurface;
    procedure InitScrollBox;
    procedure InitInertialMovement;

    procedure ImageChanged(Sender: TObject);
    procedure ImageSurfacePainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);

    /// <summary> Disables ScrollBox touch tracking </summary>
    procedure DisableTouchTracking;
    /// <summary> Enables ScrollBox touch tracking </summary>
    procedure EnableTouchTracking;
    /// <summary> Enables/Disables TouchTracking if appropiate </summary>
    /// <remarks> TouchTracking is disabled if a Zoom Gesture is in process or if the image fits in the
    /// layout, in which case the scrolling is not necessary </remarks>
    procedure SetTouchTrackingToAppropiate;
  protected const
    DefaultMouseWheelZoom = True;
    DefaultAnimateDecelerationRate = True;
    DefaultAutoHideScrollbars = True;
    DefaultBounceAnimation = True;
    DefaultBounceElasticity = 100;
    DefaultImageScale = 1.0;
  protected
    /// <summary> DisableBounceAnimation and RestoreBounceAnimation are similar to BeginUpdate and EndUpdate,
    /// but the operate on the BounceAnimation property. There moments when the scaling of the image, like  while
    /// doing a zoom gesture or mouse wheeling, that the BounceAnimation better remains disabled </summary>
    procedure DisableBounceAnimation;
    /// <summary> DisableBounceAnimation and RestoreBounceAnimation are similar to BeginUpdate and EndUpdate,
    /// but the operate on the BounceAnimation property. There moments when the scaling of the image, like  while
    /// doing a zoom gesture or mouse wheeling, that the BounceAnimation better remains disabled </summary>
    /// <summary> A call RestoreBounceAnimation restores the BounceAnimation property Value if every call
    /// to DisableBounceAnimation was paired with a call to RestoreBounceAnimation </summary>
    procedure RestoreBounceAnimation;

    procedure Loaded; override;
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean); override;
    procedure DoGesture(const EventInfo: TGestureEventInfo; var Handled: Boolean); override;

    procedure Change(const Reason: TImageChangeReason); virtual;
    procedure HandleZoom(const EventInfo: TGestureEventInfo; var Handled: Boolean); virtual;
    procedure HandleDoubleTap(const EventInfo: TGestureEventInfo; var Handled: Boolean); virtual;

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
    /// <summary> The Size of the Image without any scaling applied </summary>
    property ImageOriginalSize: TPointF read FImageOriginalSize;
  public
    constructor Create(AOwner: TComponent); override;
    /// <summary> Calculates the most appropiate ImageScale value </summary>
    procedure BestFit;
    /// <summary> Removes the Image and displays an empty Layout </summary>
    procedure ClearImage;
    /// <summary> Returns True if a Zooming Gesture is in process; False otherwise </summary>
    property IsZooming: Boolean read FIsZooming;
    /// <summary> Returns True if the Image has been zoomed in or out; False otherwise </summary>
    property IsZoomed: Boolean read GetIsZoomed;
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
    /// <summary> Fired when the Image changes. Allows to set how to calculate the ImageScale property </summary>
    property OnImageChanged: TImageChangeEvent read FOnImageChanged write SetOnImageChanged;
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
  System.SysUtils,
  System.UITypes,
  System.Math;

{$REGION 'TCustomImageLayout'}

constructor TCustomImageLayout.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FImageSource := TTextureMaterialSource.Create(Self);
  FBounceAnimationDisableCount := 0;
  FBounceAnimationPropertyValue := False;
  FIsZooming := False;
  CanParentFocus := True;
  HitTest := True;
  MouseWheelZoom := DefaultMouseWheelZoom;
  Touch.InteractiveGestures := [TInteractiveGesture.Zoom, TInteractiveGesture.Pan, TInteractiveGesture.DoubleTap];
  InitScrollBox;
  InitImageSurface;
  InitInertialMovement;
  SetAcceptsControls(False);
  Image.OnChange := ImageChanged;
end;

procedure TCustomImageLayout.DisableBounceAnimation;
begin
  if FBounceAnimationDisableCount = 0 then
    FBounceAnimationPropertyValue := BounceAnimation;

  Inc(FBounceAnimationDisableCount)
end;

procedure TCustomImageLayout.RestoreBounceAnimation;
begin
  FBounceAnimationDisableCount := System.Math.Min(FBounceAnimationDisableCount - 1, 0);
  if FBounceAnimationDisableCount = 0 then
    BounceAnimation := FBounceAnimationPropertyValue;
end;

procedure TCustomImageLayout.Change(const Reason: TImageChangeReason);
var
  ImageChangeAction: TImageChangeAction;
begin
  ImageChangeAction := TImageChangeAction.RecalcBestFit;

  if Assigned(FOnImageChanged) then
    FOnImageChanged(Self, Reason, ImageChangeAction);

  case ImageChangeAction of
    TImageChangeAction.RecalcBestFit: BestFit;
    TImageChangeAction.PreserveImageScale: Repaint;
  end;
end;

procedure TCustomImageLayout.Paint;
begin
  inherited Paint;
  if (csDesigning in ComponentState) and not Locked then
    DrawDesignBorder;
end;

procedure TCustomImageLayout.Resize;
begin
  inherited Resize;
  ScrollBox.Size.Assign(Size);
  Change(TImageChangeReason.LayoutResized);
end;

procedure TCustomImageLayout.Loaded;
begin
  inherited Loaded;
  BestFit;
end;

procedure TCustomImageLayout.MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  if MouseWheelZoom then
  begin
    DisableBounceAnimation;
    try
      ImageScale := ImageScale + ((WheelDelta * ImageScale) / PointF(Width, Height).Length);
      Handled := True;
    finally
      RestoreBounceAnimation;
    end;
  end
  else
    Handled := False;
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

procedure TCustomImageLayout.InitImageSurface;
begin
  FImageSurface := TLayout.Create(Self);
  ImageSurface.Parent := ScrollBox;
  ImageSurface.Align := TAlignLayout.Center;
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
    DisableTouchTracking;
  finally
    AniCalculations.EndUpdate;
  end;
end;

{$ENDREGION}

{$REGION 'Gesture handling'}

procedure TCustomImageLayout.DoGesture(const EventInfo: TGestureEventInfo; var Handled: Boolean);
begin
  case EventInfo.GestureID of
    igiZoom: HandleZoom(EventInfo, Handled);
    igiDoubleTap: HandleDoubleTap(EventInfo, Handled);
  else
    inherited DoGesture(EventInfo, Handled);
  end;
end;

procedure TCustomImageLayout.HandleZoom(const EventInfo: TGestureEventInfo; var Handled: Boolean);
var
  S: Single;
begin
  if TInteractiveGestureFlag.gfBegin in EventInfo.Flags then
  begin
    FIsZooming := True;
    DisableBounceAnimation;
    PriorZoomDistance := EventInfo.Distance;
    Handled := True;
  end;

  if not((TInteractiveGestureFlag.gfBegin in EventInfo.Flags) or
         (TInteractiveGestureFlag.gfEnd in EventInfo.Flags)) then
  begin
    S := ((EventInfo.Distance - PriorZoomDistance) * ImageScale) / (PointF(Width, Height).Length * 0.35);
    PriorZoomDistance := EventInfo.Distance;
    ImageScale := ImageScale + S;
    Handled := True;
  end;

  if TInteractiveGestureFlag.gfEnd in EventInfo.Flags then
  begin
    FIsZooming := False;
    RestoreBounceAnimation;
    SetTouchTrackingToAppropiate;
    Handled := True;
  end;
end;

procedure TCustomImageLayout.HandleDoubleTap(const EventInfo: TGestureEventInfo; var Handled: Boolean);
begin
  if IsZoomed then
    ImageScale := FImageOriginalScale
  else
    ImageScale := ImageScale * 1.50;
end;

{$ENDREGION}

{$REGION 'Controls Callbacks'}

procedure TCustomImageLayout.ImageChanged(Sender: TObject);
begin
  FImageOriginalSize := PointF(Image.Width, Image.Height);
  if FImageOriginalSize.IsZero then
    FImageOriginalSize := PointF(Width, Height);

  Change(TImageChangeReason.ImageChanged);
end;

procedure TCustomImageLayout.ImageSurfacePainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  ImageRect: TRectF;
begin
  ImageRect := RectF(0, 0, ImageOriginalSize.X, ImageOriginalSize.Y);
  ImageSurface.Canvas.DrawBitmap(Image, ImageRect, ARect, 1);
end;

{$ENDREGION}

{$REGION 'Image Handling'}

procedure TCustomImageLayout.BestFit;
var
  ScrollBoxRect, R: TRectF;
  ImageScaleRatio: Single;
begin
  ScrollBoxRect := ScrollBox.BoundsRect;
  R := RectF(0, 0, FImageOriginalSize.X, FImageOriginalSize.Y);

  try
    R.FitInto(ScrollBoxRect, ImageScaleRatio);
    FImageOriginalScale := 1 / ImageScaleRatio;
    ImageScale := FImageOriginalScale;
  except
    on EInvalidOp do
      ImageScale := 1;
  end;
end;

procedure TCustomImageLayout.SetImageScale(const Value: Single);
var
  PriorViewportPositionF, C: TPointF;
  PriorImageScale, NewImageScale: Single;
begin
  DisableBounceAnimation;
  try
    NewImageScale := Min(Max(Value, AbsoluteMinScale), AbsoluteMaxScale);
    PriorImageScale := FImageScale;
    FImageScale := NewImageScale;

    if PriorImageScale <> 0 then
      PriorImageScale := FImageScale / PriorImageScale
    else
      PriorImageScale := FImageScale;

    C := PointF(ScrollBox.Width, ScrollBox.Height);
    PriorViewportPositionF := AniCalculations.ViewportPositionF;
    ImageSurface.Size.Size := PointF(ImageOriginalSize.X * FImageScale, ImageOriginalSize.Y * FImageScale);
    PriorViewportPositionF := PriorViewportPositionF + (C * 0.5);

    ScrollBox.Content.BeginUpdate;
    try
      ScrollBox.RealignContent;
      AniCalculations.ViewportPositionF := (PriorViewportPositionF * PriorImageScale) - (C * 0.5);
    finally
      ScrollBox.Content.EndUpdate;
    end;

    SetTouchTrackingToAppropiate;
  finally
    RestoreBounceAnimation;
  end;
end;

procedure TCustomImageLayout.ClearImage;
begin
  Image.Clear(TAlphaColorRec.Null);
end;

{$ENDREGION}

{$REGION 'AniCalculations'}

procedure TCustomImageLayout.SetTouchTrackingToAppropiate;
begin
  if IsZooming then
  begin
    DisableTouchTracking;
    Exit;
  end;

  if (System.Math.CompareValue(ImageSurface.Size.Width, Width) = GreaterThanValue) or
     (System.Math.CompareValue(ImageSurface.Size.Height, Height) = GreaterThanValue) then
    EnableTouchTracking
  else
    DisableTouchTracking;
end;

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
  if FBounceAnimationDisableCount = 0 then
    AniCalculations.BoundsAnimation := Value;
end;

procedure TCustomImageLayout.SetBounceElasticity(const Value: Double);
begin
  AniCalculations.Elasticity := Value;
end;

{$ENDREGION}

procedure TCustomImageLayout.SetImage(const Value: TBitmap);
begin
  ImageSource.Texture.Assign(Value);
end;

function TCustomImageLayout.GetImage: TBitmap;
begin
  Result := ImageSource.Texture;
end;

function TCustomImageLayout.GetIsZoomed: Boolean;
begin
  Result := not System.Math.SameValue(FImageOriginalScale, FImageScale);
end;

procedure TCustomImageLayout.SetMouseWheelZoom(const Value: Boolean);
begin
  FMouseWheelZoom := Value;
end;

procedure TCustomImageLayout.SetOnImageChanged(const Value: TImageChangeEvent);
begin
  FOnImageChanged := Value;
end;

{$ENDREGION}

procedure Register;
begin
  RegisterComponents('Layouts', [TImageLayout]);
end;

end.
