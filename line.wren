import "math" for M, Vec

class LineVisitor {
  static walk(p0, p1) {
    var d = p1 - p0
    var nx = M.abs(d.x)
    var ny = M.abs(d.y)
    var signX = M.sign(d.x)
    var signY = M.sign(d.y)

    var p = Vec.new(p0.x, p0.y)
    var points = [Vec.new(p.x, p.y)]
    var ix = 0
    var iy = 0

    while (ix < nx || iy < ny) {
      if (((0.5 + ix) / nx) < ((0.5 + iy) / ny)) {
        // horizontal step
        p.x = p.x + signX
        ix = ix + 1
      } else {
        // vertical step
        p.y = p.y + signY
        iy = iy + 1
      }
      points.add(Vec.new(M.round(p.x), M.round(p.y)))
    }

    return points
  }
}

