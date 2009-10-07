unit Primtives;

interface

uses
  LispTypes;

function PrimitiveEnvironment: LV;
function RegisterPrimitive(Name: string; Proc: TLispPrimitiveProcedure; Env: LV): LV;

implementation

function PrimitiveEnvironment: LV;
begin

end;

function RegisterPrimitive(Name: string; Proc: TLispPrimitiveProcedure; Env: LV): LV;
var
  Binding: LV;
begin
  Binding := TLispPair.Create(TLispSymbol.Create(Name), TLispPrimitive.Create(Name, Proc));
  Result := TLispPair.Create(Binding, Env);
end;

end.











