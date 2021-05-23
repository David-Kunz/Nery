import unittest
import nery

suite "select":
  # test "without columns":
  #   let res = nery:
  #     select myDbTable
  #   assert res.id.name == "myDbTable"
  #   assert res.columns == @[]

  # test "columns":
  #   let res = nery:
  #     select myDbTable:
  #       col1
  #       col2
  #   assert res.id.name == "myDbTable"
  #   assert res.columns == @[Id(name: "col1"), Id(name: "col2")]

  # test "column alias":
  #   let res = nery:
  #     select myDbTable:
  #       col1 as myCol
  #       col2
  #   assert res.columns == @[Id(name: "col1", alias: "myCol"), Id(name: "col2")]

  # test "table alias":
  #   let res = nery:
  #     select myDbTable as myDb:
  #       col1
  #       col2
  #   assert res.id.alias == "myDb"
  #   assert res.id.name == "myDbTable"
  #   assert res.columns == @[Id(name: "col1"), Id(name: "col2")]

  # test "orderby":
  #   let res = nery:
  #     select myDbTable as myDb:
  #       col1
  #       col2
  #       orderBy:
  #         col3
  #         col4 asc
  #         col5 desc
  #   assert res.id.alias == "myDb"
  #   assert res.id.name == "myDbTable"
  #   assert res.columns == @[Id(name: "col1"), Id(name: "col2")]
  #   assert res.orderBy == @[OrderBy(id: Id(name: "col3"), order: asc), OrderBy(
  #       id: Id(name: "col4"), order: asc), OrderBy(id: Id(name: "col5"), order: desc)]

  # test "columns with functions":
  #   let res = nery:
  #     select myDbTable:
  #       col1
  #       col2
  #       avg(col3)
  #   assert res.id.name == "myDbTable"
  #   assert res.columns == @[Id(name: "col1"), Id(name: "col2"), Id(name: "avg", arguments: @[Id(name: "col3")])]

  # test "columns with functions and alias":
  #   let res = nery:
  #     select myDbTable:
  #       col1
  #       col2
  #       avg(col3) as myAvg
  #   assert res.id.name == "myDbTable"
  #   assert res.columns == @[Id(name: "col1"), Id(name: "col2"), Id(name: "avg", alias: "myAvg", arguments: @[Id(name: "col3")])]

  # test "columns with functions with multiple arguments":
  #   let res = nery:
  #     select myDbTable:
  #       col1
  #       col2
  #       coalesce(col3, col4)
  #   assert res.id.name == "myDbTable"
  #   assert res.columns == @[Id(name: "col1"), Id(name: "col2"), Id(name: "coalesce", arguments: @[Id(name: "col3"), Id(name: "col4")])]

  # test "columns with nested functions":
  #   let res = nery:
  #     select myDbTable:
  #       col1
  #       col2
  #       coalesce(col3, avg(col4))
  #   assert res.id.name == "myDbTable"
  #   assert res.columns == @[Id(name: "col1"), Id(name: "col2"), Id(name: "coalesce", arguments: @[Id(name: "col3"), Id(name: "avg", arguments: @[Id(name: "col4")])])]

  # test "columns with nested functions and alias":
  #   let res = nery:
  #     select myDbTable:
  #       col1
  #       col2
  #       coalesce(col3, avg(col4)) as myCoalesce
  #   assert res.id.name == "myDbTable"
  #   assert res.columns == @[Id(name: "col1"), Id(name: "col2"), Id(name: "coalesce", alias: "myCoalesce", arguments: @[Id(name: "col3"), Id(name: "avg", arguments: @[Id(name: "col4")])])]

  # test "where":
  #   let res = nery:
  #     select myDbTable:
  #       col1
  #       col2
  #       where:
  #         col3 == col4
  #   assert res.id.name == "myDbTable"
  #   assert res.columns == @[Id(name: "col1"), Id(name: "col2")]
  #   assert res.where == @[Where(op: "==", lhs: Id(name: "col3"), rhs: Id(name: "col4"))]

  # test "where multiple":
  #   let res = nery:
  #     select myDbTable:
  #       col1
  #       col2
  #       where:
  #         col3 == col4
  #         col5 == col6
  #   assert res.id.name == "myDbTable"
  #   assert res.columns == @[Id(name: "col1"), Id(name: "col2")]
  #   assert res.where == @[Where(op: "==", lhs: Id(name: "col3"), rhs: Id(name: "col4")), Where(op: "and"), Where(op: "==", lhs: Id(name: "col5"), rhs: Id(name: "col6"))]

  test "where multiple and brackets":
    let res = nery:
      select myDbTable:
        col1
        col2
        where:
          col3 == col4
          (col5 == col6)
    assert res.id.name == "myDbTable"
    assert res.columns == @[Id(name: "col1"), Id(name: "col2")]
    echo res.where
    # assert res.where == @[Where(op: "==", lhs: Id(name: "col3"), rhs: Id(name: "col4")), Where(op: "and"), Where(op: "==", lhs: Id(name: "col5"), rhs: Id(name: "col6"))]
