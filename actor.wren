import "./dir" for Dir
import "./action" for
  Action,
  ChargeWeaponAction,
  FireWeaponAction

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
  construct new(type, x, y, dir) {
    super(type, x, y)
    _facing = Dir[dir]
    _dir = dir
  }
  dir { _dir }
  getAction() {
    if (state != "charging") {
      if (game.canSeeDir(_facing, x, y, game.player.x, game.player.y)) {
        return ChargeWeaponAction.new()
      } else {
        return Action.new(null)
      }
    } else if (state == "charging") {
      return FireWeaponAction.new(_dir)

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

