import "./dir" for Dir
import "./action" for MoveAction
import "./events" for BoltEvent, EnergyDepletedEvent
import "./actor" for Player

class GameResult {
  progress=(v) { _progress = v}
  progress { _progress }
  events { _events }

  construct new() {
    _progress = false
    _events = []
  }
}


class GameModel {
  map { _map }
  player { _player }
  entities { _entities }
  energy { _entities[_turn].energy }
  turn { _turn }
  isPlayerTurn() { _entities[_turn] == _player }

  construct level(map, entities) {
    _map = map
    _entities = entities
    _entities.each{|entity| entity.bindGame(this) }
    _player = _entities.where {|entity| entity.type == "player" }.toList[0]
    _turn = 0
  }

  nextTurn() {
    _turn = (_turn + 1) % _entities.count
    System.print("----")
  }

  process() {
    var actor = _entities[_turn]
    if (!actor.canTakeTurn) {
      actor.gain()
      nextTurn()
      return GameResult.new()
    }

    var action = actor.getAction()
    if (action == null) {
      return GameResult.new()
    }
    while (true) {
      action.bind(actor)
      _result = GameResult.new()
      _result.progress = action.perform()

      if (_result.progress) {
        actor.consume()
        nextTurn()
      }

      if (action.alternate == null) {
        break
      }
      action = action.alternate
    }
    return _result
  }

  isTileSolid(x, y) {
    return _map.get(x, y)["solid"]
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

  canSeeDir(dir, x0, y0, x1, y1) {
    var dirX = dir["x"]
    var dirY = dir["y"]

    var done = false
    var success = false
    var x = x0
    var y = y0
    while (!done) {
      x = x + dirX
      y = y + dirY
      done = !isTileValid(x, y) || isTileSolid(x, y)
      if (!done) {
        done = x == x1 && y == y1

        success = done
      } else {
        success = false
      }
    }
    return success
  }

  canSeeOrth(x0, y0, x1, y1) {
    return canSeeDir(Dir["left"], x0, y0, x1, y1) ||
    canSeeDir(Dir["down"], x0, y0, x1, y1) ||
    canSeeDir(Dir["up"], x0, y0, x1, y1) ||
    canSeeDir(Dir["right"], x0, y0, x1, y1)
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
  }
}

