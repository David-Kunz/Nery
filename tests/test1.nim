# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import Nery

suite "selects":
  test "without columns":
    let res = query:
      select myDbTable()
    assert(res.entity == "myDbTable")
    assert(res.columns == @["*"])

  test "with columns":
    let res = query:
      select myDbTable(col1, col2)
    assert(res.entity == "myDbTable")
    assert(res.columns == @["col1", "col2"])
