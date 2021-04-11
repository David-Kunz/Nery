import macros
import tables
import fusion/matching

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
  Nery* = ref object
    id*: Id
    case kind*: NeryKind
    of nkSelect:
      columns*: seq[Id]
      orderBy*: seq[OrderBy]
    of nkInsert:
      entries*: Table[string, string]


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


proc infix2Id(infix: Nimnode): Id =
  if infix.matches(Infix[@infix is Ident(), @name is Ident(),
      @alias is Ident()]):
    if infix.strVal != "as": error("Invalid infix " & infix.strVal)
    result = Id(name: name.strVal, alias: alias.strVal)


proc neryImpl(body: NimNode): Nery =

  result = Nery()

  if body.matches(StmtList[Command[@queryKind is Ident(), @table]] | StmtList[
      Command[@queryKind is Ident(), @table, StmtList[all @stmts]]]):
    case queryKind.strVal:
      of "select":
        result.kind = nkSelect
        if table.matches(@infix is Infix()):
          result.id = infix2Id(infix)
        if table.matches(@tableName is Ident()):
          result.id = ident2Id(tableName)
        for stmt in stmts:
          if stmt.matches(@col is Ident()):
            result.columns.add(ident2Id(col))
          if stmt.matches(@infix is Infix()):
            result.columns.add(infix2Id(infix))
          if stmt.matches(Call[@id is Ident(), @subStmtList]):
            if id.strVal == "orderBy":
              for subStmt in subStmtList:
                if subStmt.matches(@col is Ident()):
                  result.orderBy.add(ident2OrderBy(col))
                if subStmt.matches(@command is Command()):
                  result.orderBy.add(command2OrderBy(command))
      of "insert":
        result.kind = nkInsert
        # TODO
      else:
        error("Invalid query kind")

macro nery*(body: untyped): untyped =
  echo body.treeRepr
  result = newLit(neryImpl(body))
