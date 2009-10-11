{$ifdef Interface}
type
  TLispInterpreter = class
  private
    FEnv, FSEnv, QuoteSym, IfSym, LambdaSym, SetSym: LV;

    function EvalApplication(Code, Env: LV; Tail: Boolean; var Proc, Args: LV): LV;
    function ArgListUnique(Lst: LV): Boolean;
    function EvalExpr(Code, Env: LV; Tail: Boolean; var Proc, Args: LV): LV;
    function EvalCode(Code, Env: LV; Tail: Boolean; var Proc, Args: LV): LV;
    function LookupSymbol(Code, Env: LV): LV;       
    function ExpandArgs(Proc, Names, Values: LV): LV;
    function ExpandList(Lines: LV; SEnv: LV): LV;
  public
    { The global environment }
    procedure RegisterGlobal(Name: string; Val: LV); overload;
    procedure RegisterGlobal(Name, Val: LV); overload;
    procedure RegisterSyntax(Name: string; X: LV); overload;
    procedure RegisterSyntax(Name, X: LV); overload;
    function Defintions: string;

    { Syntactic Extensions }
    function Expand(Code: LV; SEnv: LV): LV;

    { The main job of the interpreter }
    function Eval(Code: LV; Env: LV): LV; overload;
    function Eval(Code: LV): LV; overload;
    function Apply(Proc, Args: LV): LV; overload;
    function Apply(Proc: LV; Args: array of LV): LV; overload;

    { Some high-level stuff }
    function EvalString(S: string): LV;
    procedure Load(Path: string);
    procedure REPL(Input, Output: LV);

    constructor Create(FullLoad: Boolean);
  end;
  
var
  LispPreludePath: string;

{$else}

{ TLispInterpreter }

function TLispInterpreter.EvalApplication(Code, Env: LV; Tail: Boolean; var Proc, Args: LV): LV;

  function ArgVal(Arg: LV): LV;
  begin
    Result := EvalCode(Arg, Env, False, Proc, Args);
    if Result is TLispMultipleValues then
    begin
      Result := TLispMultipleValues(Result).First;
    end;
  end;

var
  P, A, Cur: LV;
  Arg, Next: TLispPair;
begin
  P := EvalCode(LispCar(Code), Env, False, Proc, Args);
  
  Cur := LispCdr(Code);
  if Cur = LispEmpty then
  begin
    A := LispEmpty;
  end
  else 
  begin
    Arg := LispCons(ArgVal(LispCar(Cur)), LispEmpty);
    Cur := LispCdr(Cur);
    A := Arg;
    while Cur <> LispEmpty do
    begin
      Next := LispCons(ArgVal(LispCar(Cur)), LispEmpty);
      Arg.D := Next;
      Arg := Next;
      Cur := LispCdr(Cur);
    end;
  end;

  if Tail then
  begin
    Proc := P;
    Args := A;
  end
  else
  begin
    Result := Apply(P, A);
  end;
end;

function TLispInterpreter.ArgListUnique(Lst: LV): Boolean;
var
  A, AVal, B: LV;
begin
  A := Lst;
  if not (A is TLispPair) then
  begin
    Result := True;
    exit;
  end;
  while A <> LispEmpty do
  begin
    if not (A is TLispPair) then
    begin
      Result := True;
      exit;
    end;
    AVal := LispCar(A);
    B := LispCdr(A);
    while B <> LispEmpty do
    begin
      if B is TLispPair then
      begin
        if AVal = LispCar(B) then
        begin
          Result := False;
          exit;
        end;
        B := LispCdr(B);
      end
      else
      begin
        if AVal = B then
        begin
          Result := False;
          exit;
        end
        else
        begin
          B := LispEmpty;
        end;
      end;
    end;
    A := LispCdr(A);
  end;
  Result := True;
end;

function TLispInterpreter.EvalExpr(Code, Env: LV; Tail: Boolean; var Proc, Args: LV): LV;
var
  X, Binding, CProc, CArgs, CCode: LV;
begin
  { Primitive forms }
  X := LispCar(Code);
  if X = QuoteSym then
  begin
    Result := LispCar(LispCdr(Code));
  end
  else if X = IfSym then
  begin
    if LispIsTrue(EvalCode(LispRef(Code, 1), Env, False, Proc, Args)) then
    begin
      Result := EvalCode(LispRef(Code, 2), Env, Tail, Proc, Args);
    end
    else
    begin
      Result := EvalCode(LispRef(Code, 3), Env, Tail, Proc, Args);
    end;
  end
  else if X = LambdaSym then
  begin
    CProc := LispCdr(Code);
    CArgs := LispCar(CProc);
    CCode := LispCdr(CProc);
    if not ArgListUnique(CArgs) then
    begin
      raise ELispError.Create('arguments must be unique', Code);
    end;   
    Result := TLispClosure.Create('', CArgs, CCode, Env);
  end
  else if X = SetSym then
  begin
    Binding := LookupSymbol(LispRef(Code, 1), Env);
    TLispPair(Binding).D := EvalCode(LispRef(Code, 2), Env, False, Proc, Args);
    Result := LispVoid;
  end
  else
  begin
    Result := EvalApplication(Code, Env, Tail, Proc, Args);
  end;
end;

function TLispInterpreter.EvalCode(Code, Env: LV; Tail: Boolean; var Proc, Args: LV): LV;
var
  Binding: LV;
begin
  if Code is TLispPair then
  begin  
    Result := EvalExpr(Code, Env, Tail, Proc, Args);
  end
  else if Code is TLispSymbol then
  begin
    Binding := LookupSymbol(Code, Env);
    Result := LispCdr(Binding);
  end
  else
  begin
    Result := Code;
  end;
end;

function TLispInterpreter.LookupSymbol(Code, Env: LV): LV;
begin
  Result := LispAssoc(Code, Env);

  if (not LispIsTrue(Result)) and (Env <> FEnv) then
  begin
    Result := LispAssoc(Code, FEnv);
  end;

  if (not LispIsTrue(Result)) then
  begin
    raise ELispError.Create('unknown variable', Code);
  end;
end;

function TLispInterpreter.ExpandArgs(Proc, Names, Values: LV): LV;
var
  Head: LV;
begin
  if (Names = LispEmpty) and (Values <> LispEmpty) then
  begin
    raise ELispError.Create('too many arguments', Proc);
  end;

  if Names = LispEmpty then
  begin
    Result := LispEmpty;
  end
  else if Names is TLispPair then
  begin
    if Values = LispEmpty then
    begin
      raise ELispError.Create('not enough arguments', Proc);
    end;

    Head := LispCons(LispCar(Names), LispCar(Values));
    Result := LispCons(Head, ExpandArgs(Proc, LispCdr(Names), LispCdr(Values)));
  end
  else
  begin
    Result := LispCons(LispCons(Names, Values), LispEmpty);
  end;
end;

procedure TLispInterpreter.RegisterGlobal(Name: string; Val: LV);
begin
  RegisterGlobal(LispSymbol(Name), Val);
end;
  
procedure TLispInterpreter.RegisterGlobal(Name, Val: LV);
var
  Binding: LV;
begin
  if Val is TLispProcedure then
  begin
    Val := TLispProcedure(Val).WithName(LispToWrite(Name));
  end;
  Binding := LispCons(Name, Val);
  FEnv := LispCons(Binding, FEnv);
end;
  
procedure TLispInterpreter.RegisterSyntax(Name: string; X: LV);
begin
  RegisterSyntax(LispSymbol(Name), X);
end;

procedure TLispInterpreter.RegisterSyntax(Name, X: LV);
var
  Binding: LV;
begin
  Binding := LispCons(Name, X);
  FSEnv := LispCons(Binding, FSEnv);
end;

function TLispInterpreter.Defintions: string;
var
  Cur: LV;
begin
  Result := 'Variables:' + #10;
  Cur := FEnv;
  while Cur <> LispEmpty do
  begin
    Result := Result + LispToWrite(LispCar(Cur)) + #10;
    Cur := LispCdr(Cur);
  end;
end;

function TLispInterpreter.ExpandList(Lines: LV; SEnv: LV): LV;
var
  Cur: LV;
  This, Next: TLispPair;
begin
  if Lines = LispEmpty then
  begin
    Result := LispEmpty;
    exit;
  end;
  This := LispList([Expand(LispCar(Lines), SEnv)]);
  Result := This;
  Cur := LispCdr(Lines);
  while Cur <> LispEmpty do
  begin
    Next := LispList([Expand(LispCar(Cur), SEnv)]);
    This.D := Next;
    This := Next;
    Cur := LispCdr(Cur);
  end;
end;
  
function TLispInterpreter.Expand(Code, SEnv: LV): LV;
var
  X, Cur, Binding: LV;
begin
  if Code is TLispPair then
  begin
    X := LispCar(Code);
    if X = QuoteSym then
    begin
      Result := Code;
    end
    else if X = IfSym then
    begin
      Result := LispList([
        IfSym, 
        Expand(LispRef(Code, 1), SEnv), 
        Expand(LispRef(Code, 2), SEnv), 
        Expand(LispRef(Code, 3), SEnv)
      ]);
    end
    else if X = LambdaSym then
    begin
      try
        Cur := LispCdr(LispCdr(Code));
      except
        on ELispError do
        begin
          raise ELispError.Create('invalid lambda expression', Code);
        end;
      end;
      if Cur = LispEmpty then
      begin
        raise ELispError.Create('invalid lambda expression', Code);
      end;
      Result := LispCons(LambdaSym, LispCons(LispRef(Code, 1), ExpandList(Cur, SEnv)));
    end
    else if X = SetSym then
    begin
      Result := LispList([
        SetSym, 
        Expand(LispRef(Code, 1), SEnv), 
        Expand(LispRef(Code, 2), SEnv)
      ]);
    end
    else if X is TLispSymbol then
    begin
      Binding := LispAssoc(X, SEnv);
      if not LispIsTrue(Binding) then
      begin
        Binding := LispAssoc(X, FSEnv);
      end;
      if LispIsTrue(Binding) then
      begin
        Result := Expand(Apply(LispCdr(Binding), LispCdr(Code)), SEnv);
      end 
      else
      begin
        Result := ExpandList(Code, SEnv);      
      end;
    end
    else
    begin
      Result := ExpandList(Code, SEnv);
    end;
  end
  else
  begin
    Result := Code;
  end;
end;

function TLispInterpreter.Eval(Code, Env: LV): LV;
var
  DummyProc, DummyArgs: LV;
begin
  Result := EvalCode(Expand(Code, LispEmpty), Env, False, DummyProc, DummyArgs);
end;

function TLispInterpreter.Eval(Code: LV): LV;
begin
  Result := Eval(Code, LispEmpty);
end;
    
function TLispInterpreter.Apply(Proc, Args: LV): LV;
var
  Closure: TLispClosure;
  Primitive: TLispPrimitive;
  Cur, Env: LV;
begin
  repeat
    if Proc is TLispPrimitive then
    begin
      Primitive := TLispPrimitive(Proc);
      Result := Primitive.Exec(Args);
      Proc := nil;
    end
    else if Proc is TLispClosure then
    begin
      Closure := TLispClosure(Proc);
      Env := LispAppend(ExpandArgs(Proc, Closure.Args, Args), Closure.Env);
      Proc := nil;
      Cur := Closure.Code;
      Result := LispVoid;
      while Cur <> LispEmpty do
      begin
        if LispCdr(Cur) = LispEmpty then
        begin
          Result := EvalCode(LispCar(Cur), Env, True, Proc, Args);       
        end 
        else
        begin
          Result := EvalCode(LispCar(Cur), Env, False, Proc, Args);
        end;
        Cur := LispCdr(Cur);
      end;
    end
    else
    begin
      raise ELispError.Create('Not a procedure', Proc);
    end;
  until Proc = nil;
end;
    
function TLispInterpreter.Apply(Proc: LV; Args: array of LV): LV; 
begin
  Result := Apply(Proc, LispList(Args));
end;

function TLispInterpreter.EvalString(S: string): LV;
begin
  Result := Eval(LispReadString(S));
end;

procedure TLispInterpreter.Load(Path: string);
var
  F: LV;
begin
  F := LispInputFile(Path);
  while not LispEOF(F) do
  begin
    Eval(LispRead(F));
  end;
end;

procedure TLispInterpreter.REPL(Input, Output: LV);
var
  Result: LV;
begin
  while not LispEOF(Input) do
  begin
    try
      Result := Eval(LispRead(Input));
      if (Result <> LispEOFObject) and (Result <> LispVoid) then
      begin
        LispWrite(Result, Output);
        LispWriteChar(#10, Output);
      end;
    except
      on E: ELispError do
      begin
        LispWriteString('error: ', Output);
        LispWriteString(E.Message, Output);
        LispWriteChar(#10, Output);
      end;
    end;
  end;
end;

constructor TLispInterpreter.Create(FullLoad: Boolean);
begin
  FEnv := LispEmpty;
  FSEnv := LispEmpty;
  QuoteSym := LispSymbol('quote');
  IfSym := LispSymbol('if');
  LambdaSym := LispSymbol('lambda');
  SetSym := LispSymbol('set!');
  if FullLoad then
  begin
    RegisterPrimitives(Self);
    Load(LispPreludePath);
  end;
end;

procedure InitInterpreter;
begin
  LispPreludePath := './prelude.scm';
end;

{$endif}
