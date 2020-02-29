import "dome" for Window
import "graphics" for Canvas, Color, ImageData
import "input" for Keyboard
import "math" for M, Vec
import "./action" for PlayerMoveAction,
  DanceAction,
  RestAction,
  ChargeWeaponAction,
  FireWeaponAction
import "./events" for GameOverEvent, MoveEvent
import "./model" for GameModel
import "./keys" for Key

var Inputs = [
  "left",
  "right",
  "up",
  "down"
].map {|key| Key.new(key, PlayerMoveAction.new(key), true) }.toList
Inputs.add(Key.new("space", RestAction.new(), true))
Inputs.add(Key.new("d", DanceAction.new(), true))
Inputs.add(Key.new("c", ChargeWeaponAction.new(), false))
Inputs.add(Key.new("f", FireWeaponAction.new(), false))




var Angles = {
  "left": 90,
  "right": -90,
  "up": 180,
  "down": 0
}

class Animation {
  done=(v) { _done = v }
  done { _done || false }
  t { _t || 0 }
  update(view) { _t = t + 1 }
  draw() {}
}
class CameraAnimation is Animation {
  construct begin() {
  }
  update(view) {
    var player = view.model.player
    var camera = view.camera
    camera.x = camera.x - M.sign(camera.x - player.x) * 1/8
    camera.y = camera.y - M.sign(camera.y - player.y) * 1/8

    if (camera.x - player.x == 0 && camera.y - player.y == 0) {
      done = true
    }
  }
}



class GameView {
  construct init(gameModel) {
    Window.title = "Salvage"
    var scale = 3
    Canvas.resize(128, 128)
    Window.resize(scale * Canvas.width, scale * Canvas.height)

    _model = gameModel
    _events = []
    _animations = []
    _ready = true
    updateState()

    _camera = Vec.new(_model.player.x, _model.player.y)
  }
  camera { _camera }
  model { _model }

  update() {
    Inputs.each { |input| input.update() }
    if (_ready) {
      for (input in Inputs) {
        if (input.firing) {
          _model.player.action = input.action
          break
        }
      }
      var result = _model.process()
      _ready = _ready && !result.progress && result.events.count == 0
      _animations = processEvents(result.events)
    } else {
      _animations.each {|animation| animation.update(this) }

      _ready = _animations.count == 0
      if (_ready) {
        updateState()
        if (_gameOver) {
        }
      }
    }

  }

  draw() {
    Canvas.cls()
    var map = _currentMap
    if (_gameOver) {
      // TODO UI Stacking system
      Canvas.print("Game Over", 0, map.height * 8, Color.white)
    } else {
      // Canvas.print("Player: %(_model.entities[0].energy)", 0,8, Color.white)
      // Canvas.print("Blob: %(_model.entities[1].energy)", 0, 0, Color.white)
    }
    var player = _model.player


    var displayW = 128
    var displayH = 128
    var offX = (displayW / 2) - (camera.x * 8) - 4
    var offY = (displayH / 2) - (camera.y * 8) - 4

    var border = 8
    var minX = M.max(player.x - border, 0)
    var maxX = M.min(player.x + border, map.width)
    var minY = M.max(player.y - border, 0)
    var maxY = M.min(player.y + border, map.width)


    for (y in minY...maxY) {
      for (x in minX...maxX) {
        var tile = map.get(x, y)
        if (!tile["dark"]) {
          if (tile.type == 0) {
            Canvas.print(".", offX + x * 8, offY + y * 8, Color.darkgray)
          } else if (tile.type == 1) {
            Canvas.print("#", offX + x * 8, offY + y * 8, Color.darkgray)
            // Canvas.rectfill(offX + x * 8, offY + y * 8, 7, 8, Color.darkgray)
          } else if (tile.type == 2) {
            Canvas.print("*", offX + x * 8, offY + y * 8, Color.blue)
          } else if (tile.type == 3) {
            Canvas.rectfill(offX + x * 8, offY + y * 8, 7, 8, Color.darkgray)
            Canvas.print("-", offX + x * 8, offY + y * 8, Color.lightgray)
          }
        }
      }
    }

    _model.entities.each {|entity|
      if (!entity.visible) {
        return
      }
      if (entity.type == "player") {
        Canvas.rectfill(offX + 8 * camera.x, offY + 8*camera.y, 8, 8, Color.black)
        Canvas.print("@", offX + 8 * camera.x, offY + 8 * camera.y, Color.white)
      } else if (entity.type == "blob") {
        Canvas.print("s", offX + 8 * entity.x, offY + 8 * entity.y, Color.green)
      } else if (entity.type == "chargeball") {
        if (entity.state == "charging") {
          var diff = entity.pos - player.pos
          Canvas.print("o", offX + 8 * (camera.x + diff.x), offY + 8 * (camera.y +  diff.y), Color.blue)
        } else {
          Canvas.print("o", offX + 8 * (entity.x), offY + 8 * (entity.y), Color.blue)
        }
      }
    }

    // Render one animation at a time
    if (_animations.count > 0) {
      var a = _animations[0]
      a.draw()
      if (a.done) {
        _animations.removeAt(0)
      }
    }
  }

  // Following the Redux model, you can up
  updateState() {
    _currentMap = _model.map
    _currentEnergy = _model.energy
    _gameOver = _gameOverImminent || false
  }

  // Respond to events generated by the Game Model since the last action was taken
  // You can trigger animations here and pass them back to the view
  processEvents(events) {
    return events.map {|event|
      if (event is GameOverEvent) {
        _gameOverImminent = true
        return null
      } else if (event is MoveEvent) {
        if (event.source == _model.player) {
          return CameraAnimation.begin()
        }
      }
      return null
    }.where {|animation| animation != null }.toList
  }
}

