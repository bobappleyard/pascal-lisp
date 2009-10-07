interface

uses
  LispTypes;

type
  TLispInterpreter = class
  private
    FEnv: LV;

    function EvalApplication(Code, Env: LV): LV;
    function EvalExpr(Code, Env: LV): LV;
    function LookupSymbol(Code, Env: LV): LV;       
  public
    function Eval(Code, Env: LV): LV;
    function Apply(Proc, Args: LV): LV;

    constructor Create(AEnv: LV);
  end;


implementation

{ TLispInterpreter }

function TLispInterpreter.EvalApplication(Code, Env: LV): LV;
var
  Proc, Args, Cur: LV;
  Head, Arg: TLispPair;
begin
  Proc := Eval(LispCar(Code), Env);
  
  Cur := LispCdr(Code);
  if Cur = LispEmpty then
  begin
    Args := LispEmpty;
  end
  else 
  begin
    Arg := TLispPair.Create(Eval(LispCar(Cur), Env), LispEmpty);
    Cur := LispCdr(Cur);
    while Cur <> LispEmpty do
    begin
      Arg.D := TLispPair.Create(Eval(LispCar(Cur), Env), LispEmpty);
      Arg := Arg.D;
      Cur := LispCdr(Cur);
    end;
    Args := Arg;
  end;

  Result := Apply(Proc, Args);
end;

function TLispInterpreter.EvalExpr(Code, Env: LV): LV;
var
  ID: string;
  Tmp: LV;
begin
  if LispCar(Code) is TLispSymbol then
  begin
    ID := LispCar(Code).ToString;
    if ID = 'quote' then
    begin
      Result := LispCar(LispCdr(Code));
    end
    else if ID = 'if' then
    begin
      Tmp := LispCdr(LispCdr(Code));
      if Eval(LispCar(LispCdr(Code)), Env) = LispFalse then
      begin
        Result := Eval(LispCar(LispCdr(Tmp)), Env);
      end
      else
      begin
        Result := Eval(LispCar(Tmp), Env);
      end;
    end
    else if ID = 'lambda' then
    begin
      Tmp := LispCdr(Code);
      Result := TLispClosure.Create('', LispCar(Tmp), LispCdr(Tmp), Env);
    end
    else if ID = 'set!' then
    begin
      Tmp := LookupSymbol(LispCar(LispCdr(Code)));
      TLispPair(Tmp).D := Eval(LispCar(LispCdr(LispCdr(Code))), Env);
      Result := LispVoid;
    end
    else
    begin
      Result := EvalApplication(Code, Env);
    end
  end
  else
  begin
    Result := EvalApplication(Code, Env);
  end;
end;

function TLispInterpreter.LookupSymbol(Code, Env: LV): LV;
var
  Cur, Binding: LV;
  Name, BindName: TLispSymbol;
begin
  if not (Code is TLispSymbol) then
  begin
    raise ELispError.Create('Invalid identifier', Code);
  end;

  Name := TLispSymbol(Code);

  while Cur <> LispEmpty do
  begin
    Binding := LispCar(Cur);

    if not (LispCar(Binding) is TLispSymbol) then
    begin
      raise ELispError.Create('Invalid binding name', Binding.A);
    end;

    BindName := TLispSymbol(LispCar(Binding));
        
    if Name.Ident = BindName.Ident then
    begin
      Result := Binding;
      exit;
    end;

    Cur := LispCdr(Cur);
  end;

  raise ELispError.Create('Unknown variable', Code);
end;

function TLispInterpreter.Eval(Code, Env: LV): LV;
begin
  if Env = nil then
  begin
    Env := FEnv;
  end;

  if Code is TLispPair then
  begin
    Result := EvalExpr(Code, Env);
  end
  else if Code is TLispSymbol then
  begin
    Result := LispCdr(LookupSymbol(Code, Env));
  end
  else
  begin
    Result := Code;
  end;
end;

function ExpandArgs(Names, Values: LV): LV;
var
  Head: LV;
begin
  if Names is TLispPair then
  begin
    Head := TLispPair.Create(LispCar(Names), LispCar(Values));
    Result := TLispPair.Create(Head, ExpandArgs(LispCdr(Names), LispCdr(Values)));
  end
  else
  begin
    Result := TLispPair.Create(Names, Values);
  end;
end;

function TLispInterpreter.Apply(Proc, Args: LV): LV;
var
  Closure: TLispClosure;
  Env: LV;
begin
  if Proc is TLispPrimitive then
  begin
    Result := Proc.Exec(Args);
  end
  else if Proc is TLispClosure then
  begin
    Closure := TLispClosure(Proc);
    Env := LispAppend(ExpandArgs(Closure.Args, Args), Closure.Env);
    Result := Eval(Closure.Code, Env);
  end
  else
  begin
    raise ELispError.Create('Not a procedure', Proc);
  end;
end;

constructor TLispInterpreter.Create(AEnv: LV);
begin
  FEnv := AEnv;
end;

end.
