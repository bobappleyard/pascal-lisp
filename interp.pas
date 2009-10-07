interface

uses
  LispTypes, LispUtils;

type
  TLispInterpreter = class
  private
    FEnv: LV; 
  public
    function Eval(Code, Env: LV): LV;
    function Apply(Proc, Args: LV): LV;
  end;


implementation

function EvalExpr(Code, Env: LV): LV;
begin

end;

function LookupSymbol(Code, Env: LV): LV;
var
  Cur, Binding: TLispPair;
  Name, BindName: TLispSymbol;
begin
  if not (Code is TLispSymbol) then
  begin
    raise ELispError.Create('Invalid identifier', Code);
  end;

  if not (Env is TLispPair) then
  begin
    raise ELispError.Create('Invalid environment', Env);
  end;

  Name := TLispSymbol(Code);
  Cur := TLispPair(Env);
  while Cur <> LispEmpty do
  begin
    if Cur.A is TLispPair then
    begin
      Binding := TLispPair(Cur.A);

      if Binding.A is TLispSymbol then
      begin
        BindName := TLispSymbol(Binding.A);
        
        if Name.Ident = BindName.Ident then
        begin
          Result := Binding.D;
          exit;
        end;

      end
      else
      begin
        raise ELispError.Create('Invalid binding name', Binding.A);
      end;

    end
    else
    begin
      raise ELispError.Create('Invalid binding', Cur.A);
    end;
    
    if not ((Cur.D is TLispPair) or (Cur.D = LispEmpty)) then
    begin
      raise ELispError.Create('Invalid environment', Cur.D);
    end;

    Cur := Cur.D;
  end;
end;

{ TLispInterpreter }

function TLispInterpreter.Eval(Code, Env: LV): LV;
begin
  if Env = nil then
  begin
    Env := FEnv;
  end;

  if Code is TLispList then
  begin
    Result := EvalExpr(Code, Env);
  end
  else if Code is TLispSymbol then
  begin
    Result := LookupSymbol(Code, Env);
  end
  else
  begin
    Result := Code;
  end;
end;

function TLispInterpreter.Apply(Proc, Args: LV): LV;
var
  Closure: TLispClosure;
begin
  if Proc is TLispPrimitive then
  begin
    Result := Proc.Exec(Args);
  end
  else if Proc is TLispClosure then
  begin
    Closure := TLispClosure(Proc);
    Result := Eval(Closure.Code, LispAppend(Args, Closure.Env));
  end
  else
  begin
    raise ELispError.Create('Not a procedure', Proc);
  end;
end;

end.
