import "math" for Vec, M
import "./map" for TileMap, Tile
import "./actor" for Player, Blob
import "./tiles" for Tiles

import "./test" for FloorGenerator, R

var NameIndex = 0
var Roomnames = [
  ["corridor"],
  ["bridge"],
  ["cargo hold"],
  ["kitchen"],
  ["common area"],
  ["laboratory"],
  ["recreation"],
  ["crew quarters"],
  ["reactor"],
  ["recycling"],
  ["hydroponics"],
  ["observation"],
  ["canteen"],
  ["medical bay"],
  ["brig"],
  ["quarantine"],
  ["grav core"],
  ["air processing"],
  ["airlock"]
]
R.shuffle(Roomnames)

class Room {
  construct new(pos, size) {
    init(pos, size)
    NameIndex = (NameIndex + 1) % Roomnames.count
    _name = Roomnames[NameIndex][0]
  }
  construct new(pos, size, name) {
    init(pos, size)
    _name = name
  }

  init(pos, size) {
    _size = size
    _pos = pos
    _doors = []
    _tiles = []
    _features = []
  }
  print() {
    var start = pos
    var max = pos + size - Vec.new(1, 1)
    for (y in start.y .. max.y) {
      for (x in start.x .. max.x) {
        if (_map.get(x, y).type == Tiles.empty.type) {
          if (y == start.y || y == max.y || x == start.x || x == max.x) {
            addTile(x, y, Tiles.wall)
          } else {
            if (_name == "") {

            } else {
              addTile(x, y, Tiles.floor)
            }
          }
        } else {
          tiles.add(_map.get(x, y))
        }
      }
    }
  }

  map=(v) { _map = v }

  pos { _pos }
  size { _size }
  width { _size.x }
  height { _size.y }
  doors { _doors }
  tiles { _tiles }
  features { _features }
  name { _name }

  light { _light }
  light=(v) { _light = v }

  isInRoom(vec) { isInRoom(vec.x, vec.y) }
  isInRoom(x, y) {
    var max = pos + size
    return x >= pos.x &&
      x < max.x &&
      y >= pos.y &&
      y < max.y
  }

  addTile(x, y, tile) {
    if (!_map) {
      Fiber.abort("No map bound to room")
    }
    if (_map.get(x, y).type != tile.type) {
      _map.set(x, y, tile)
    }
    tiles.add(_map.get(x, y))
  }

  setDarkness() {
    _tiles.each {|tile|
      tile["light"] = tile["seen"] ? 1 : 0
    }
  }

  setTileProperties(pairs) {
    // Expect pairs as a list of 2-element lists of key=value
    _tiles.each {|tile|
      for (pair in pairs) {
        tile[pair[0]] = pair[1]
      }
    }
  }

  setTileProperty(key, value) {
    _tiles.each {|tile| tile[key] = value }
  }
}

class Level {
  construct new(map, entities, data) {
    _map = map
    _entities = entities
    _data = data
    _player = null
  }

  addPlayer(player) {
    _player = player
    _entities.insert(0, player)
  }

  player { _player }

  map { _map }
  entities { _entities }
  data { _data }
}

class RoomGenerator {
  static generate(seed) {}
}

var ROOM_WIDTH = 16
var ROOM_HEIGHT = 16

class StaticRoomGenerator {
  static generate(seed) {
    var generator = FloorGenerator.init()
    var rooms = generator.rooms
    //rooms = FloorGenerator.generate(0 ,0)
    var map = TileMap.init(320, 320, Tiles.empty)
    var doors = []
    for (room in rooms) {
      room.map = map
      room.print()
      // TODO: Set properties of room

      for (door in room.doors) {
        doors.add(door)
      }

      room.setTileProperty("light", 2)
    }
    for (corridor in generator.corridors) {
      var width = 3
      var perp = corridor[1].perp
      var cross = corridor[1].perp * width
      var len = perp * width
      System.print(" --- carving ")
      var start = corridor[0]
      System.print("Door is at %(start) -> %(corridor[1])")
      var pos = start + corridor[1]
      var tile = map.get(pos)
      while (tile.type == Tiles.empty.type || tile.type == Tiles.door.type) {
        if (tile.type == Tiles.door.type) {
        } else if (tile.type == Tiles.empty.type) {
          map.set(pos.x, pos.y, Tiles.floor)
        }
        pos = pos + corridor[1]
        len = len + corridor[1]
        tile = map.get(pos)
      }
      len = pos - start + cross
      // calculate top-left
      var minX = start.x + M.min(0, len.x) - (cross.x / 2).floor
      var minY = start.y + M.min(0, len.y) - (cross.y / 2).floor
      var topLeft = Vec.new(minX, minY) - corridor[1]
      len = Vec.new(len.x.abs, len.y.abs)

      System.print("Corridor dimensions:")
      System.print(Vec.new(minX, minY))
      System.print(len)
      var room = Room.new(Vec.new(minX, minY), len, "corridor")
      room.map = map
      room.light = R.int(2) % 2 == 0
      room.print()
      room.doors.add(start)
      room.doors.add(pos)
      for (door in room.doors) {
        doors.add(door)
      }
      rooms.add(room)
    }

    rooms.each {|room|
      doors.each {|door|
        if (room.isInRoom(door)) {
          room.addTile(door.x, door.y, Tiles.door)
        }
      }

      if (room.name == "reactor") {
        System.print("reactor!")
        map.set(room.pos.x + 2, room.pos.y + 2, Tiles.console)
        room.tiles.add(map.get(room.pos.x + 2, room.pos.y + 2))
      }
    }

    var entities = []
    map.set(14, 4, Tiles.sludge)
    rooms.each {|room|
      if (room.isInRoom(14, 4)) {
        room.tiles.add(map.get(14, 4))
      }

      if (R.int(3) % 2 == 0) {
        var blob = Blob.new(1 + room.pos.x + R.int(room.size.x - 2), 1 + room.pos.y + R.int(room.size.y - 2))
        entities.add(blob)
      }


    }

    var level = Level.new(map, entities, rooms)
    level.addPlayer(Player.new(rooms[0].pos.x + 1, rooms[0].pos.y + 1))
    System.print("player: %(Vec.new(rooms[0].pos.x + 1, rooms[0].pos.y + 1))")


    rooms.each {|room|
      var player = level.player
      if (room.isInRoom(player.pos)) {
        room.setTileProperty("dark", false)
      }
    }

    return level
  }
}

/*

class FloorGenerator {
  static generateDebugRooms() {
    var room1 = Room.new(Vec.new(), Vec.new(ROOM_WIDTH, ROOM_HEIGHT))
    room1.light = false
    var room2 = Room.new(Vec.new(ROOM_WIDTH - 1, ROOM_HEIGHT / 2), Vec.new(ROOM_WIDTH, 3))
    room2.light = true
    var room3 = Room.new(Vec.new(ROOM_WIDTH * 2 - 2, 0), Vec.new(ROOM_WIDTH, ROOM_HEIGHT))
    room1.doors.add(Vec.new(ROOM_WIDTH - 1, ROOM_HEIGHT / 2 + 1))
    room2.doors.add(Vec.new(ROOM_WIDTH*2 - 2, ROOM_HEIGHT / 2 + 1))
    return [room1, room2, room3]
  }
}
*/
