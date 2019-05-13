import "./dir" for Dir
import "./action" for MoveAction
import "./events" for BoltEvent, EnergyDepletedEvent
import "./actor" for Enemy, Player

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
  energy { _energy }
  turn { _turn }

  construct level(map, entities) {
    _map = map
    _entities = entities
    _entities.each{|entity| entity.bindGame(this) }
    _player = _entities.where {|entity| entity.type == "player" }.toList[0]
    _energy = 10
    _turn = 0
  }

  process() {
    var actor = _entities[_turn]
    var action = actor.getAction()
    if (action == null) {
      return GameResult.new()
    }
    while (true) {
      System.print("Taking turn: %(actor.type)")
      action.bind(actor)
      _result = GameResult.new()
      _result.progress = action.perform()

      if (_result.progress) {
        consumeEnergy(action.energy)
        _turn = (_turn + 1) % _entities.count
      }

      if (action.alternate == null) {
        break
      }
      action = action.alternate
    }
    return _result
  }

  consumeEnergy(n) {
    _energy = _energy - n
      if (_energy <= 0) {
        addEventToResult(EnergyDepletedEvent.new())
      }
  }

  isTileSolid(x, y) {
    var tile = _map[y * 7 + x]
    return tile == 1
  }

  isTileValid(x, y) {
    return (x >= 0 && x < 7 && y >= 0 && y < 7)
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
}

