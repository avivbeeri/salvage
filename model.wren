import "./dir" for Dir
import "./action" for MoveAction
import "./events" for LogEvent, GameOverEvent
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
  turn { _turn }
  isPlayerTurn() { _entities[_turn] == _player }
  state { _data }
  [index] { _data[index] }
  [index]=(v) { _data[index] = v }

  construct level(level) {
    _map = level.map
    _entities = level.entities
    _entities.each{|entity| entity.bindGame(this) }
    _rooms = level.data
    _player = _entities.where {|entity| entity.type == "player" }.toList[0]
    _turn = 0
    _data = {}
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

    // Some actions may consume energy on failure?
    if (_result.progress) {
      actor.finishTurn(action)
      recalculate()
      checkConditions()
      nextTurn()
    }

    return _result
  }

  checkConditions() {
    if (_player.power <= 0) {
      addEventToResult(LogEvent.new("Out of power"))
      addEventToResult(GameOverEvent.new())
    }
  }

  recalculate() {
    var facing = Dir[_player.state["facing"]]
    var min = _player.pos
    var length = 7
    var cone = facing * length
    var max = _player.pos + cone

    recalculateRooms()

    var base = _player.pos - facing
    for (line in 0..cone.manhattan) {
      for (scan in -line..line) {
        var current = base + facing.perp * scan
        var points = LineVisitor.walk(_player.pos, current)
        for (index in 0...points.count) {
          var tile = getTileAt(points[index])
          tile["seen"] = true
          if (tile["light"] == null || tile["light"] < 2) {
            tile["light"] = 2
            if (!tile["obscure"]) {
              for (j in -1..1) {
                for (i in -1..1) {
                  var point = points[index] + Vec.new(i, j)
                  var nextTile = getTileAt(point)
                  if (nextTile["obscure"]) {
                    nextTile["light"] = 2
                    nextTile["seen"] = true
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

  getRoomsAtPos(pos) {
    return _rooms.where {|room| room.isInRoom(pos) }.toList
  }

  getEntityRooms(entity) {
    return getRoomsAtPos(entity.pos)
  }

  recalculateRooms() {
    var lighting = []
    state["currentRooms"] = []
    _rooms.each {|room|
      var player = _player
      if (room.isInRoom(player.pos)) {
        state["currentRooms"].add(room)
      }
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
      room.setTileProperties([ ["light", 2], [ "seen", true ] ])
    }
  }

  getTileAt(vec) { getTileAt(vec.x, vec.y) }
  getTileAt(x, y) {
    return _map.get(x, y)
  }

  setTileAt(pos, tile) { setTileAt(pos.x, pos.y, tile) }
  setTileAt(x, y, tile) {
    _map.set(x, y, tile.copy)
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

