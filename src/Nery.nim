import macros
import tables

type
  KeyVal* = object
    key, val: string
  NeryKind* = enum
    nkSelect
    nkInsert
  Id* = object
    name*, alias*, prefix*: string
  Nery* = ref object
    entity*: Id
    case kind*: NeryKind
    of nkSelect:
      columns*: seq[Id]
    of nkInsert:
      entries*: Table[string, string]

proc neryImpl(body: NimNode): Nery =
  expectKind body, nnkStmtList
  expectMinLen body, 1
  let n = body[0]
  expectKind n, nnkCommand
  let kind = $n[0]
  case kind:
    of "select":
      var s = Nery(kind: nkSelect)
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

macro nery*(body: untyped): untyped =
  result = newLit(neryImpl(body))
