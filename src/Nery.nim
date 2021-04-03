import macros
import fusion/matching
import tables

type
  KeyVal = object
    key, val: string
  QueryKind = enum
    qkSelect
    qkInsert
  Query = ref object
    entity: string
    case kind: QueryKind
    of qkSelect:
      columns: seq[string]
    of qkInsert:
      entries: Table[string, string]



proc queryh(n: NimNode): Query = 
  expectKind n, nnkCommand 
  expectMinLen n, 2
  let kind = $n[0]
  echo kind
  case kind:
    of "select":
      let calls = n[1]
      let tableName = $calls[0]
      var s = Query(kind: qkSelect, entity: tableName)
      if calls.len > 1:
        for i in 1..<calls.len:
          let c = calls[i]
          s.columns.add($calls[i])
      else:
        s.columns = @["*"]
      echo s[]
      return s

    of "insert":
      echo "found insert"
    else:
      error("Invalid query: " & kind)

proc queryImpl(body: NimNode): Query =
  expectKind body, nnkStmtList
  expectMinLen body, 1
  echo body.treeRepr
  let b0 = body[0]
  result = queryh(b0)

macro query*(body: untyped): untyped =
  let query = queryImpl(body)
