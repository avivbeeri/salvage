import "math" for Vec
import "random" for Random
import "./map" for TileMap, Tile
import "./actor" for Player, Blob
import "./tiles" for Tiles

var NameIndex = 0
var Roomnames = [
  "corridor",
  "bridge",
  "cargo hold",
  "kitchen",
  "common area",
  "laboratory",
  "recreation room",
  "sleeping quarters",
  "reactor",
  "waste processing",
  "hydroponics bay",
  "observation deck",
  "canteen",
  "medical bay",
  "brig",
  "containment room",
  "gravitational core",
  "air processing",
  "airlock"
]
var R = Random.new(12345)

class Feature {
  construct new(type, pos) {
    _type = type
    _pos = pos
  }
  pos { _pos }
  type { _type }
}

class Room {
  construct new(pos, size) {
    _size = size
    _pos = pos
    // R.shuffle(Roomnames)
    _name = Roomnames[NameIndex]
    NameIndex = (NameIndex + 1) % Roomnames.count
    _doors = []
    _tiles = []
    _features = []
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
    var rooms = []
    /*
    for (gridY in 0...5) {
      for (gridX in 0...5) {
        var room = Room.new(Vec.new(gridX * (ROOM_WIDTH - 1), gridY * (ROOM_HEIGHT - 1)), Vec.new(ROOM_WIDTH, ROOM_HEIGHT))
        room.doors.add(Vec.new(gridX * (ROOM_WIDTH - 1) + ROOM_WIDTH - 1, 4))
        rooms.add(room)
      }
    }
    */

    var room1 = Room.new(Vec.new(), Vec.new(ROOM_WIDTH, ROOM_HEIGHT))
    room1.light = false
    var room2 = Room.new(Vec.new(ROOM_WIDTH - 1, ROOM_HEIGHT / 2), Vec.new(ROOM_WIDTH, 3))
    room2.light = true
    var room3 = Room.new(Vec.new(ROOM_WIDTH * 2 - 2, 0), Vec.new(ROOM_WIDTH, ROOM_HEIGHT))
    room1.doors.add(Vec.new(ROOM_WIDTH - 1, ROOM_HEIGHT / 2 + 1))
    room2.doors.add(Vec.new(ROOM_WIDTH*2 - 2, ROOM_HEIGHT / 2 + 1))
    rooms = [room1, room2, room3]

    var map = TileMap.init(320, 320, Tiles.empty)
    for (room in rooms) {
      room.map = map
      var start = room.pos
      var max = room.pos + room.size - Vec.new(1, 1)
      for (y in start.y .. max.y) {
        for (x in start.x .. max.x) {
          if (map.get(x, y).type == Tiles.empty.type) {
            if (y == start.y || y == max.y || x == start.x || x == max.x) {
              room.addTile(x, y, Tiles.wall)
            } else {
              room.addTile(x, y, Tiles.floor)
            }
          } else {
            room.tiles.add(map.get(x, y))
          }
        }
      }

      for (door in room.doors) {
        /*
        if (map.get(door.x, door.y).type != Tiles.door.type) {
           map.set(door.x, door.y, Tiles.door)
        }
        room.tiles.add(map.get(door.x, door.y))
        */
        room.addTile(door.x, door.y, Tiles.door)
      }

      for (feature in room.features) {

      }

      room.setTileProperty("light", 2)
    }

    map.set(3, 2, Tiles.teleport)
    map.set(14, 4, Tiles.sludge)
    rooms.each {|room|
      if (room.isInRoom(14, 4)) {
        room.tiles.add(map.get(14, 4))
      }
    }


/*
    map.set(3, 0, Tiles.teleport)
    for (x in 0...7) {
      map.set(x, 4, Tiles.wall)
    }
    */
    var entities = [
      Blob.new(14, 5),
      Blob.new(5, 3)
    ]

    var level = Level.new(map, entities, rooms)
    level.addPlayer(Player.new(4, 4))

    rooms.each {|room|
      var player = level.player
      if (room.isInRoom(player.pos)) {
        room.setTileProperty("dark", false)
      }
    }

    return level
  }
}
