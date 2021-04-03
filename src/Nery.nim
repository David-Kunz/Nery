import macros
import fusion/matching
import tables

type
  KeyVal* = object
    key, val: string
  QueryKind* = enum
    qkSelect
    qkInsert
  Id* = object
    name*, alias*, prefix*: string
  Query* = ref object
    entity*: Id
    case kind*: QueryKind
    of qkSelect:
      columns*: seq[Id]
    of qkInsert:
      entries*: Table[string, string]

proc queryh(n: NimNode): Query = 
  expectKind n, nnkCommand 
  expectMinLen n, 2
  let kind = $n[0]
  case kind:
    of "select":
      let calls = n[1]
      let tableName = $calls[0]
      var s = Query(kind: qkSelect, entity: Id(name: tableName))
      if calls.len > 1:
        for i in 1..<calls.len:
          let c = calls[i]
          case c.kind:
            of nnkInfix:
              let call = calls[i]
              if $call[0] == "as":
                echo "found aliased"
                s.columns.add(Id(name: $call[1], alias: $call[2]))
            of nnkIdent:
              s.columns.add(Id(name: $calls[i]))
            else:
              error("Invalid column")
      else:
        s.columns = @[Id(name: "*")]
      return s

    of "insert":
      echo "found insert"
    else:
      error("Invalid query: " & kind)

proc queryImpl(body: NimNode): Query =
  expectKind body, nnkStmtList
  expectMinLen body, 1
  let b0 = body[0]
  result = queryh(b0)

macro query*(body: untyped): untyped =
  result = newLit(queryImpl(body))
  # echo body.treeRepr
  # result = newLit("3")
