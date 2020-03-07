import "math" for M, Vec
import "./events" for LogEvent, GameOverEvent
import "./action" for Action, MoveAction, DanceAction, ChargeMoveAction, RestAction
import "./test" for R

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
    _state = {}
    _energy = 0
    _speed = NORMAL_SPEED
    _visible = false
    _solid = true
    _attack = 1
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

  attack { _attack }
  attack=(v) { _attack = v }
  visible { _visible }
  visible=(v) { _visible = v }
  solid { _solid }
  solid=(v) { _solid = v }

  x { _pos.x }
  y { _pos.y }
  x=(v) { _pos.x = v }
  y=(v) { _pos.y = v }
  pos { _pos }
  pos=(v) { _pos = v }
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
      _power = (FULL_POWER * 1.00).floor // FULL_POWER
    state = {
      "facing": Vec.new(0, 1)
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
    attack = 50
    visible = true
    state["hp"] = 1
  }

  onDestroy() {
    game.addEventToResult(LogEvent.new("Blob was killed"))
  }

  getAction() {
    // var dir = (pos - game.player.pos).unit
    var dir = R.sample([
      Vec.new(0, 1),
      Vec.new(-1, 0),
      Vec.new(1, 0),
      Vec.new(0, -1),
    ])
    var action = MoveAction.new(dir)
    action.bind(this)
    if (action.verify(dir, true)) {
      return MoveAction.new(dir)
    }
    return RestAction.new()
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
  finishTurn(action) {
    if (state == "hit") {
      gain()
    } else {
      super.finishTurn(action)
    }
  }

  getAction() {
    if (state == "charging") {
      return Action.none()
    } else if (state == "hit") {
      game.destroyEntity(this)
      if (game.player.state["charge"] == this) {
        game.player.state["charge"] = null
      }
    } else {
      var dir = _direction + pos
      return ChargeMoveAction.new(_direction)
    }
  }
}
