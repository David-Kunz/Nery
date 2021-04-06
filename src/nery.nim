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

proc neryImpl(body: NimNode): Nery =

  result = Nery()

  if body.matches(StmtList[Command[@queryKind is Ident(), @table]] | StmtList[
      Command[@queryKind is Ident(), @table, StmtList[all @stmts]]]):
    case queryKind.strVal:
      of "select":
        result.kind = nkSelect
        if table.matches(Infix[@infix is Ident(), @tableName is Ident(),
            @tableAlias is Ident()]):
          if infix.strVal != "as": error("Invalid infix " & infix.strVal)
          result.id = Id(name: $tableName, alias: $tableAlias)
        if table.matches(@tableName is Ident()):
          result.id = Id(name: $tableName)
        for stmt in stmts:
          if stmt.matches(@col is Ident()):
            result.columns.add(Id(name: $col))
          if stmt.matches(Infix[@infix is Ident(), @col is Ident(),
              @alias is Ident()]):
            if infix.strVal != "as": error("Invalid infix " & infix.strVal)
            result.columns.add(Id(name: $col, alias: $alias))
          if stmt.matches(Call[@id is Ident(), @subStmtList]):
            if id.strVal == "orderBy":
              for subStmt in subStmtList:
                if subStmt.matches(@col is Ident()):
                  result.orderBy.add(OrderBy(id: Id(name: $col), order: asc))
                if subStmt.matches(Command[@col is Ident(), @order is Ident()]):
                  let o = case order.strVal:
                    of "asc": asc
                    of "desc": desc
                    else:
                      error("Invalid order " & order.strVal)
                      return
                  result.orderBy.add(OrderBy(id: Id(name: $col), order: o))
      of "insert":
        result.kind = nkInsert
        # TODO
      else:
        error("Invalid query kind")

macro nery*(body: untyped): untyped =
  result = newLit(neryImpl(body))
