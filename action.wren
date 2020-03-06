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
      var pos = actor.pos + Dir[actor.state["facing"]]
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

  perform(result) {
    if (_dir == null) {
      result.alternate = Action.none()
      return true
    }

    var destX = actor.x + Dir[_dir].x
    var destY = actor.y + Dir[_dir].y
    var validMove = false

    var tile = game.map.get(destX, destY)
    var isSolid = tile["solid"]
    var isOccupied = game.getEntitiesOnTile(destX, destY).where {|entity| entity.solid }.count > 0

    var isInteractable = tile["menu"] != null
    if (isInteractable) {
      result.alternate = InteractWithMenuAction.new(Vec.new(destX, destY))
      return true
    }

    if (!isSolid && !isOccupied) {
      actor.x = destX
      actor.y = destY
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
    return validMove
  }
}

class ChargeMoveAction is MoveAction {
  construct new(direction) {
    super(direction)
  }
  perform(result) {
    var validMove = super.perform(result)
    var target = actor.pos + Dir[direction]
    if (!validMove) {
      if (actor.state == "charging") {
        game.destroyEntity(actor)
      } else {
        game.getEntitiesOnTile(target.x, target.y).each {|entity| game.destroyEntity(entity) }
        actor.pos.x = target.x
        actor.pos.y = target.y
        actor.state = "hit"
      }
    } else {
      import "./tiles" for Tiles
      var tile = game.getTileAt(actor.pos)
      if (tile["obscure"]) {
        game.destroyEntity(actor)
        target = actor.pos
        var tile = game.getTileAt(target)
        if (tile.type == Tiles.door.type) {
          tile["hp"] = tile["hp"] - 1
          if (tile["hp"] <= 0) {
            var newTile = Tiles.floor.copy
            var rooms = game.getRoomsAtPos(target)
            rooms.each {|room| room.addTile(target.x, target.y, newTile)}
          }
        }
      }
    }
    return validMove
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
    game["self-destruct"] = 5
    game.addEventToResult(LogEvent.new("Self-destruct set", "high"))
    game.addEventToResult(SelfDestructEvent.new())
  }
}
