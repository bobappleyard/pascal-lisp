interface

uses
  SysUtils, LispTypes;

type
  ELispError = class(Exception)
  public
    constructor Create(Msg: string; What: LV);
  end;

function LispAppend(L1, L2: LV): LV;

implementation

function LispAppend(L1, L2: LV): LV;
begin
  if not (L1 is TLispPair) then
  begin
    raise ELispError.Create('Not a list', L1);
  end;

  if not (L2 is TLispPair) then
  begin
    raise ELispError.Create('Not a list', L2);
  end;

  if L1.D = LispEmpty then
  begin
    Result := TLispPair.Create(L1.A, L2);
  end
  else
  begin
    Result := TLispPair.Create(L1.A, LispAppend(L1.D, L2);
  end;
end;

{ ELispError }

constructor Create(Msg: string; What: LV);
var
  WhatStr: string;
begin
  if What = nil then
  begin
    WhatStr := '#<null>';
  end
  else
  begin
    WhatStr := What.ToString;
  end;

  inherited Create(Msg + ': ' + WhatStr);
end;

end.
