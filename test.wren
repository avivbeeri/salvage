import "random" for Random
import "input" for Keyboard
import "graphics" for Canvas, Color
import "math" for Vec, M
import "./generator" for Room

import "./adt" for Queue

var R = Random.new(5)
var ROOM_HEIGHT = 16
var ROOM_WIDTH = 16

class Area {
  construct new(pos, size) {
    _pos = pos
    _size = size
    _exits = []
  }
  size { _size }
  pos { _pos }
  exits { _exits }
}

var CONNECT_SIZE = Vec.new(9, 9)
var HAB_SIZE = Vec.new(32, 32)

class Game {
  static init() {
    Canvas.resize(114, 114)
    __areas = generate()
    __rooms = paintRooms()
  }

  static areaExists(pos, areas) {
    return (areas.count == 0 || !areas.any {|area| area.pos == pos})

  }

  static validRoom(pos) {
    return (pos.x >= 0 && pos.y >= 0 && pos.x < 3 && pos.y < 3)
  }
  static paintRooms() {
    System.print("--- painting ---")
    var rooms = []

    for (area in __areas) {
      var center = Vec.new(area.pos.x * (HAB_SIZE.x + CONNECT_SIZE.x), area.pos.y * (HAB_SIZE.y + CONNECT_SIZE.y)) + HAB_SIZE * 0.5
      System.print(center)

      var nextPos = []
      var quadrants = [
        Vec.new(-1, -1),
        Vec.new(-1, 0),
        Vec.new(0, 0),
        Vec.new(0, -1)
      ]
      var doorPos = [
        Vec.new(0, 1),
        Vec.new(-1, 0),
        Vec.new(1, 0),
        Vec.new(0, -1),
      ]

      var prev = null
      for (i in 0...quadrants.count) {

        var quadrant = quadrants[i]
        var dir = doorPos[i]
        var height = R.int(5, ROOM_HEIGHT)
        var width = R.int(5, ROOM_WIDTH)
        var pos = center + Vec.new((width - 1) * quadrant.x, (height - 1) * quadrant.y)
        var dim = Vec.new(width, height)
        // System.print("%(pos) -> %(pos + dim)")
        var room = Room.new(pos, dim)
        rooms.add(room)
        room.doors.add(center)

        var len = M.min(width.abs, height.abs)
        if (i < quadrants.count - 1 && prev != null) {
          len = M.min(M.min(prev.size.x, prev.size.y), len)
        } else if (prev != null) {
          len = 4
        } else {
          len = 4
        }
        prev = room

        var n = R.int(3, len - 1)
        var door = center + dir * n
        System.print("door: %(len) - > %(door)")

        room.doors.add(door)

        // Add door(s)?
        // Environmental properties
        room.light = R.int(2) % 2 == 0
      }

      for (exit in area.exits) {
        // output corridors between areas
      }

    }

    return rooms
  }

  static generate() {
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

  static update() {
    if (Keyboard.isKeyDown("space")) {
      __areas = generate()
      __rooms = paintRooms()
    }
  }
  static draw(alpha) {
    Canvas.cls()
    var exits = []
    for (area in __areas) {
      Canvas.rect(area.pos.x * (HAB_SIZE.x + CONNECT_SIZE.x), area.pos.y * (HAB_SIZE.y + CONNECT_SIZE.y), area.size.x, area.size.y, Color.red)
      var center = ((area.pos) * (HAB_SIZE.x + CONNECT_SIZE.x)) + (HAB_SIZE / 2)
      Canvas.pset(center.x, center.y, Color.orange)
      for (exit in area.exits) {
        var out = center + (exit * (1 + HAB_SIZE.x / 2))
        Canvas.pset(out.x, out.y, Color.green)
      }
    }
    for (room in __rooms) {
      Canvas.rect(room.pos.x, room.pos.y, room.size.x, room.size.y, Color.red)
      exits = exits + room.doors
    }
    for (exit in exits) {
      Canvas.pset(exit.x, exit.y, Color.blue)
    }
  }

}
