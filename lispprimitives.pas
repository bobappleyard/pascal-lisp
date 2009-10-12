{ General Stuff }

function EqP(Args: Pointer): LV;
var 
  A, B: LV;
begin
  LispParseArgs(Args, [@A, @B]);
  Result := LispBoolean(A = B);
end;

function EqvP(Args: Pointer): LV;
var 
  A, B: LV;
begin
  LispParseArgs(Args, [@A, @B]);
  Result := LispBoolean(A.Equals(B));
end;

function Gensym(Args: Pointer): LV;
begin
  LispParseArgs(Args, []);
  Result := LispGensym();
end;

function BoehmP(Args: Pointer): LV;
begin
  LispParseArgs(Args, []);
  Result := LispBoolean(GCInstalled);
end;

{ Control }

function Values(Args: Pointer): LV;
var
  First, Rest: LV;
begin
  LispParseArgs(Args, [@First, @Rest], True);
  Result := TLispMultipleValues.Create(First, Rest);
end;

type
  TControlPrimitives = class
  private
    Lisp: TLispInterpreter;
  public
    function Expand(Args: Pointer): LV;
    function Eval(Args: Pointer): LV;
    function Apply(Args: Pointer): LV;
    function Load(Args: Pointer): LV;
    function CallWithValues(Args: Pointer): LV;
    function AddGlobal(Args: Pointer): LV;
    function AddSyntax(Args: Pointer): LV;
    function CallWithException(Args: Pointer): LV;

    constructor Create(Interpreter: TLispInterpreter);
  end;

function TControlPrimitives.Expand(Args: Pointer): LV;
var
  Expr: LV;
begin
  LispParseArgs(Args, [@Expr]);
  Result := Lisp.Expand(Expr, LispEmpty);
end;

function TControlPrimitives.Eval(Args: Pointer): LV;
var
  Code, Env: LV;
begin
  LispParseArgs(Args, [@Code, @Env]);
  Result := Lisp.Eval(Code, Env);
end;

function TControlPrimitives.Apply(Args: Pointer): LV;
var
  Proc, ArgLst: LV;
  First, This, Next: TLispPair;
begin
  LispParseArgs(Args, [@Proc, @ArgLst], True);
  if ArgLst = LispEmpty then
  begin
    Result := Lisp.Apply(Proc, ArgLst);
  end 
  else if LispCdr(ArgLst) = LispEmpty then
  begin
    Result := Lisp.Apply(Proc, LispCar(ArgLst));
  end
  else
  begin
    First := TLispPair.Create(LispCar(ArgLst), LispEmpty);
    This := First;
    ArgLst := LispCdr(ArgLst);
    while LispCdr(ArgLst) <> LispEmpty do
    begin
      Next := TLispPair.Create(LispCar(ArgLst), LispEmpty);
      This.D := Next;
      This := Next;
      ArgLst := LispCdr(ArgLst);
    end;
    This.D := LispCar(ArgLst);
    Result := Lisp.Apply(Proc, First);
  end;
end;

function TControlPrimitives.Load(Args: Pointer): LV;
var
  Path: LV;
begin
  LispParseArgs(Args, [@Path]);
  Lisp.Load(LispToString(Path));
  Result := LispVoid;
end;

function TControlPrimitives.CallWithValues(Args: Pointer): LV;
var
  Producer, Consumer, Produced: LV;
  Vals: TLispMultipleValues;
begin
  LispParseArgs(Args, [@Producer, @Consumer]);
  Produced := Lisp.Apply(Producer, LispEmpty);
  if Produced is TLispMultipleValues then
  begin
    Vals := TLispMultipleValues(Produced);
    Result := Lisp.Apply(Consumer, TLispPair.Create(Vals.First, Vals.Rest));
  end
  else
  begin
    Result := Lisp.Apply(Consumer, TLispPair.Create(Produced, LispEmpty));
  end;
end;

function TControlPrimitives.AddGlobal(Args: Pointer): LV;
var
  Name, Value: LV;
begin
  LispParseArgs(Args, [@Name, @Value]);
  Lisp.RegisterGlobal(Name, Value);
  Result := LispVoid;
end;  

function TControlPrimitives.AddSyntax(Args: Pointer): LV;
var
  Name, Value: LV;
begin
  LispParseArgs(Args, [@Name, @Value]);
  Lisp.RegisterSyntax(Name, Value);
  Result := LispVoid;
end;  
  
function TControlPrimitives.CallWithException(Args: Pointer): LV;
var
  Handler, Call: LV;
begin
  LispParseArgs(Args, [@Handler, @Call]);
  try
    Result := Lisp.Apply(Call, LispEmpty);
  except
    on E: ELispError do
    begin
      Result := Lisp.Apply(Handler, TLispPair.Create(TLispString.Create(E.Message), LispEmpty));
    end;
    on E: LV do
    begin
      Result := Lisp.Apply(Handler, TLispPair.Create(E, LispEmpty));
    end;
  end;
end;

constructor TControlPrimitives.Create(Interpreter: TLispInterpreter);
begin
  Lisp := Interpreter;
end;

function RaiseError(Args: Pointer): LV;
var
  Msg, Obj: LV;
begin
  LispParseArgs(Args, [@Msg, @Obj]);
  raise ELispError.Create(LispToString(Msg), Obj);
end;

{ Fixnums }

function FixnumAdd(Args: Pointer): LV;
var
  A, B: LV;
begin
  LispParseArgs(Args,[@A, @B]);
  Result := LispNumber(LispToInteger(A) + LispToInteger(B));
end;

function FixnumSubtract(Args: Pointer): LV;
var
  A, B: TLispFixnum;
begin
  LispParseArgs(Args, [@A, @B]);
  Result := LispNumber(LispToInteger(A) - LispToInteger(B));
end;

function FixnumMultiply(Args: Pointer): LV;
var
  A, B: TLispFixnum;
begin
  LispParseArgs(Args, [@A, @B]);
  Result := LispNumber(LispToInteger(A) * LispToInteger(B));
end;

function FixnumQuotient(Args: Pointer): LV;
var
  A, B: TLispFixnum;
begin
  LispParseArgs(Args, [@A, @B]);
  Result := LispNumber(LispToInteger(A) div LispToInteger(B));
end;

function FixnumModulo(Args: Pointer): LV;
var
  A, B: TLispFixnum;
begin
  LispParseArgs(Args, [@A, @B]);
  Result := LispNumber(LispToInteger(A) mod LispToInteger(B));
end;

function FixnumToReal(Args: Pointer): LV;
var
  X: TLispFixnum;
begin
  LispParseArgs(Args, [@X]);
  Result := LispNumber(LispToReal(X));
end;

{ Reals }

procedure CheckReal(X: LV);
begin
  LispTypeCheck(X, TLispReal, 'Not a Real');
end;

function RealAdd(Args: Pointer): LV;
var
  A, B: TLispReal;
begin
  LispParseArgs(Args, [@A, @B]);
  CheckReal(A);
  CheckReal(B);

  Result := TLispReal.Create(A.Value + B.Value);
end;

function RealSubtract(Args: Pointer): LV;
var
  A, B: TLispReal;
begin
  LispParseArgs(Args, [@A, @B]);
  CheckReal(A);
  CheckReal(B);

  Result := TLispReal.Create(A.Value - B.Value);
end;

function RealMultiply(Args: Pointer): LV;
var
  A, B: TLispReal;
begin
  LispParseArgs(Args, [@A, @B]);
  CheckReal(A);
  CheckReal(B);

  Result := TLispReal.Create(A.Value * B.Value);
end;

function RealDivide(Args: Pointer): LV;
var
  A, B: TLispReal;
begin
  LispParseArgs(Args, [@A, @B]);
  CheckReal(A);
  CheckReal(B);

  Result := TLispReal.Create(A.Value / B.Value);
end;

{ Pairs }

function Cons(Args: Pointer): LV;
var
  A, D: TLispReal;
begin
  LispParseArgs(Args, [@A, @D]);
  Result := TLispPair.Create(A, D);
end;

function Car(Args: Pointer): LV;
var
  P: LV;
begin
  LispParseArgs(Args, [@P]);  
  Result := LispCar(P);
end;

function Cdr(Args: Pointer): LV;
var
  P: LV;
begin
  LispParseArgs(Args, [@P]);  
  Result := LispCdr(P);
end;

function SetCar(Args: Pointer): LV;
var
  P, X: LV;
begin
  LispParseArgs(Args, [@P, @X]);
  LispTypeCheck(P, TLispPair, 'not a pair');
  TLispPair(P).A := X;
  Result := LispVoid;
end;

function SetCdr(Args: Pointer): LV;
var
  P, X: LV;
begin
  LispParseArgs(Args, [@P, @X]);  
  LispTypeCheck(P, TLispPair, 'not a pair');
  TLispPair(P).D := X;
  Result := LispVoid;
end;

procedure RegisterPrimitives(I: TLispInterpreter);
var
  Control: TControlPrimitives;
begin
  Control := TControlPrimitives.Create(I);

  { General stuff }
  I.RegisterGlobal('eq?', LispPrimitive(@EqP));
  I.RegisterGlobal('eqv?', LispPrimitive(@EqvP));
  I.RegisterGlobal('number?', LispTypePredicate(TLispNumber));
  I.RegisterGlobal('gensym', LispPrimitive(@Gensym));
  I.RegisterGlobal('boehm?', LispPrimitive(@BoehmP));

  { Control }
  I.RegisterGlobal('procedure?', LispTypePredicate(TLispProcedure));
  I.RegisterGlobal('expand', LispPrimitive(Control.Expand));
  I.RegisterGlobal('eval', LispPrimitive(Control.Eval));
  I.RegisterGlobal('apply', LispPrimitive(Control.Apply));
  I.RegisterGlobal('load', LispPrimitive(Control.Load));
  I.RegisterGlobal('values', LispPrimitive(@Values));
  I.RegisterGlobal('call-with-values', LispPrimitive(Control.CallWithValues));
  I.RegisterGlobal('call-with-exception', LispPrimitive(Control.CallWithException));
  I.RegisterGlobal('add-global', LispPrimitive(Control.AddGlobal));
  I.RegisterGlobal('add-syntax', LispPrimitive(Control.AddSyntax));
  I.RegisterGlobal('error', LispPrimitive(@RaiseError));

  { Fixnums }
  I.RegisterGlobal('fixnum?', LispTypePredicate(TLispFixnum));
  I.RegisterGlobal('fixnum-add', LispPrimitive(@FixnumAdd));
  I.RegisterGlobal('fixnum-subtract', LispPrimitive(@FixnumSubtract));
  I.RegisterGlobal('fixnum-multiply', LispPrimitive(@FixnumMultiply));
  I.RegisterGlobal('fixnum-quotient', LispPrimitive(@FixnumQuotient));
  I.RegisterGlobal('fixnum-modulo', LispPrimitive(@FixnumModulo));
  I.RegisterGlobal('fixnum->real', LispPrimitive(@FixnumToReal));

  { Reals }
  I.RegisterGlobal('real?', LispTypePredicate(TLispReal));
  I.RegisterGlobal('real-add', LispPrimitive(@RealAdd));
  I.RegisterGlobal('real-subtract', LispPrimitive(@RealSubtract));
  I.RegisterGlobal('real-multiply', LispPrimitive(@RealMultiply));
  I.RegisterGlobal('real-divide', LispPrimitive(@RealDivide));

  { Pairs }
  I.RegisterGlobal('pair?', LispTypePredicate(TLispPair));
  I.RegisterGlobal('cons', LispPrimitive(@Cons));
  I.RegisterGlobal('car', LispPrimitive(@Car));
  I.RegisterGlobal('cdr', LispPrimitive(@Cdr));
  I.RegisterGlobal('set-car!', LispPrimitive(@SetCar));
  I.RegisterGlobal('set-cdr!', LispPrimitive(@SetCdr));
end;
