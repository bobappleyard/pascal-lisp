{$ifdef Interface}
type
  TLispProcedure = class(LV)
  protected
    FName: string;
  public
    function WithName(AName: string): LV; virtual;
    property Name: string read FName;
  end;

{ Primitives }

type
  TLispPrimitiveFunc = function(Args: LV): LV;
  TLispPrimitiveMethod = function(Args: LV): LV of object;

  TLispPrimitive = class(TLispProcedure)
  private
    FImpl: TLispPrimitiveFunc;
  public
    function ToWrite: string; override;
    function WithName(AName: string): LV; override;
    function Exec(Args: LV): LV; virtual;
    constructor Create(AImpl: TLispPrimitiveFunc); overload;
    constructor Create(AName: string; AImpl: TLispPrimitiveFunc); overload;
  end;

  TLispObjectPrimitive = class(TLispPrimitive)
  private
    FImpl: TLispPrimitiveMethod;
  public
    function WithName(AName: string): LV; override;
    function Exec(Args: LV): LV; override;
    constructor Create(AImpl: TLispPrimitiveMethod); overload;
    constructor Create(AName: string; AImpl: TLispPrimitiveMethod); overload;
  end;
  
function LispPrimitive(Impl: TLispPrimitiveFunc): LV; overload;
function LispPrimitive(Impl: TLispPrimitiveMethod): LV; overload;
  
{ Closures (interpreted by the library) }  

type
  TLispClosure = class(TLispProcedure)
  private
    FCode, FArgs, FEnv: LV;
  public
    property Code: LV read FCode;
    property Args: LV read FArgs;
    property Env: LV read FEnv;

    function ToWrite: string; override;
    function WithName(AName: string): LV; override;
    constructor Create(AName: string; AArgs, ACode, AEnv: LV);
  end;
  
{$else}

{ TLispProcedure }

function TLispProcedure.WithName(AName: string): LV;
var
  P: TLispProcedure;
begin
  P := TLispProcedure.Create;
  P.FName := AName;
  Result := P;
end;

{ TLispPrimitive }

function TLispPrimitive.ToWrite: string;
begin
  Result := '#<primitive ' + FName + '>';
end;

function TLispPrimitive.WithName(AName: string): LV;
begin
  Result := TLispPrimitive.Create(AName, FImpl);
end;

function TLispPrimitive.Exec(Args: LV): LV;
begin
  Result := FImpl(Args);
end;

constructor TLispPrimitive.Create(AImpl: TLispPrimitiveFunc);
begin
  FName := '';
  FImpl := AImpl;
end;

constructor TLispPrimitive.Create(AName: string; AImpl: TLispPrimitiveFunc);
begin
  FName := AName;
  FImpl := AImpl;
end;

function LispPrimitive(Impl: TLispPrimitiveFunc): LV;
begin
  Result := TLispPrimitive.Create(Impl);
end;

{ TLispObjectPrimitive }

function TLispObjectPrimitive.Exec(Args: LV): LV; 
begin
  Result := FImpl(Args);
end;

function TLispObjectPrimitive.WithName(AName: string): LV;
begin
  Result := TLispObjectPrimitive.Create(AName, FImpl);
end;

constructor TLispObjectPrimitive.Create(AImpl: TLispPrimitiveMethod);
begin
  FName := '';
  FImpl := AImpl;
end;

constructor TLispObjectPrimitive.Create(AName: string; AImpl: TLispPrimitiveMethod);
begin
  FName := AName;
  FImpl := AImpl;
end;

function LispPrimitive(Impl: TLispPrimitiveMethod): LV; 
begin
  Result := TLispObjectPrimitive.Create(Impl);
end;

{ TLispClosure }

function TLispClosure.ToWrite: string;
var
  N: string;
begin
  if FName = '' then
  begin
    N := '';
  end
  else
  begin
    N := FName + ' ';
  end;

  Result := '#<closure ' + N + LispToWrite(Args) + '>';
end;

function TLispClosure.WithName(AName: string): LV;
begin
  Result := TLispClosure.Create(AName, Args, Code, Env);
end;

constructor TLispClosure.Create(AName: string; AArgs, ACode, AEnv: LV);
begin
  FName := AName;
  FArgs := AArgs;
  FCode := ACode;
  FEnv := AEnv;
end;

{$endif}
