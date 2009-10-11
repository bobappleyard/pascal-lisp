unit Lisp;

interface

uses
  BoehmGC, SysUtils, Classes;

  {$define Interface}
  {$include lisptypes.pas}
  {$include lispsyntax.pas}
  {$include lispinterpreter.pas}

implementation 

  {$undef Interface}
  {$include lisptypes.pas}
  {$include lispsyntax.pas}
  {$include lispprimitives.pas}
  {$include lispinterpreter.pas}

initialization
  InitTypes;
  InitInterpreter;
end.

