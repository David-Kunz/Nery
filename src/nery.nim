import macros
import tables
import fusion/matching

# TODO: Use object variants and implement `==` by hand, otherwise the output is way to verbose.

type
  KeyVal* = object
    key, val: string
  NeryKind* = enum
    nkSelect
    nkInsert
  Id* = object
    name*, alias*, prefix*: string
    arguments*: seq[Id]
  Order* = enum
    asc, desc
  OrderBy* = object
    id*: Id
    order*: Order
  Where* = object
    op*: string
    lhs*: Id
    rhs*: Id
  Nery* = ref object
    id*: Id
    case kind*: NeryKind
    of nkSelect:
      columns*: seq[Id]
      orderBy*: seq[OrderBy]
      where*: seq[Where]
    of nkInsert:
      entries*: Table[string, string]

proc whereAnd*(query: var Nery, where: Where) =
  if query.kind == nkSelect: # TODO: Also for update later
    if query.where.len == 0:
      query.where.add(where)
    else:
      query.where.add(Where(op: "and"))
      query.where.add(where)

proc ident2Id(ident: NimNode): Id =
  Id(name: ident.strVal)

proc ident2OrderBy(ident: NimNode): OrderBy =
  result = OrderBy(id: ident2Id(ident), order: asc)

proc command2OrderBy(command: NimNode): OrderBy =
  if command.matches(Command[@col is Ident(), @order is Ident()]):
    let o = case order.strVal:
      of "asc": asc
      of "desc": desc
      else:
        error("Invalid order " & order.strVal)
        return
    result = OrderBy(id: Id(name: $col), order: o)

proc call2Id(call: NimNode): Id =
  if call.matches(Call[@fnName is Ident(), all @idents]):
    result = Id(name: fnName.strVal)
    for ident in idents:
      if ident.matches(@ident is Ident()):
        result.arguments.add(Id(name: ident.strVal))
      if ident.matches(@subCall is Call()):
        result.arguments.add(call2Id(subCall))

proc infix2Id(infix: NimNode): Id =
  if infix.matches(Infix[@infix is Ident(), @name is Ident(),
      @alias is Ident()]):
    if infix.strVal != "as": error("Invalid infix " & infix.strVal)
    result = Id(name: name.strVal, alias: alias.strVal)
  if infix.matches(Infix[@infix is Ident(), @call is Call(),
      @alias is Ident()]):
    if infix.strVal != "as": error("Invalid infix " & infix.strVal)
    result = call2Id(call)
    result.alias = alias.strVal

proc infix2Where(infix: NimNode): Where =
  if infix.matches(Infix[@op is Ident(), @lhs is Ident(), @rhs is Ident()]):
    result = Where(op: op.strVal(), lhs: Id(name: lhs.strVal), rhs: Id(name: rhs.strVal))

proc neryImpl(body: NimNode): Nery =
  result = Nery()
  if body.matches(StmtList[Command[@queryKind is Ident(), @table]] |
                  StmtList[Command[@queryKind is Ident(), @table, StmtList[all @stmts]]]):
    case queryKind.strVal:
      of "select":
        result.kind = nkSelect
        if table.kind == nnkInfix:
          result.id = infix2Id(table)
        if table.kind == nnkIdent:
          result.id = ident2Id(table)
        for stmt in stmts:
          if stmt.kind == nnkIdent:
            result.columns.add(ident2Id(stmt))
          if stmt.kind == nnkInfix:
            result.columns.add(infix2Id(stmt))
          if stmt.kind == nnkCall:
            if stmt[0].strVal == "orderBy":
              doAssert stmt.len > 1
              for subStmt in stmt[1]:
                if subStmt.kind == nnkIdent:
                  result.orderBy.add(ident2OrderBy(subStmt))
                if subStmt.kind == nnkCommand:
                  result.orderBy.add(command2OrderBy(subStmt))
            elif stmt[0].strVal == "where":
              # TODO: Implement where properly (with `and` and `or`)
              doAssert stmt.len > 1
              for subStmt in stmt[1]:
                if subStmt.kind == nnkInfix:
                  result.whereAnd(infix2Where(subStmt)) 
                if subStmt.kind == nnkPar:
                  result.whereAnd(Where(op: "(")) 
                  for pStmt in subStmt:
                    if pStmt.kind == nnkInfix:
                      result.whereAnd(infix2Where(pStmt))
                  result.whereAnd(Where(op: ")")) 

            else:
              result.columns.add(call2Id(stmt))

      of "insert":
        result.kind = nkInsert
        # TODO
      else:
        error("Invalid query kind")

macro nery*(body: untyped): untyped =
  echo body.treeRepr
  result = newLit(neryImpl(body))
