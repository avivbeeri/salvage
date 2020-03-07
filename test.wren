import "random" for Random
import "input" for Keyboard
import "graphics" for Canvas, Color
import "math" for Vec, M

import "./adt" for Queue

var SystemRandom = Random.new()
var Seed = SystemRandom.int(32767)
System.print(Seed)
var R = Random.new(Seed)
var ROOM_HEIGHT = 12
var ROOM_WIDTH = 12

class Area {
  construct new(pos, size) {
    _pos = pos
    _size = size
    _rooms = []
    _exits = []
  }
  size { _size }
  pos { _pos }
  exits { _exits }
  rooms { _rooms }
}

var CONNECT_SIZE = Vec.new(5, 5)
var HAB_SIZE = Vec.new(ROOM_WIDTH * 2, ROOM_HEIGHT * 2)

class Game {
  static init() {
    Canvas.resize(114, 114)
    __generator = FloorGenerator.init()
      drawOnce(0)
  }
  static update() {
    if (Keyboard.isKeyDown("space")) {
      Canvas.cls()
      __generator = FloorGenerator.init()
      drawOnce(0)
    }
  }


  static draw(alpha) {}
  static drawOnce(alpha) {
    // Canvas.cls()
    var areas = __generator.areas
    var rooms = __generator.rooms
    var corridors = __generator.corridors
    var exits = []
    for (area in areas) {
      // Canvas.rect(area.pos.x * (HAB_SIZE.x + CONNECT_SIZE.x), area.pos.y * (HAB_SIZE.y + CONNECT_SIZE.y), area.size.x, area.size.y, Color.red)
      var center = ((area.pos) * (HAB_SIZE.x + CONNECT_SIZE.x)) + (HAB_SIZE / 2)
      Canvas.pset(center.x, center.y, Color.orange)
      for (exit in area.exits) {
        var out = center + (exit * (1 + HAB_SIZE.x / 2))
        Canvas.pset(out.x, out.y, Color.green)
      }
    }
    for (room in rooms) {
      Canvas.rect(room.pos.x, room.pos.y, room.size.x, room.size.y, Color.red)
      exits = exits + room.doors
    }
    for (exit in exits) {
      Canvas.pset(exit.x, exit.y, Color.blue)
    }

    for (corridor in corridors) {
      var pos = corridor[0]
      Canvas.pset(pos.x, pos.y, Color.green)
      while (Canvas.pget(pos.x, pos.y).toNum == Color.black.toNum || Canvas.pget(pos.x, pos.y).toNum == Color.green.toNum) {
        if (Canvas.pget(pos.x, pos.y).toNum == Color.green.toNum) {
        } else {
          Canvas.pset(pos.x, pos.y, Color.purple)
        }
        pos = pos + corridor[1]
      }
      Canvas.pset(pos.x, pos.y, Color.green)
      // Canvas.line(corridor[0].x, corridor[0].y, corridor[1].x, corridor[1].y, Color.purple)
    }
  }

}

class FloorGenerator {
  construct init() {
    while (_areas == null || _areas.count < 3) {
      _areas = generate()
    }

    _rooms = paintRooms()
    _corridors = []
    paintCorridors()
  }
  corridors { _corridors }
  areas { _areas }
  rooms { _rooms }

  getArea(pos) {
    for (area in _areas) {
      if (area.pos == pos) {
        return area
      }
    }
  }

  floorVec(vec) {
    var result = vec * 1
    result.x = result.x.floor
    result.y = result.y.floor
    return result
  }

  paintCorridors() {
    import "./generator" for Room
    System.print(_areas)
    for (area in _areas) {
      var areaCenter = (area.pos * (HAB_SIZE.x + CONNECT_SIZE.x) + (HAB_SIZE / 2))
      for (exit in area.exits) {
        var pairs = null
        var target = getArea(area.pos + exit)

        for (sourceRoom in area.rooms) {
          for (targetRoom in target.rooms) {
            var sourceCenter = (sourceRoom.pos + sourceRoom.size / 2)
            var targetCenter = (targetRoom.pos + targetRoom.size / 2)
            sourceCenter = (sourceCenter)
            targetCenter = (targetCenter)
            Canvas.pset(sourceCenter.x, sourceCenter.y, Color.purple)
            Canvas.pset(targetCenter.x, targetCenter.y, Color.purple)
            if (pairs == null) {
              pairs = [sourceCenter, targetCenter, sourceRoom, targetRoom]
            } else {
              if ((sourceCenter - targetCenter).manhattan.abs < (pairs[0] - pairs[1]).manhattan.abs) {
                pairs = [sourceCenter, targetCenter, sourceRoom, targetRoom]
              }
            }
          }
        }

        Canvas.pset(pairs[1].x, pairs[1].y, Color.purple)
        Canvas.pset(pairs[0].x, pairs[0].y, Color.purple)

        var sourceCenter = pairs[0]
        var sourceRoom = pairs[2]
        var targetCenter = pairs[1]
        var targetRoom = pairs[3]

        var sourceDim = (sourceRoom.size / 2)
        var sourceExitPos = (sourceCenter + Vec.new(exit.x * sourceDim.x, exit.y * sourceDim.y))

        var pos = sourceExitPos
        if (exit.x > 0 || exit.y > 0) {
          pos = pos - exit
        }
        _corridors.add([pos, exit])
        System.print("%(area.pos) <--> %(target.pos)")
      }
    }
  }

  areaExists(pos, areas) {
    return (areas.count == 0 || !areas.any {|area| area.pos == pos})
  }

  validRoom(pos) {
    return (pos.x >= 0 && pos.y >= 0 && pos.x < 3 && pos.y < 3)
  }

  paintRooms() {
    import "./generator" for Room
    System.print("--- painting ---")
    var rooms = []

    for (area in _areas) {
      var center = Vec.new(area.pos.x * (HAB_SIZE.x + CONNECT_SIZE.x), area.pos.y * (HAB_SIZE.y + CONNECT_SIZE.y)) + HAB_SIZE * 0.5
      System.print(center)

      var nextPos = []
      var quadrants = [
        Vec.new(-1, -1),
        Vec.new(-1, 0),
        Vec.new(0, 0),
        Vec.new(0, -1)
      ]
      System.print(quadrants)
      var doorPos = [
        Vec.new(0, 1),
        Vec.new(-1, 0),
        Vec.new(1, 0),
        Vec.new(0, -1),
      ]

      var prev = null
      var first = null
      var quad = 4// quadrants.count
      var order = (0...quad).toList
      for (i in order) {

        var quadrant = quadrants[i]

        var dir = doorPos[i]
        var height = R.int(5, ROOM_HEIGHT)
        var width = R.int(5, ROOM_WIDTH)
        if (height % 2 == 1) {
          height = height + 1
        }
        if (width % 2 == 1) {
          width = width + 1
        }
        var pos = center + Vec.new((width - 1) * quadrant.x, (height - 1) * quadrant.y)
        var dim = Vec.new(width, height)
        // System.print("%(pos) -> %(pos + dim)")
        var room = Room.new(pos, dim)

        // Add door(s)?
        if (i < quadrants.count - 1) {
          var len = M.min(width.abs, height.abs)
          if (prev != null) {
            len = M.min(M.min(prev.size.x, prev.size.y), len) - 1
          } else if (prev == null) {
            first = room
            len = 4
          }
          prev = room

          var n = R.int(2, len-1)
          var door = center + dir * n
          System.print("door: %(len) - > %(door)")

          room.doors.add(door)

        }
        // Environmental properties
        room.light = R.int(2) % 2 == 0

        rooms.add(room)
        area.rooms.add(room)
      }

      for (exit in area.exits) {
        // output corridors between areas
      }

    }

    return rooms
  }

  generate() {
    System.print("---")
    var areas = []
    var rX = 1
    var rY = 1
    var next = Queue.init()
    next.enqueue(Vec.new(rX, rY))
    var min = 3
    while (!next.empty) {
      var place = next.dequeue()
      if (areaExists(place, areas)) {


        System.print(place)
        var area = Area.new(Vec.new(place.x, place.y), HAB_SIZE)
        areas.add(area)
          if (this.validRoom(place + Vec.new(1, 0)) && areaExists(place + Vec.new(1, 0), areas)) {
        if (R.int(3) % 3 == 0) {
            area.exits.add(Vec.new(1, 0))
            next.enqueue(place + Vec.new(1, 0))
          }
        }
          if (this.validRoom(place + Vec.new(-1, 0)) && areaExists(place + Vec.new(-1, 0), areas)) {
        if (R.int(3) % 3 == 0) {
            area.exits.add(Vec.new(-1, 0))
            next.enqueue(place + Vec.new(-1, 0))
          }
        }
          if (this.validRoom(place + Vec.new(0, 1)) && areaExists(place + Vec.new(0, 1), areas)) {
        if (R.int(3) % 3 == 0) {
            area.exits.add(Vec.new(0, 1))
            next.enqueue(place + Vec.new(0, 1))
          }
        }
          if (this.validRoom(place + Vec.new(0, -1)) && areaExists(place + Vec.new(0, -1), areas)) {
        if (R.int(3) % 3 == 0) {
            area.exits.add(Vec.new(0, -1))
            next.enqueue(place + Vec.new(0, -1))
          }
        }
      }
    }
    return areas
  }
}
