import unittest
import nery

suite "select":
  test "without columns":
    let res = nery:
      select myDbTable
    assert res.toSql == """
SELECT
FROM
  myDbTable;"""
    assert res.reference.id == "myDbTable"
    assert res.columns == @[]

  test "columns":
    let res = nery:
      select myDbTable:
        col1
        col2
    assert res.toSql == """
SELECT
  col1,
  col2
FROM
  myDbTable;"""
    assert res.reference.id == "myDbTable"
    assert res.columns == @[Reference(kind: rkId, id: "col1"), Reference(kind: rkId, id: "col2")]

  test "column alias":
    let res = nery:
      select myDbTable:
        col1 as myCol
        col2
    assert res.toSql == """
SELECT
  col1 AS myCol,
  col2
FROM
  myDbTable;"""
    assert res.columns == @[Reference(kind: rkId, id: "col1", alias: "myCol"), Reference(kind: rkId, id: "col2")]

  test "table alias":
    let res = nery:
      select myDbTable as myDb:
        col1
        col2
    assert res.toSql == """
SELECT
  col1,
  col2
FROM
  myDbTable AS myDb;"""
    assert res.reference.alias == "myDb"
    assert res.reference.id == "myDbTable"
    assert res.columns == @[Reference(kind: rkId, id: "col1"), Reference(kind: rkId, id: "col2")]

  test "orderby":
    let res = nery:
      select myDbTable as myDb:
        col1
        col2
        orderBy:
          col3
          col4 asc
          col5 desc
    assert res.toSql == """
SELECT
  col1,
  col2
FROM
  myDbTable AS myDb
ORDER BY
  col3,
  col4,
  col5 DESC;"""
    assert res.reference.alias == "myDb"
    assert res.reference.id == "myDbTable"
    assert res.columns == @[Reference(kind: rkId, id: "col1"), Reference(kind: rkId, id: "col2")]
    assert res.orderBy == @[OrderBy(reference: Reference(kind: rkId, id: "col3"), order: asc), OrderBy(
        reference: Reference(kind: rkId, id: "col4"), order: asc), OrderBy(reference: Reference(kind: rkId, id: "col5"), order: desc)]

  test "columns with functions":
    let res = nery:
      select myDbTable:
        col1
        col2
        avg(col3)
    assert res.toSql == """
SELECT
  col1,
  col2,
  avg(col3)
FROM
  myDbTable;"""
    assert res.reference.id == "myDbTable"
    assert res.columns == @[Reference(kind: rkId, id: "col1"), Reference(kind: rkId, id: "col2"), Reference(kind: rkFunction, function: "avg", arguments: @[Reference(kind: rkId, id: "col3")])]


  test "columns with functions and alias":
    let res = nery:
      select myDbTable:
        col1
        col2
        avg(col3) as myAvg
    assert res.toSql == """
SELECT
  col1,
  col2,
  avg(col3) AS myAvg
FROM
  myDbTable;"""
    assert res.reference.id == "myDbTable"
    assert res.columns == @[Reference(kind: rkId, id: "col1"), Reference(kind: rkId, id: "col2"), Reference(kind: rkFunction, function: "avg", alias: "myAvg", arguments: @[Reference(kind: rkId, id: "col3")])]

  test "columns with functions with multiple arguments":
    let res = nery:
      select myDbTable:
        col1
        col2
        coalesce(col3, col4)
    assert res.toSql == """
SELECT
  col1,
  col2,
  coalesce(col3,col4)
FROM
  myDbTable;"""
    assert res.reference.id == "myDbTable"
    assert res.columns == @[Reference(kind: rkId, id: "col1"), Reference(kind: rkId, id: "col2"), Reference(kind: rkFunction, function: "coalesce", arguments: @[Reference(kind: rkId, id: "col3"), Reference(kind: rkId, id: "col4")])]

  test "columns with nested functions":
    let res = nery:
      select myDbTable:
        col1
        col2
        coalesce(col3, avg(col4))
    assert res.toSql == """
SELECT
  col1,
  col2,
  coalesce(col3,avg(col4))
FROM
  myDbTable;"""
    assert res.reference.id == "myDbTable"
    assert res.columns == @[Reference(kind: rkId, id: "col1"), Reference(kind: rkId, id: "col2"), Reference(kind: rkFunction, function: "coalesce", arguments: @[Reference(kind: rkId, id: "col3"), Reference(kind: rkFunction, function: "avg", arguments: @[Reference(kind: rkId, id: "col4")])])]

  test "columns with nested functions and alias":
    let res = nery:
      select myDbTable:
        col1
        col2
        coalesce(col3, avg(col4)) as myCoalesce
    assert res.toSql == """
SELECT
  col1,
  col2,
  coalesce(col3,avg(col4)) AS myCoalesce
FROM
  myDbTable;"""
    assert res.reference.id == "myDbTable"
    assert res.columns == @[Reference(kind: rkId, id: "col1"), Reference(kind: rkId, id: "col2"), Reference(kind: rkFunction, function: "coalesce", alias: "myCoalesce", arguments: @[Reference(kind: rkId, id: "col3"), Reference(kind: rkFunction, function: "avg", arguments: @[Reference(kind: rkId, id: "col4")])])]
 
  test "where":
    let res = nery:
      select myDbTable:
        col1
        col2
        where:
          col3 == col4
    assert res.toSql == """
SELECT
  col1,
  col2
FROM
  myDbTable
WHERE
  col3 = col4;"""
    assert res.reference.id == "myDbTable"
    assert res.columns == @[Reference(kind: rkId, id: "col1"), Reference(kind: rkId, id: "col2")]
    assert res.where == @[Where(kind: wkBinary, op: "==", lhs: Reference(kind: rkId, id: "col3"), rhs: Reference(kind: rkId, id: "col4"))]

  test "where multiple":
    let res = nery:
      select myDbTable:
        col1
        col2
        where:
          col3 == col4
          col5 == col6
    assert res.toSql == """
SELECT
  col1,
  col2
FROM
  myDbTable
WHERE
  col3 = col4
  and
  col5 = col6;"""
    assert res.reference == Reference(kind: rkId, id: "myDbTable")
    assert res.reference.id == "myDbTable"
    assert res.columns == @[Reference(kind: rkId, id: "col1"), Reference(kind: rkId, id: "col2")]
    assert res.where == @[Where(kind: wkBinary, op: "==", lhs: Reference(kind: rkId, id: "col3"), rhs: Reference(kind: rkId, id: "col4")), Where(kind: wkUnary, val: "and"), Where(kind: wkBinary, op: "==", lhs: Reference(kind: rkId, id: "col5"), rhs: Reference(kind: rkId, id: "col6"))]

  test "where multiple and brackets":
    let res = nery:
      select myDbTable:
        col1
        col2
        where:
          col3 == col4
          (col5 == col6)
    assert res.toSql == """
SELECT
  col1,
  col2
FROM
  myDbTable
WHERE
  col3 = col4
  and
  (
   col5 = col6
  );"""
    assert res.reference.id == "myDbTable"
    assert res.columns == @[Reference(kind: rkId, id: "col1"), Reference(kind: rkId, id: "col2")]
    assert res.where == @[Where(kind: wkBinary, op: "==", lhs: Reference(kind: rkId, id: "col3"), rhs: Reference(kind: rkId, id: "col4")), Where(kind: wkUnary, val: "and"), Where(kind: wkUnary, val: "("), Where(kind: wkBinary, op: "==", lhs: Reference(kind: rkId, id: "col5"), rhs: Reference(kind: rkId, id: "col6")), Where(kind: wkUnary, val: ")")]

  test "where multiple and brackets":
    let res = nery:
      select myDbTable:
        col1
        col2
        where:
          col3 == col4
          (col5 == col6 and col7 == col8 and col9 == col10)
    assert res.toSql == """
SELECT
  col1,
  col2
FROM
  myDbTable
WHERE
  col3 = col4
  and
  (
   col5 = col6
   and
   col7 = col8
   and
   col9 = col10
  );"""
    assert res.reference.id == "myDbTable"
    assert res.columns == @[Reference(kind: rkId, id: "col1"), Reference(kind: rkId, id: "col2")]
    assert res.where == @[
      Where(
        kind: wkBinary,
        lhs: Reference(kind: rkId, id: "col3"),
        rhs: Reference(kind: rkId, id: "col4"),
        op: "=="
      ),
      Where(kind: wkUnary, val: "and"),
      Where(kind: wkUnary, val: "("),
      Where(
        kind: wkBinary,
        lhs: Reference(kind: rkId, id: "col5"),
        rhs: Reference(kind: rkId, id: "col6"),
        op: "=="
      ),
      Where(kind: wkUnary, val: "and"),
      Where(
        kind: wkBinary,
        lhs: Reference(kind: rkId, id: "col7"),
        rhs: Reference(kind: rkId, id: "col8"),
        op: "=="
      ),
      Where(kind: wkUnary, val: "and"),
      Where(
        kind: wkBinary,
        lhs: Reference(kind: rkId, id: "col9"),
        rhs: Reference(kind: rkId, id: "col10"),
        op: "=="
      ),
      Where(kind: wkUnary, val: ")")
    ]

  test "where multiple and/or brackets":
    let res = nery:
      select myDbTable:
        col1
        col2
        where:
          col3 == col4
          (col5 == col6 or col7 == col8 and col9 == col10)
    assert res.toSql == """
SELECT
  col1,
  col2
FROM
  myDbTable
WHERE
  col3 = col4
  and
  (
   col5 = col6
   or
   col7 = col8
   and
   col9 = col10
  );"""
    assert res.reference.id == "myDbTable"
    assert res.columns == @[Reference(kind: rkId, id: "col1"), Reference(kind: rkId, id: "col2")]
    assert res.where == @[
      Where(
        kind: wkBinary,
        lhs: Reference(kind: rkId, id: "col3"),
        rhs: Reference(kind: rkId, id: "col4"),
        op: "=="
      ),
      Where(kind: wkUnary, val: "and"),
      Where(kind: wkUnary, val: "("),
      Where(
        kind: wkBinary,
        lhs: Reference(kind: rkId, id: "col5"),
        rhs: Reference(kind: rkId, id: "col6"),
        op: "=="
      ),
      Where(kind: wkUnary, val: "or"),
      Where(
        kind: wkBinary,
        lhs: Reference(kind: rkId, id: "col7"),
        rhs: Reference(kind: rkId, id: "col8"),
        op: "=="
      ),
      Where(kind: wkUnary, val: "and"),
      Where(
        kind: wkBinary,
        lhs: Reference(kind: rkId, id: "col9"),
        rhs: Reference(kind: rkId, id: "col10"),
        op: "=="
      ),
      Where(kind: wkUnary, val: ")")
    ]

  test "where multiple and/or brackets and functions":
    let res = nery:
      select myDbTable:
        col1
        col2
        where:
          myFun(col3) == col4
          col5 == myFun2(myFun3(col6, myFun4(col7)))
          (col8 == myFunc5(col9) or myFunc6(col10) == col11)
    assert res.toSql == """
SELECT
  col1,
  col2
FROM
  myDbTable
WHERE
  myFun(col3) = col4
  and
  col5 = myFun2(myFun3(col6,myFun4(col7)))
  and
  (
   col8 = myFunc5(col9)
   or
   myFunc6(col10) = col11
  );"""
    assert res.reference.id == "myDbTable"
    assert res.columns == @[Reference(kind: rkId, id: "col1"), Reference(kind: rkId, id: "col2")]
    assert res.where == @[
      Where(
        kind: wkBinary,
        lhs: Reference(alias: "", prefix: "", kind: rkFunction, function: "myFun", arguments: @[Reference(alias: "", prefix: "", kind: rkId, id: "col3")]),
        rhs: Reference(alias: "", prefix: "", kind: rkId, id: "col4"),
        op: "=="
      ),
      Where(kind: wkUnary, val: "and"),
      Where(
        kind: wkBinary,
        lhs: Reference(alias: "", prefix: "", kind: rkId, id: "col5"),
        rhs: Reference(
          alias: "",
          prefix: "",
          kind: rkFunction,
          function: "myFun2",
          arguments: @[
            Reference(
              alias: "",
              prefix: "",
              kind: rkFunction,
              function: "myFun3",
              arguments: @[
                Reference(alias: "", prefix: "", kind: rkId, id: "col6"),
                Reference(alias: "", prefix: "", kind: rkFunction, function: "myFun4", arguments: @[Reference(alias: "", prefix: "", kind: rkId, id: "col7")])
              ]
            )
          ]
        ),
        op: "=="
      ),
      Where(kind: wkUnary, val: "and"),
      Where(kind: wkUnary, val: "("),
      Where(
        kind: wkBinary,
        lhs: Reference(alias: "", prefix: "", kind: rkId, id: "col8"),
        rhs: Reference(alias: "", prefix: "", kind: rkFunction, function: "myFunc5", arguments: @[Reference(alias: "", prefix: "", kind: rkId, id: "col9")]),
        op: "=="
      ),
      Where(kind: wkUnary, val: "or"),
      Where(
        kind: wkBinary,
        lhs: Reference(alias: "", prefix: "", kind: rkFunction, function: "myFunc6", arguments: @[Reference(alias: "", prefix: "", kind: rkId, id: "col10")]),
        rhs: Reference(alias: "", prefix: "", kind: rkId, id: "col11"),
        op: "=="
      ),
      Where(kind: wkUnary, val: ")")
    ]

  test "where multiple nested brackets":
    let res = nery:
      select myDbTable:
        col1
        col2
        where:
          col3 == col4
          col5 == col6
          (col7 == col8 or (col9 == col10 and col11 == col12))
    assert res.toSql == """
SELECT
  col1,
  col2
FROM
  myDbTable
WHERE
  col3 = col4
  and
  col5 = col6
  and
  (
   col7 = col8
   or
   (
    col9 = col10
    and
    col11 = col12
   )
  );"""
    assert res.reference.id == "myDbTable"
    assert res.columns == @[Reference(kind: rkId, id: "col1"), Reference(kind: rkId, id: "col2")]
    assert res.where == @[
      Where(
        kind: wkBinary,
        lhs: Reference(alias: "", prefix: "", kind: rkId, id: "col3"),
        rhs: Reference(alias: "", prefix: "", kind: rkId, id: "col4"),
        op: "=="
      ),
      Where(kind: wkUnary, val: "and"),
      Where(
        kind: wkBinary,
        lhs: Reference(alias: "", prefix: "", kind: rkId, id: "col5"),
        rhs: Reference(alias: "", prefix: "", kind: rkId, id: "col6"),
        op: "=="
      ),
      Where(kind: wkUnary, val: "and"),
      Where(kind: wkUnary, val: "("),
      Where(
        kind: wkBinary,
        lhs: Reference(alias: "", prefix: "", kind: rkId, id: "col7"),
        rhs: Reference(alias: "", prefix: "", kind: rkId, id: "col8"),
        op: "=="
      ),
      Where(kind: wkUnary, val: "or"),
      Where(kind: wkUnary, val: "("),
      Where(
        kind: wkBinary,
        lhs: Reference(alias: "", prefix: "", kind: rkId, id: "col9"),
        rhs: Reference(alias: "", prefix: "", kind: rkId, id: "col10"),
        op: "=="
      ),
      Where(kind: wkUnary, val: "and"),
      Where(
        kind: wkBinary,
        lhs: Reference(alias: "", prefix: "", kind: rkId, id: "col11"),
        rhs: Reference(alias: "", prefix: "", kind: rkId, id: "col12"),
        op: "=="
      ),
      Where(kind: wkUnary, val: ")"),
      Where(kind: wkUnary, val: ")")
    ]
