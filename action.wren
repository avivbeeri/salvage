import "./dir" for Dir

class Event {}

class EnergyDepletedEvent is Event {
  construct new() {}
}

class BoltEvent is Event {
  source { _source }
  target { _target }
  construct new(source, tx, ty) {
    _source = source
    _target = [tx, ty]
  }
}


class Action {
  type { _type }
  actor { _actor }
  game { _game }
  energy { 0 }

  construct new(type) {
    _type = type
  }

  bind(actor) {
    _game = actor.game
    _actor = actor
  }

  perform() { true }
  addEvent(event) { _game.addEventToResult(event) }
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
    var targets
    while (valid && !solid && !hit) {
      x = x + vec["x"]
      y = y + vec["y"]
      valid = game.isTileValid(x, y)
      solid = valid && game.isTileSolid(x, y)
      if (valid && !solid) {
        targets = game.entities.where {|entity|
          return entity != actor &&
            entity.x == x &&
            entity.y == y
        }.toList
        hit = targets.count > 0
      }
    }
    if (hit) {
      // handle hit
      game.consumeEnergy(1)
      var target = targets[0]
      game.addEventToResult(BoltEvent.new(actor, target.x, target.y))
    } else {
      game.addEventToResult(BoltEvent.new(actor, x, y))

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
      var tile = game.map[destY * 7 + destX]
      var isSolid = (tile == 1)
      var isOccupied = game.doesTileContainEntity(destX, destY)
      if (!isSolid && !isOccupied) {
        actor.x = destX
        actor.y = destY
        validMove = true
      }
    }
    _energy = 1
    return validMove
  }

}

