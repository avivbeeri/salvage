import "./dir" for Dir
import "./action" for Action, MoveAction, DanceAction
import "math" for M

var SLOW_SPEED = 0
var NORMAL_SPEED = 1
var FAST_SPEED = 2

var GAINS = [
  3, // half speed
  6, // Normal speed
  12, // double speed
]

var THRESHOLD = 12

class Actor {
  construct new(type, x, y) {
    _x = x
    _y = y
    _type = type
    _state = "ready"
    _energy = 0
    _speed = NORMAL_SPEED
  }

  // Energy Mechanics
  speed { _speed }
  speed=(v) { _speed = v }
  energy { _energy }
  gain() { _energy = M.min(THRESHOLD, (_energy + GAINS[this.speed])) }
  consume() { _energy = _energy % THRESHOLD }
  canTakeTurn { _energy >= THRESHOLD }
  // END energy mechanics


  x { _x }
  y { _y }
  x=(v) { _x = v }
  y=(v) { _y = v }
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
    _action = null
  }

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
    _action = null
    speed = SLOW_SPEED
  }
  getAction() {
    if (x > 0) {
      return MoveAction.new("left")
    } else {
      return DanceAction.new()
    }
  }
}

