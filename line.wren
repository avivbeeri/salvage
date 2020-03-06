import "math" for M, Vec
import "./adt" for Queue
import "./map" for Elegant

var DIRS = [
  Vec.new(0, 1),
  Vec.new(-1, 0),
  Vec.new(1, 0),
  Vec.new(0, -1),
]

class GridVisitor {
  static bfs(map, start, test) {
    var frontier = Queue.init()
    var visited = {}
    visited[Elegant.pair(start)] = true
    frontier.enqueue(start)
    while (!frontier.empty) {
      var current = frontier.dequeue()
      // TODO: This should do something
      if (test != null) {
        test.call(current)
      }
      for (dir in DIRS) {
        var next = current + dir
        if (next.x < 0 || next.x >= map.width || next.y < 0 || next.y >= map.height) {
        } else {
          if (!visited[Elegant.pair(next)]) {
            frontier.enqueue(next)
            visited[Elegant.pair(next)] = true
          }
        }
      }
    }
  }
  static findPath(map, start) {
    var frontier = Queue.init()
    var cameFrom = {}
    cameFrom[Elegant.pair(start)] = null
    frontier.enqueue(start)
    while (!frontier.empty) {
      var current = frontier.dequeue()
      for (dir in DIRS) {
        var next = current + dir
        if (next.x < 0 || next.x >= map.width || next.y < 0 || next.y >= map.height) {
        } else {
          if (!cameFrom.containsKey(Elegant.pair(next))) {
            frontier.enqueue(next)
            cameFrom[Elegant.pair(next)] = current
          }
        }
      }
    }
    return cameFrom
  }
}

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

