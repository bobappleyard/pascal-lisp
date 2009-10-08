uses
  LispTypes, IOStream, LispIO, Interp, Primitives;

procedure REPL(LI: TLispInterpreter);
var
  Port: LV;
begin
  Port := TLispPort.Create(TIOStream.Create(iosInput));
  while not LispEOF(Port) do
  begin
    try
      Write(LispToString(LI.Eval(LispRead(Port), nil)), #10);
    except
      on E: ELispError do
      begin
        Write(E.Message, #10);
      end;
    end;
  end;
end;

var
  Lisp: TLispInterpreter;
begin
  Lisp := TLispInterpreter.Create(PrimitiveEnvironment);
  REPL(Lisp);
end.

