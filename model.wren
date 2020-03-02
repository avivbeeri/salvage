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

  }
  construct level(map, entities) {
    _map = map
    _entities = entities
    _entities.each{|entity| entity.bindGame(this) }
    _player = _entities.where {|entity| entity.type == "player" }.toList[0]
    _turn = 0
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

  recalculateA() {
    var distance = 8
    for (y in 0...distance) {
      for (x in 0...y) {
        var pos = Vec.new(x, -y) + player.pos

      }
    }
  }

  recalculate() {
    var min = _player.pos - Vec.new(8, 8)
    var max = _player.pos + Vec.new(8, 8)
    for (y in min.y..max.y) {
      for (x in min.x..max.x) {
        var point = Vec.new(x, y)
        getTileAt(point)["light"] = 0
      }
    }
    for (y in min.y..max.y) {
      for (x in min.x..max.x) {
        var points = LineVisitor.walk(_player.pos, Vec.new(x, y))
        var visible = true
        var last = null
        for (index in 1...points.count) {
          var tile = getTileAt(points[index])
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

          if (tile["obscure"]) {
            break
          }
        }
      }
    }
    for (entity in _entities) {
      if (entity != _player) {
        var points = LineVisitor.walk(_player.pos, entity.pos)
        var visible = true
        for (point in points) {
          var tile = getTileAt(point)
          if (tile["obscure"]) {
            visible = false
            break
          }
        }
        entity.visible = visible
      }
    }


  }

  recalculateRooms() {
    var lighting = []
    _rooms.each {|room|
      var player = _player
      if (room.isInRoom(player.pos)) {
        lighting.add(room)
      } else {
        room.setTileProperty("light", 0)
      }
    }
    entities.each {|entity|
      entity.visible = lighting.count > 0 && lighting.any {|room| room.isInRoom(entity.pos) }
    }
    lighting.each {|room| room.setTileProperty("light", 2) }
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

