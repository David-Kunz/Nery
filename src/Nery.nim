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

proc queryImpl(body: NimNode): Query =
  expectKind body, nnkStmtList
  expectMinLen body, 1
  let n = body[0]
  # result = queryh(b0)
  expectKind n, nnkCommand
  let kind = $n[0]
  case kind:
    of "select":
      var s = Query(kind: qkSelect)
      let second = n[1]
      if second.kind == nnkInfix and $second[0] == "as":
        s.entity = Id(name: $second[1], alias: $second[2])
      elif second.kind == nnkIdent:
        s.entity = Id(name: $second)
      else: error("Invalid entity")

      if n.len == 3 and n[2].kind == nnkStmtList:
        for stmt in n[2]:
          case stmt.kind:
            of nnkInfix:
              if $stmt[0] == "as":
                s.columns.add(Id(name: $stmt[1], alias: $stmt[2]))
              else: error("Invalid column")
            of nnkIdent:
              s.columns.add(Id(name: $stmt))
            else: error("Invalid column")
      return s
    of "insert":
      echo "found insert"
    else:
      error("Invalid query: " & kind)

macro query*(body: untyped): untyped =
  result = newLit(queryImpl(body))
  # echo body.treeRepr
  # result = newLit("3")


# var x = query:
#   select myTable:
#     col1 as myCol
#     col2
# echo x[]
