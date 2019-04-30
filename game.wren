
class Event {}
class StateChangeEvent is Event {
  construct new() { _type = "global" }
  construct new(type) {
    _type = type
  }
  type { _type }
}

var Dir = {
  "left": { "x": -1, "y": 0 },
  "right": { "x": 1, "y": 0 },
  "up": { "x": 0, "y": -1 },
  "down": { "x": 0, "y": 1 }
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
    _listeners = []
    _turn = 0
  }

  registerListener(listener) {
    _listeners.add(listener)
  }

  emit(event) {
    _listeners.each {|listener|
      listener.receive(event)
    }
  }

  process() {
    var actor = _entities[_turn]
    var action = actor.action
    if (action == null) {
      return false
    }
    System.print("Taking turn: %(actor.type)")
    action.bind(actor)
    if (action.perform()) {
      consumeEnergy(action.energy)
      _turn = (_turn + 1) % _entities.count
      return true
    }
    return false
  }

  consumeEnergy(n) {
    _energy = _energy - n
  }

  isTileSolid(x, y) {
    var tile = _map[y * 7 + x]
    return tile == 1
  }

  isTileValid(x, y) {
    return (x >= 0 && x < 7 && y >= 0 && y < 7)
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
      System.print("Dir: %(dirX), %(dirY)")
      System.print("0: %(x0), %(y0)")
      while (!done) {
        x = x + dirX
        y = y + dirY
        System.print("%(x), %(y)")
        done = !isTileValid(x, y) || isTileSolid(x, y)
        if (!done) {
          done = x == x1 && y == y1
          System.print("%(done)")

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
}
