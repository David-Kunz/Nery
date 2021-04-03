import unittest
import Nery

suite "selects":
  test "without columns":
    let res = query:
      select myDbTable()
    assert res.entity.name == "myDbTable"
    assert res.columns == @[Id(name: "*")]

  test "with columns":
    let res = query:
      select myDbTable(col1, col2)
    res.columns.add(Id(name: "col3"))
    assert res.entity.name == "myDbTable"
    assert res.columns == @[Id(name: "col1"),Id(name: "col2"),Id(name: "col3")]

  test "with alias":
    let res = query:
      select myDbTable(col1 as myCol, col2)
    assert res.columns == @[Id(name: "col1", alias: "myCol"), Id(name: "col2")]
