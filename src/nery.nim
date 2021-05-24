import macros
import tables
import fusion/matching
import strutils

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
  case ref1.kind:
  of rkId:
    result = ref1.id == ref2.id
  of rkFunction:
    result = ref1.function == ref2.function and ref1.arguments == ref2.arguments

proc `==`*(where1, where2: Where): bool =
  if where1.kind != where2.kind: return false
  case where1.kind:
  of wkUnary: result = where1.val == where2.val
  of wkBinary: result = where1.lhs == where2.lhs and where1.rhs == where2.rhs

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
    result = OrderBy(reference: ident2Reference(col), order: o)

proc call2Reference(call: NimNode): Reference =
  if call.matches(Call[@fnName is Ident(), all @idents]):
    result = Reference(kind: rkFunction, function: fnName.strVal)
    for ident in idents:
      if ident.matches(@ident is Ident()):
        result.arguments.add(ident2Reference(ident))
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

proc side2Reference(side: NimNode): Reference =
  case side.kind:
  of nnkCall:
    result = call2Reference(side)
  of nnkIdent:
    result = ident2Reference(side)
  else: discard

proc stmt2Wheres(stmt: NimNode): seq[Where] =
  if stmt.kind == nnkInfix:
    let op = stmt[0]
    let lhs = stmt[1]
    let rhs = stmt[2]
    if op.strVal == "and" or op.strVal == "or":
      result.add(stmt2Wheres(lhs))
      result.add(Where(kind: wkUnary, val: op.strVal))
      result.add(stmt2Wheres(rhs))
    else:
      result.add(Where(kind: wkBinary, op: op.strVal, lhs: side2Reference(lhs),
          rhs: side2Reference(rhs)))


    # result.add(infix2Where(stmt))
  if stmt.kind == nnkPar:
    result.add(Where(kind: wkUnary, val: "("))
    result.add(stmt2Wheres(stmt[0]))
    result.add(Where(kind: wkUnary, val: ")"))


proc stmtList2Wheres(stmts: NimNode): seq[Where] =
  for stmt in stmts:
    if result.len > 0:
      result.add(Where(kind: wkUnary, val: "and"))
    result.add(stmt2Wheres(stmt))

proc reference2Sql(reference: Reference): string =
  # TODO: Support quoting/uppecase styles
  if reference.prefix != "":
    result &= reference.prefix
  case reference.kind:
  of rkId:
    result &= reference.id
  of rkFunction:
    result &= reference.function & "("
    for idx, arg in reference.arguments:
      result &= reference2Sql(arg)
      if idx < reference.arguments.len - 1: result &= ","
    result &= ")"
  if reference.alias != "":
    result &= " AS " & reference.alias

proc orderBy2Sql(orderBy: OrderBy): string =
  result &= reference2Sql(orderBy.reference)
  case orderBy.order:
    of asc: result &= ""
    of desc: result &= " DESC"

proc op2Sql(op: string): string =
  case op:
  of "==": result = "="
  else: result = op

proc where2Sql(where: Where): string =
  case where.kind:
  of wkUnary:
    result = where.val
  of wkBinary:
    result = reference2Sql(where.lhs) & " " & op2Sql(where.op) & " " &
        reference2Sql(where.rhs)

proc separated[T](sequence: seq[T], processor: proc (x: T): string,
    initial = "", separator = ",", final = "", spaces = 2,
    including = false): string =
  if including or sequence.len > 0:
    result &= initial
  if sequence.len > 0:
    var currSpaces = spaces
    for idx, item in sequence:
      let value = processor(item)
      if value == ")": dec currSpaces
      result &= repeat(" ", currSpaces) & value
      if value == "(": inc currSpaces
      if idx < sequence.len - 1: result &= separator
      result &= final

proc toSql*(nery: Nery): string =
  case nery.kind:
    of nkSelect:
      result &= separated(nery.columns, reference2Sql, initial = "SELECT\n",
          including = true, final = "\n")
      result &= "FROM\n" & "  " & reference2sql(nery.reference)
      result &= separated(nery.orderBy, orderBy2Sql, initial = "\nORDER BY\n",
          separator = ",\n")
      result &= separated(nery.where, where2Sql, initial = "\nWHERE\n",
          separator = "\n")
    of nkInsert:
      result &= "NOT IMPLEMENTED"
  result &= ";"
  result

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
  # echo body.treeRepr
  result = newLit(neryImpl(body))
