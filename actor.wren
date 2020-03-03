import "./dir" for Dir
import "./events" for LogEvent
import "./action" for Action, MoveAction, DanceAction, ChargeMoveAction
import "math" for M, Vec

var FULL_POWER = 1560

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
      _solid = true
  }

  onDestroy() {}

  needsInput { false }
  // Energy Mechanics
  speed { _speed }
  speed=(v) { _speed = v }
  energy { _energy }
  gain() {
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
  finishTurn(action) {
    consume()
  }

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
      _power = FULL_POWER
    state = {
      "facing": "up"
    }
  }

  power { _power }
  power=(v) { _power = v }
  needsInput { _action == null }

  action=(v) { _action = v }
  getAction() {
    var action = _action
    _action = null
    return action
  }

  finishTurn(action) {
    if (action is MoveAction) {
      var tile = game.getTileAt(pos)
      tile["cost"]
      power = M.max(0, power - (tile["cost"] || 1))
    } else {
      power = M.max(0, power - 1)
    }
    if (state["charge"]) {
      power = M.max(0, power - 1)
    }
    if (game.getEntityRooms(this).all {|room| !room.light}) {
      power = M.max(0, power - 1)
    }
    super.finishTurn(action)
  }
}

class Blob is Actor {
  construct new(x, y) {
    super("blob", x, y)
    speed = SLOWEST_SPEED
    visible = true
  }

  onDestroy() {
    game.addEventToResult(LogEvent.new("Blob was killed"))
  }

  getAction() {
    if (x > 0) {
      if (game.doesTileContainEntity(x - 1, y)) {
        return MoveAction.new(null)
      }
      return MoveAction.new(null)
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
    solid = false
    _direction = direction
  }

  owner { _owner }

  getAction() {
    if (state == "charging") {
      return Action.none()
    } else if (state == "hit") {
      game.destroyEntity(this)
      return Action.none()
    } else {
      var dir = Dir[_direction] + pos
      System.print(dir)
      return ChargeMoveAction.new(_direction)
    }
  }
}
