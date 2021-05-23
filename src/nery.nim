import macros
import tables
import fusion/matching
import print

type
  KeyVal* = object
    key, val: string
  NeryKind* = enum
    nkSelect
    nkInsert
  Id* = object
    name*, alias*, prefix*: string
    arguments*: seq[Id]
  ReferenceKind* = enum
    rkId,
    rkFunction
  Reference* = object
    alias*, prefix*: string
    case kind*: ReferenceKind
    of rkId:
      id*: string
    of rkFunction:
      function*: string
      arguments*: seq[Reference]
  Order* = enum
    asc, desc
  OrderBy* = object
    reference*: Reference
    order*: Order
  WhereKind* = enum
    wkUnary,
    wkBinary
  Where* = object
    case kind*: WhereKind
    of wkUnary:
      val*: string
    of wkBinary:
      lhs*: Reference
      rhs*: Reference
      op*: string
  Nery* = ref object
    reference*: Reference
    case kind*: NeryKind
    of nkSelect:
      columns*: seq[Reference]
      orderBy*: seq[OrderBy]
      where*: seq[Where]
    of nkInsert:
      entries*: Table[string, string]

proc `==`*(ref1, ref2: Reference): bool =
  if ref1.kind != ref2.kind: return false
  if ref1.alias != ref2.alias or ref1.prefix != ref2.prefix: return false
  if ref1.kind == rkId:
    return ref1.id == ref2.id
  if ref1.kind == rkFunction:
    return ref1.function == ref2.function and ref1.arguments == ref2.arguments

proc `==`*(where1, where2: Where): bool =
  if where1.kind != where2.kind: return false
  if where1.kind == wkUnary: return where1.val == where2.val
  if where1.kind == wkBinary: return where1.lhs == where2.lhs and where1.rhs == where2.rhs

proc ident2Reference(ident: NimNode): Reference =
  Reference(kind: rkId, id: ident.strVal)

proc ident2OrderBy(ident: NimNode): OrderBy =
  result = OrderBy(reference: ident2Reference(ident), order: asc)

proc command2OrderBy(command: NimNode): OrderBy =
  if command.matches(Command[@col is Ident(), @order is Ident()]):
    let o = case order.strVal:
      of "asc": asc
      of "desc": desc
      else:
        error("Invalid order " & order.strVal)
        return
    result = OrderBy(reference: Reference(kind: rkId, id: $col), order: o)

proc call2Reference(call: NimNode): Reference =
  if call.matches(Call[@fnName is Ident(), all @idents]):
    result = Reference(kind: rkFunction, function: fnName.strVal)
    for ident in idents:
      if ident.matches(@ident is Ident()):
        result.arguments.add(Reference(kind: rkId, id: ident.strVal))
      if ident.matches(@subCall is Call()):
        result.arguments.add(call2Reference(subCall))

proc infix2Reference(infix: NimNode): Reference =
  if infix.matches(Infix[@infix is Ident(), @name is Ident(),
      @alias is Ident()]):
    if infix.strVal != "as": error("Invalid infix " & infix.strVal)
    result = Reference(kind: rkId, id: name.strVal, alias: alias.strVal)
  if infix.matches(Infix[@infix is Ident(), @call is Call(),
      @alias is Ident()]):
    if infix.strVal != "as": error("Invalid infix " & infix.strVal)
    result = call2Reference(call)
    result.alias = alias.strVal


proc infix2Where(infix: NimNode): seq[Where] =
  if infix.matches(Infix[@cmp is Ident(), @lhs is Infix(), @rhs is Infix()]):
    result.add infix2Where(lhs)
    result.add Where(kind: wkUnary, val: cmp.strVal)
    result.add infix2Where(rhs)
  elif infix.matches(Infix[@op is Ident(), @lhs is Ident(), @rhs is Ident()]):
    result.add Where(kind: wkBinary, op: op.strVal(), lhs: Reference(kind: rkId, id: lhs.strVal), rhs: Reference(kind: rkId, id: rhs.strVal))


proc stmt2Wheres(stmt: NimNode): seq[Where] = 
  if stmt.kind == nnkInfix:
    result.add(infix2Where(stmt))
  if stmt.kind == nnkPar:
    result.add(Where(kind: wkUnary, val: "("))
    result.add(stmt2Wheres(stmt[0]))
    result.add(Where(kind: wkUnary, val: ")"))


proc stmtList2Wheres(stmts: NimNode): seq[Where] = 
  for stmt in stmts:
    if result.len > 0:
      result.add(Where(kind: wkUnary, val: "and"))
    result.add(stmt2Wheres(stmt))
  echo result

proc neryImpl(body: NimNode): Nery =
  result = Nery()
  if body.matches(StmtList[Command[@queryKind is Ident(), @table]] |
                  StmtList[Command[@queryKind is Ident(), @table, StmtList[all @stmts]]]):
    case queryKind.strVal:
      of "select":
        result.kind = nkSelect
        if table.kind == nnkInfix:
          result.reference = infix2Reference(table)
        if table.kind == nnkIdent:
          result.reference = ident2Reference(table)
        for stmt in stmts:
          if stmt.kind == nnkIdent:
            result.columns.add(ident2Reference(stmt))
          if stmt.kind == nnkInfix:
            result.columns.add(infix2Reference(stmt))
          if stmt.kind == nnkCall:
            if stmt[0].strVal == "orderBy":
              doAssert stmt.len > 1
              for subStmt in stmt[1]:
                if subStmt.kind == nnkIdent:
                  result.orderBy.add(ident2OrderBy(subStmt))
                if subStmt.kind == nnkCommand:
                  result.orderBy.add(command2OrderBy(subStmt))
            elif stmt[0].strVal == "where":
              doAssert stmt.len > 1
              result.where.add(stmtList2Wheres(stmt[1]))
            else:
              result.columns.add(call2Reference(stmt))

      of "insert":
        result.kind = nkInsert
        # TODO
      else:
        error("Invalid query kind")

macro nery*(body: untyped): untyped =
  echo body.treeRepr
  result = newLit(neryImpl(body))
