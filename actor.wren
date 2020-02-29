import "./dir" for Dir
import "./action" for Action, MoveAction, DanceAction
import "math" for M, Vec

var SLOWEST_SPEED = 0
var SLOW_SPEED = 1
var NORMAL_SPEED = 3
var FAST_SPEED = 5

var GAINS = [
  2, // third speed
  3, // half speed
  4, // 2/3rd speed
  6, // Normal speed
  9,
  12, // double speed
]

var THRESHOLD = 12

class Actor {
  construct new(type, x, y) {
    _pos = Vec.new(x, y)
    _type = type
    _state = "ready"
    _energy = 0
    _speed = NORMAL_SPEED
    _visible = false
    _solid = false
  }

  needsInput { false }
  // Energy Mechanics
  speed { _speed }
  speed=(v) { _speed = v }
  energy { _energy }
  gain() {
    if (type != "player") {
      System.print("%(this.type) gains %(GAINS[this.speed])")
    }
    _energy = _energy + GAINS[this.speed]
    return canTakeTurn
  }
  consume() { _energy = _energy % THRESHOLD }
  canTakeTurn { _energy >= THRESHOLD }
  // END energy mechanics

  visible { _visible }
  visible=(v) { _visible = v }
  solid { _solid }
  solid=(v) { _solid = v }

  x { _pos.x }
  y { _pos.y }
  x=(v) { _pos.x = v }
  y=(v) { _pos.y = v }
  pos { _pos }
  type { _type }
  getAction() { Action.new(null) }

  state { _state }
  state=(s) { _state = s }

  bindGame(game) { _game = game }
  game { _game }
}

class Player is Actor {
  construct new(x, y) {
    super("player", x, y)
    visible = true
    _action = null
    state = {
      "facing": Dir["up"]
    }
  }

  needsInput { _action == null }

  getAction() {
    var action = _action
    _action = null
    return action
  }
  action=(v) { _action = v }
}

class Blob is Actor {
  construct new(x, y) {
    super("blob", x, y)
    speed = SLOWEST_SPEED
    visible = true
  }
  getAction() {
    if (x > 0) {
      if (game.doesTileContainEntity(x - 1, y)) {
        return MoveAction.new(null)
      }
      return MoveAction.new("left")
    } else {
      return DanceAction.new()
    }
  }
}

class ChargeBall is Actor {
  construct new(actor, x, y, direction) {
    super("chargeball", x, y)
    speed = FAST_SPEED
    visible = true
    _owner = actor
    state = "charging"
    _direction = direction
  }

  getAction() {
    if (state == "charging") {
      return Action.none()
    } else {
      var dir = Dir[_direction] + pos
      System.print(dir)
      if (game.isTileValid(dir.x, dir.y)) {
        return MoveAction.new(_direction)
      } else {
        System.print("destroy")
        game.destroyEntity(this)
        _owner.state["charge"] = null
        return Action.none()
      }
    }
  }
}
