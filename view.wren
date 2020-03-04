import "dome" for Window
import "graphics" for Canvas, Color, ImageData
import "input" for Keyboard
import "math" for M, Vec
import "./generator" for StaticRoomGenerator
import "./action" for PlayerMoveAction,
  DanceAction,
  RestAction,
  ChargeWeaponAction,
  FireWeaponAction
import "./events" for GameOverEvent, MoveEvent, LogEvent
import "./model" for GameModel
import "./keys" for Key
import "./actor" for FULL_POWER

var MAROON = Color.hex("#800000")


var TILE_WIDTH = 8
var TILE_HEIGHT = 8

var Inputs = [
  "left",
  "right",
  "up",
  "down"
].map {|key| Key.new(key, PlayerMoveAction.new(key), true) }.toList
var SPACE_KEY = Key.new("space", RestAction.new(), true)
Inputs.add(SPACE_KEY)
Inputs.add(Key.new("d", DanceAction.new(), true))
Inputs.add(Key.new("c", ChargeWeaponAction.new(), false))
Inputs.add(Key.new("f", FireWeaponAction.new(), false))


class Animation {
  done=(v) { _done = v }
  done { _done || false }
  t { _t || 0 }
  update(view) { _t = t + 1 }
  draw() {}
}

class MessageAnimation is Animation {
  construct begin(text, color, timeout) {
    _height = 0
    _message = text
    _color = color
    _timeout = timeout
  }
  update(view) {
    super.update(view)
    _height = M.mid(0, t / 2, 10)
    if ((_timeout && t > (2 * 60)) || SPACE_KEY.firing) {
      done = true
    }
  }
  draw() {
    var centerH = M.round(Canvas.height / 2)
    var centerW = M.round(Canvas.width / 2)
    Canvas.rectfill(0, centerH - _height, Canvas.width, _height * 2, _color)
    Canvas.rectfill(0, centerH - _height + 1, Canvas.width, 2, Color.black)
    Canvas.rectfill(0, centerH + _height - 3, Canvas.width, 2, Color.black)
    // Canvas.line(0, centerH + _height - 1, Canvas.width,  centerH + _height - 1, Color.black)
    if (_height > 2) {
      Canvas.print(_message, centerW - _message.count * TILE_WIDTH / 2, centerH - 4, Color.black)
    }
  }
}

class GameBeginAnimation is MessageAnimation {
  construct begin() {
    super("MISSION BEGIN", Color.blue, true)
  }
  update(view) {
    super.update(view)
  }
}
class GameWinAnimation is MessageAnimation {
  construct begin() {
    super("MISSION SUCCESS", Color.darkgreen, false)
  }
  update(view) {
    super.update(view)
    if (done) {

      var level = StaticRoomGenerator.generate([])
      view.model = GameModel.level(level)
      return view
    }
  }
}
class GameLoseAnimation is MessageAnimation {
  construct begin() {
    super("MISSION FAILED", Color.red, false)
  }
  update(view) {
    super.update(view)
    if (done) {
      var level = StaticRoomGenerator.generate([])
      view.model = GameModel.level(level)
      return view
    }
  }
}

class WaitAnimation is Animation {
  construct begin() {
  }
  update(view) {
    super.update(view)
    if (t > 10) {
      done = true
    }
  }
}

class CameraAnimation is Animation {
  construct begin() {
  }
  update(view) {
    var player = view.model.player
    var camera = view.camera
    camera.x = (camera.x - M.sign(camera.x - player.x) * (1/ TILE_WIDTH))
    camera.y = (camera.y - M.sign(camera.y - player.y) * (1/ TILE_HEIGHT))

    if ((camera.x - player.x).abs < 0.1 && (camera.y - player.y).abs < 0.1) {
      done = true
      camera.x = M.round(camera.x)
      camera.y = M.round(camera.y)
    }
  }
}



class GameView {
  construct init(gameModel) {

    _model = gameModel
    _log = []
    _events = []
    _animations = [ WaitAnimation.begin(), GameBeginAnimation.begin() ]
    _ready = true
    updateState()

    _camera = Vec.new(_model.player.x, _model.player.y)
  }
  camera { _camera }
  model { _model }
  model=(v) { _model = v }

  update() {
    _ready = _animations.count == 0

    Inputs.each { |input| input.update() }
    if (_ready) {
      if (_gameOver) {
      }
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
      var result = _animations[0].update(this)
      if (_animations[0].done) {
        updateState()
        _animations.removeAt(0)
        return result
      }
    }
  }

  // Following the Redux model, you can up
  updateState() {
    _currentMap = _model.map
  }

  // Respond to events generated by the Game Model since the last action was taken
  // You can trigger animations here and pass them back to the view
  processEvents(events) {
    return events.map {|event|
      if (event is GameOverEvent) {
        _gameOver = true
        return GameLoseAnimation.begin()
      } else if (event is LogEvent) {
        _log.add(event.text)
        _log = _log.skip(M.max(0, _log.count - 3)).toList
      } else if (event is MoveEvent) {
        if (event.source == _model.player) {
          return CameraAnimation.begin()
        }
      }
      return null
    }.where {|animation| animation != null }.toList
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
    var top = (Canvas.height - displayH) / 2
    var left = 4
    var offX = left + (displayW / 2) - (camera.x * TILE_WIDTH) - 4
    var offY = top + (displayH / 2) - (camera.y * TILE_HEIGHT) - 4

    var border = 8
    var minX = M.max(player.x - border, 0)
    var maxX = M.min(player.x + border, map.width)
    var minY = M.max(player.y - border, 0)
    var maxY = M.min(player.y + border, map.height)


    for (y in minY...maxY) {
      for (x in minX...maxX) {
        var tile = map.get(x, y)
        if (tile["light"] != null && tile["light"] > 0) {
        // if (!tile["dark"] && (Vec.new(x, y) - camera).length < border) {
          if (tile.type == ".") {
            if (tile["light"] == 2) {
              Canvas.print(".", offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT, Color.darkgray)
            } else {
              Canvas.print(".", offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT, Color.darkblue)
            }
          } else if (tile.type == "#") {
            if (tile["light"] == 2) {
              Canvas.print("#", offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT, Color.darkgray)
            } else {
              Canvas.print("#", offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT, Color.darkblue)
            }
          } else if (tile.type == "*") {
            Canvas.print("*", offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT, Color.blue)
          } else if (tile.type == "~") {
            if (tile["light"] == 2) {
              Canvas.rectfill(offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT, 7, 8, Color.brown)
              Canvas.print("~", offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT + 3, Color.white)
            } else {
              Canvas.print("~", offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT + 3, Color.darkblue)
            }
          } else if (tile.type == "+") {
            // What kind of door is it?
            var color = Color.darkgreen
            if (tile["locked"]) {
              color = Color.hex("#800000")
            }
            if (tile["light"] < 2) {
              color = Color.darkblue
            }
            Canvas.rectfill(offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT, 7, 8, color)
            Canvas.print("+", offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT, Color.black)
          }
        }
      }
    }

    _model.entities.each {|entity|
      var diff = entity.pos - camera
      if (!entity.visible ||
        (entity.x >= maxX) || entity.x < minX ||
        (entity.y >= maxY) || entity.y < minY) {
        return
      }
      if (entity.type == "player") {
        Canvas.rectfill(offX + TILE_WIDTH * camera.x, offY + TILE_HEIGHT * camera.y, TILE_WIDTH, TILE_HEIGHT, Color.rgb(0, 0, 0, 128))
        if (entity.power > 0) {
          Canvas.print("@", offX + TILE_WIDTH * camera.x, offY + TILE_HEIGHT * camera.y, Color.white)
        } else {
          Canvas.print("\%", offX + TILE_WIDTH * camera.x, offY + TILE_HEIGHT * camera.y, Color.white)
        }
      } else if (entity.type == "blob") {
        Canvas.print("s", offX + TILE_WIDTH * entity.x, offY + TILE_HEIGHT * entity.y, Color.green)
      } else if (entity.type == "chargeball") {
        if (entity.state == "charging") {
          var diff = entity.pos - player.pos
          Canvas.print("o", offX + TILE_WIDTH * (camera.x + diff.x), offY + TILE_HEIGHT * (camera.y +  diff.y), Color.blue)
        } else {
          Canvas.print("o", offX + TILE_WIDTH * (entity.x), offY + TILE_HEIGHT * (entity.y), Color.blue)
        }
      }
    }
    Canvas.rectfill(left, top - 12, displayW, TILE_HEIGHT, Color.black)
    drawLog(0, 0)
    drawPowerBar(0, top + displayH)
    drawUI(displayW + 3, top)
  }
  drawLog(left, top) {
    Canvas.rectfill(129, top, 64, Canvas.height, Color.black)
    var lineY = 0
    for (line in _log) {
      Canvas.print(line, 0, lineY, Color.white)
      lineY = lineY + 8
    }

  }

  drawPowerBar(left, top) {
    var player = _model.player
    Canvas.print("[", 0, top, Color.white)
    var color = Color.blue
    if ((player.power / FULL_POWER) <= 0.1) {
      color = Color.orange
    }
    if ((player.power / FULL_POWER) <=0.05) {
      color = Color.red
    }
    for (pip in 0...(player.power / 55).ceil) {
      Canvas.print("|", 3 * (1 + pip), top, color)
    }
    var percentage = (100 * player.power / FULL_POWER).floor
    var percentX = 8 + 3 * 30
    if (percentage < 100) {
      percentX = percentX + 8
    }
    Canvas.print("]", 5 + 3 * 29, top, Color.white)
    Canvas.print("%(percentage)\%", percentX, top, Color.white)
  }

  drawUI(left, top) {
    Canvas.line(left, top, left, Canvas.height, Color.darkgray)

    var uiTop = top
    if (_model["currentRooms"].all {|room| !room.light }) {
      Canvas.rectfill(130, uiTop, 70, 12, Color.red)
      Canvas.print("Darkness", 133, uiTop + 2, Color.black)
    } else {
      Canvas.rect(129, uiTop, 71, 12, Color.darkgray)
      Canvas.print("Darkness", 133, uiTop + 2, Color.darkgray)
    }

    // Render one animation at a time
    if (_animations.count > 0) {
      _animations[0].draw()
    }

  }

}

