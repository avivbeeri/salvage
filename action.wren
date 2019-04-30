class Action {
  type { _type }
  actor { _actor }
  model { _model }
  energy { 0 }

  construct new(type) {
    _type = type
  }

  bind(actor) {
    _model = actor.game
    _actor = actor
  }

  perform() { true }
}

var Dir = {
  "left": { "x": -1, "y": 0 },
  "right": { "x": 1, "y": 0 },
  "up": { "x": 0, "y": -1 },
  "down": { "x": 0, "y": 1 }
}

class FireWeaponAction is Action {
  construct new(direction) {
    super("fire")
    _direction = direction
  }
  perform() {
    System.print("FireWeaponAction: %(actor.type)")

    var hit = false
    var vec = Dir[_direction]
    var x = actor.x
    var y = actor.y
    var solid = false
    var valid = true
    while (valid && !solid && !hit) {
      x = x + vec["x"]
      y = y + vec["y"]
      valid = model.isTileValid(x, y)
      solid = valid && model.isTileSolid(x, y)
      if (valid && !solid) {
        var target = model.entities.where {|entity|
          return entity != actor &&
            entity.x == x &&
            entity.y == y
        }
        hit = target.count > 0
      }
    }
    if (hit) {
      // handle hit
      model.consumeEnergy(1)
    }
    System.print("Hit: %(hit)")
    // push an animation event to the ui
    // }

    actor.state = null
    return true
  }

}

class ChargeWeaponAction is Action {
  construct new() {
    super("change")
  }
  perform() {
    System.print("ChargeWeaponAction: %(actor.type)")
    actor.state = "charging"
    return true
  }

}

class MoveAction is Action {
  construct new(direction) {
    super("move")
    _dir = direction
  }

  energy { _energy }

  perform() {
    System.print("MoveAction: %(_actor)")
    var destX = actor.x + Dir[_dir]["x"]
    var destY = actor.y + Dir[_dir]["y"]
    var validMove = false

    if ((destX >= 0 && destX < 7) && (destY >= 0 && destY < 7)) {
      var tile = model.map[destY * 7 + destX]
      var isSolid = (tile == 1)
      if (!isSolid) {
        actor.x = destX
        actor.y = destY
        validMove = true
      }
    }
    _energy = 1
    return validMove
  }

}
