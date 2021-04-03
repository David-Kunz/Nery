import unittest
import Nery

suite "selects":
  test "without columns":
    let res = query:
      select myDbTable
    assert res.entity.name == "myDbTable"
    assert res.columns == @[]

  test "with columns":
    let res = query:
      select myDbTable:
        col1
        col2
    assert res.entity.name == "myDbTable"
    assert res.columns == @[Id(name: "col1"),Id(name: "col2")]

  test "with column alias":
    let res = query:
      select myDbTable:
        col1 as myCol
        col2
    assert res.columns == @[Id(name: "col1", alias: "myCol"), Id(name: "col2")]

  test "with table alias":
    let res = query:
      select myDbTable as myDb:
        col1
        col2
    assert res.entity.alias == "myDb"
    assert res.entity.name == "myDbTable"
    assert res.columns == @[Id(name: "col1"), Id(name: "col2")]
