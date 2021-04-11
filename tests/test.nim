import unittest
import nery

suite "select":
  test "without columns":
    let res = nery:
      select myDbTable
    assert res.id.name == "myDbTable"
    assert res.columns == @[]

  test "columns":
    let res = nery:
      select myDbTable:
        col1
        col2
    assert res.id.name == "myDbTable"
    assert res.columns == @[Id(name: "col1"), Id(name: "col2")]

  test "column alias":
    let res = nery:
      select myDbTable:
        col1 as myCol
        col2
    assert res.columns == @[Id(name: "col1", alias: "myCol"), Id(name: "col2")]

  test "table alias":
    let res = nery:
      select myDbTable as myDb:
        col1
        col2
    assert res.id.alias == "myDb"
    assert res.id.name == "myDbTable"
    assert res.columns == @[Id(name: "col1"), Id(name: "col2")]

  test "orderby":
    let res = nery:
      select myDbTable as myDb:
        col1
        col2
        orderBy:
          col3
          col4 asc
          col5 desc
    assert res.id.alias == "myDb"
    assert res.id.name == "myDbTable"
    assert res.columns == @[Id(name: "col1"), Id(name: "col2")]
    assert res.orderBy == @[OrderBy(id: Id(name: "col3"), order: asc), OrderBy(
        id: Id(name: "col4"), order: asc), OrderBy(id: Id(name: "col5"), order: desc)]

  test "function columns":
    let res = nery:
      select myDbTable:
        col1
        col2
        avg(col3)
    assert res.id.name == "myDbTable"
    # assert res.columns == @[Id(name: "col1"), Id(name: "col2"), Id(name: "avg", arguments: @[Id(name: "col3")])]
