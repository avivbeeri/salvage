import "./dir" for Dir
import "./action" for MoveAction
import "./events" for BoltEvent, EnergyDepletedEvent
import "./actor" for Player
import "./line" for LineVisitor
import "math" for Vec
import "./tiles" for Tiles

class GameResult {
  progress=(v) { _progress = v}
  progress { _progress }
  events { _events }
  alternate { _alternate }
  alternate=(v) { _alternate = v}

  construct new() {
    _progress = false
    _events = []
    _alternate = null
  }
}


class GameModel {
  map { _map }
  player { _player }
  entities { _entities }
  energy { _entities[_turn].energy }
  turn { _turn }
  isPlayerTurn() { _entities[_turn] == _player }

  construct level(level) {
    _map = level.map
    _entities = level.entities
    _entities.each{|entity| entity.bindGame(this) }
    _rooms = level.data
    _player = _entities.where {|entity| entity.type == "player" }.toList[0]
    _turn = 0
    recalculate()

  }
  construct level(map, entities) {
    _map = map
    _entities = entities
    _entities.each{|entity| entity.bindGame(this) }
    _player = _entities.where {|entity| entity.type == "player" }.toList[0]
    _turn = 0
    recalculate()
  }

  nextTurn() {
    _turn = (_turn + 1) % _entities.count
  }

  currentActor { _entities[_turn] }

  process() {
    var actor = currentActor
    if (actor.canTakeTurn && actor.needsInput) {
      return GameResult.new()
    }
    var action = null
    while (action == null) {
      actor = currentActor
      if (actor.canTakeTurn || actor.gain()) {
        if (actor.needsInput) {
          return GameResult.new()
        }
        action = actor.getAction()
      } else {
        nextTurn()
      }
    }
    action.bind(actor)
    _result = GameResult.new()
    _result.progress = action.perform(_result)
    while (_result.alternate != null) {
      action = _result.alternate
      _result.alternate = null
      action.bind(actor)
      _result.progress = action.perform(_result)
    }

    // Some actions should consume energy on failure
    if (_result.progress) {
      actor.finishTurn(action)
      recalculate()
      nextTurn()
    }

    return _result
  }

  recalculate() {
    var facing = Dir[_player.state["facing"]]
    var min = _player.pos
    var cone = facing * 10
    var max = _player.pos + cone

    recalculateRooms()

    var base = _player.pos - facing
    for (line in 0..cone.manhattan) {
      for (scan in -line..line) {
        var current = base + facing.perp * scan
        var points = LineVisitor.walk(_player.pos, current)
        var visible = true
        for (index in 0...points.count) {
          var tile = getTileAt(points[index])
          tile["seen"] = true
          if (tile["light"] == null || tile["light"] < 2) {
            tile["light"] = 2
            if (visible && !tile["obscure"]) {
              for (j in -1..1) {
                for (i in -1..1) {
                  var point = points[index] + Vec.new(i, j)
                  var nextTile = getTileAt(point)
                  if (nextTile["obscure"]) {
                    nextTile["light"] = 2
                  }
                }
              }
            }
          }

          if (tile["obscure"]) {
            break
          }
        }
      }
      base = base + facing
    }

    for (entity in _entities) {
      if (entity != _player) {
        var tile = getTileAt(entity.pos)
        entity.visible = tile["light"] == 2
      }
    }
  }

  getEntityRooms(entity) {
    return _rooms.where {|room| room.isInRoom(entity.pos) }.toList
  }

  recalculateRooms() {
    var lighting = []
    _rooms.each {|room|
      var player = _player
      if (room.isInRoom(player.pos) && room.light) {
        lighting.add(room)
      } else {
        room.setDarkness()
      }
    }
    entities.each {|entity|
      if (entity != _player) {
        entity.visible = lighting.count > 0 && lighting.any {|room| room.isInRoom(entity.pos) }
      }
    }
    lighting.each {|room|
      room.setTileProperty("light", 2)
      room.setTileProperty("seen", true)
    }
  }

  getTileAt(vec) { getTileAt(vec.x, vec.y) }
  getTileAt(x, y) {
    return _map.get(x, y)
  }

  isTileSolid(x, y) {
    return getTileAt(x, y)["solid"]
  }

  isTileValid(x, y) {
    return (x >= 0 && x < map.width && y >= 0 && y < map.height)
  }

  doesTileContainEntity(x, y) {
    return _entities.any {|entity| entity.x == x && entity.y == y }
  }

  getEntitiesOnTile(x, y) {
    return _entities.where {|entity| entity.x == x && entity.y == y }.toList
  }

  addEventToResult(event) {
    if (_result != null) {
      _result.events.add(event)
    } else {
      Fiber.abort("Tried to add an event without a result")
    }
  }

  destroyEntity(entity) {
    _entities = _entities.where {|e| e != entity }.toList
    entity.onDestroy()
  }
}

