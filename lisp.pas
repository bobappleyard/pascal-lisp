uses
  LispTypes, IOStream, LispInterpreter;

var
  Lisp: TLispInterpreter;
  Input, Output: LV;
begin
  Lisp := TLispInterpreter.Create(True);
  Input := TLispPort.Create(TIOStream.Create(iosInput));
  Output := TLispPort.Create(TIOStream.Create(iosOutput));
  
  Lisp.REPL(Input, Output);
end.

