import "./dir" for Dir
import "./action" for MoveAction, BoltEvent, EnergyDepletedEvent
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
    System.print("Taking turn: %(actor.type)")
    action.bind(actor)
    _result = GameResult.new()
    _result.progress = action.perform()

    if (_result.progress) {
      consumeEnergy(action.energy)
      _turn = (_turn + 1) % _entities.count
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

  canSeeOrth(x0, y0, x1, y1) {
    if (x0 == x1 || y0 == y1) {
      var dirX = (x1 - x0) == 0 ? 0 : (x1 - x0) / (x1 - x0).abs
      var dirY = (y1 - y0) == 0 ? 0 : (y1 - y0) / (y1 - y0).abs
      if (dirX == 0 && dirY == 0) {
        return true
      }
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
    } else {
      return false
    }
  }


  addEventToResult(event) {
    if (_result != null) {
      _result.events.add(event)
    } else {
      Fiber.abort("Tried to add an event without a result")
    }
  }
}

