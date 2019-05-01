class Actor {
  construct new(type, x, y) {
    _x = x
    _y = y
    _type = type
    _state = "ready"
  }
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

class Enemy is Actor {
  construct new(type, x, y) {
    super(type, x, y)
  }
  getAction() {
    if (state != "charging") {
      if (game.canSeeOrth(x, y, game.player.x, game.player.y)) {
        return ChargeWeaponAction.new()
      } else {
        return Action.new(null)
      }
    } else if (state == "charging") {
      return FireWeaponAction.new("down")

    } else {
      return Action.new(null)
    }
  }
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

import "./action" for
  Action,
  ChargeWeaponAction,
  FireWeaponAction

