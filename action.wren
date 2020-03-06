import "math" for M, Vec
import "./dir" for Dir
import "./events" for
  MoveEvent,
  LogEvent,
  GameOverEvent,
  SelfDestructEvent,
  MenuEvent

class Action {
  type { _type }
  actor { _actor }
  game { _game }
  energy { 0 }

  construct none() { _type = "none" }
  construct new(type) {
    _type = type
  }

  bind(actor) {
    _game = actor.game
    _actor = actor
  }

  perform(result) { true }
  addEvent(event) { _game.addEventToResult(event) }
}

class DanceAction is Action {
  construct new() {
    super("dance")
  }
  perform(result) {
    System.print("%(actor.type) dances flagrantly!")
    return true
  }
}
class RestAction is Action {
  construct new() {
    super("rest")
  }
  perform(result) {
    System.print("%(actor.type) rests.")
    import "./actor" for Player
    if (actor is Player) {
      if (actor.state["charge"]) {
        result.alternate = FireWeaponAction.new()
      }
    }
    return true
  }
}

class TeleportAction is Action {
  construct new() {
    super("teleport")
  }
  perform(result) {
    System.print("You win!")
    game.addEventToResult(LogEvent.new("You win!"))
    return true
  }
}

class ChargeWeaponAction is Action {
  construct new() {
    super("charge")
  }
  perform(result) {
    // We assume this action is taken by a player
    if (!actor.state["charge"]) {
      import "./actor" for ChargeBall
      var facing = actor.state["facing"]
      var pos = actor.pos + actor.state["facing"]
      var isOccupied = game.getEntitiesOnTile(pos.x, pos.y).where {|entity| entity.solid }.count > 0
      var tile = game.getTileAt(pos)
      if (isOccupied || tile["solid"] || tile["obscure"]) {
        return false
      }
      var ball = ChargeBall.new(actor, pos.x, pos.y, facing)
      ball.bindGame(actor.game)
      actor.state["charge"] = ball
      // ball.state = "firing"
      // Add right after player
      game.entities.insert(1, ball)
    } else {
      result.alternate = Action.none()
    }
    return true
  }
}


class MoveAction is Action {
  construct new(direction) {
    super("move")
    _dir = direction
  }

  direction { _dir }
  energy { _energy || 0 }

  verify (dir) { verify(dir, false) }
  verify(dir, ignoreEntities) {
    var dest = actor.pos + direction
    var tile = game.map.get(dest)
    var isSolid = tile["solid"]
    var isObscure = tile["obscure"]
    var isOccupied = game.getEntitiesOnTile(dest.x, dest.y).where {|entity| entity.solid }.count > 0
    return !isSolid && !isObscure && (ignoreEntities || !isOccupied)
  }

  perform(result) {
    if (_dir == null) {
      result.alternate = Action.none()
      return true
    }

    var dest = actor.pos + direction
    var validMove = false

    var tile = game.map.get(dest)
    var isSolid = tile["solid"]
    var isOccupied = game.getEntitiesOnTile(dest.x, dest.y).where {|entity| entity.solid }.count > 0
    if (isOccupied) {
      result.alternate = AttackAction.new(direction, 1)
      return true
    }

    var isInteractable = tile["menu"] != null
    if (isInteractable) {
      result.alternate = InteractWithMenuAction.new(dest)
      return true
    }

    if (!isSolid && !isOccupied) {
      actor.pos = dest
      /*
      actor.x = destX
      actor.y = destY
      */
      validMove = true
    }
    return validMove
  }
}

class PlayerMoveAction is MoveAction {
  construct new(direction) {
    super(direction)
  }
  perform(result) {
    var validMove = super.perform(result)
    if (validMove) {
      var tile = game.getTileAt(actor.pos)
      if (tile["teleport"]) {
        result.alternate = TeleportAction.new()
      }
      if (actor.state["charge"]) {

        var charge = actor.state["charge"]
        var chargeMove = ChargeMoveAction.new(direction)
        chargeMove.bind(charge)
        var chargeOkay = chargeMove.perform(result)
        if (!chargeOkay) {
          actor.state["charge"] = null
        }
        /*
        charge.x = charge.x + Dir[direction].x
        charge.y = charge.y + Dir[direction].y
        */
      } else {
        actor.state["facing"] = direction
      }
      addEvent(MoveEvent.new(actor, direction))
    }
    if (result.alternate is AttackAction) {
      result.alternate = null
    }
    return validMove
  }
}

class ChargeMoveAction is MoveAction {
  construct new(direction) {
    super(direction)
  }
  perform(result) {
    // var validMove = super.perform(result)
    var validMove = super.verify(direction)
    var target = actor.pos + direction
    if (!validMove) {
      var attack = AttackAction.new(direction, 1)
      attack.bind(actor)
      var valid = attack.perform(result)
      if (valid) {
        actor.pos.x = target.x
        actor.pos.y = target.y
      }
      actor.state = "hit"
    } else {
      actor.pos.x = target.x
      actor.pos.y = target.y
      var direction = direction
      if (actor.state == "charging") {
        direction = Vec.new()
      }
      var attack = AttackAction.new(direction, 1)
      attack.bind(actor)
      var valid = attack.perform(result)
      if (valid) {
        actor.state = "hit"
      }
      System.print("6")
    }
    return true
  }
}

class AttackAction is Action {
  construct new(dir, power) {
    _dir = dir
    _power = power
  }
  perform(result) {
    var valid = false
    var target = actor.pos + _dir
    var targets = game.getEntitiesOnTile(target.x, target.y).each {|entity|
      import "./actor" for Player
      if (entity is Player) {
        valid = true
        entity.power = entity.power - _power
        game.addEventToResult(LogEvent.new("%(actor.type) hit %(entity.type)"))
      } else if (entity.state is Map && entity.state["hp"] != null) {
        game.addEventToResult(LogEvent.new("%(actor.type) hit %(entity.type)"))
        valid = true
        entity.state["hp"] = entity.state["hp"] - _power
        if (entity.state["hp"] <= 0) {
          game.destroyEntity(entity)
          System.print("kill")
        }
      }
    }
    var tile = game.getTileAt(target)
    if (tile["obscure"] && tile["hp"] != null) {
      tile["hp"] = tile["hp"] - _power
      if (tile["hp"] <= 0) {
        import "./tiles" for Tiles
        var newTile = Tiles.floor.copy
        var rooms = game.getRoomsAtPos(target)
        rooms.each {|room| room.addTile(target.x, target.y, newTile)}
      }
      valid = true
    }

    return valid
  }
}

class FireWeaponAction is Action {
  construct new() {
    super("fire")
  }

  perform(result) {
    if (actor.state["charge"]) {
      actor.state["charge"].state = "firing"
      actor.state["charge"] = null
      return true
    } else {
      return false
    }
  }
}

class InteractWithMenuAction is Action {
  construct new(pos) {
    super("interact-menu")
    _pos = pos
  }

  perform(result) {
    var tile = game.getTileAt(_pos)
    if (tile["menu"] != null) {
      game.addEventToResult(MenuEvent.new(tile["menu"]))
      return false
    }

    return false
  }

}

class SelfDestructAction is Action {
  construct new() {
    super("self-destruct")
  }
  perform(result) {
    game["self-destruct"] = 100
    game.addEventToResult(LogEvent.new("Self-destruct set", "high"))
    game.addEventToResult(SelfDestructEvent.new())
  }
}
