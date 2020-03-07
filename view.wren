import "dome" for Window
import "graphics" for Canvas, Color, ImageData
import "input" for Keyboard
import "math" for M, Vec
import "./dir" for Dir
import "./generator" for StaticRoomGenerator
import "./action" for PlayerMoveAction,
  DanceAction,
  RestAction,
  ChargeWeaponAction,
  FireWeaponAction
import "./model" for GameModel
import "./keys" for Key
import "./tiles" for Tiles
import "./actor" for FULL_POWER
import "./events" for
  GameOverEvent,
  WinEvent,
  MoveEvent,
  LogEvent,
  SelfDestructEvent,
  MenuEvent,
  DamagePlayerEvent

import "./line" for GridVisitor


var BORDER = 9
var TILE_WIDTH = 8
var TILE_HEIGHT = 8
var MAROON = Color.rgb(128, 0, 0)

var Inputs = [
  "left",
  "right",
  "up",
  "down"
].map {|key| Key.new(key, PlayerMoveAction.new(Dir[key]), true) }.toList
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

class QuickFlashAnimation is Animation {
  construct begin() {
    _length = 60 * 0.25
    _color = Color.rgb(255, 0, 0, 128)
  }

  update(view) {
    super.update(view)
    done = t >= _length
  }

  draw() {
    Canvas.rectfill(0, 0, (1 + 2 * BORDER) * TILE_WIDTH, (1 + 2 * BORDER) * TILE_HEIGHT, _color)
  }
}
class FlashAnimation is Animation {
  construct begin() {
    _cycle = 30
    _length = 60 * 3
    _color = Color.rgb(255, 0, 0, 128)
  }

  update(view) {
    super.update(view)
    done = t >= _length
  }

  draw() {
    if (t % 60 < _cycle) {
      Canvas.rectfill(0, 0, (1 + 2 * BORDER) * TILE_WIDTH, (1 + 2 * BORDER) * TILE_HEIGHT, _color)
    }
  }

}

class MenuEffect is Animation {
  construct begin(items) {
    _items = items
    _position = 0
    _upKey = Key.new("up", -1, true)
    _downKey = Key.new("down", 1, true)
    _keys = [
      _upKey,
      _downKey
    ]
  }
  update(view) {
    super.update(view)
    // SPACE_KEY.update()
    _keys.each {|key|
      key.update()
      if (key.firing) {
        _position = _position + key.action
      }
    }
    _position = M.abs(_position % (_items.count))
    if (SPACE_KEY.firing) {
      done = true
      view.model.player.action = _items[_position][1]
    }
  }

  draw() {
    var width = Canvas.width / 2
    var height = Canvas.height / 2
    Canvas.rect(Canvas.width / 4, Canvas.height / 4, width, height, Color.white)
    Canvas.rect(Canvas.width / 4 + 1, Canvas.height / 4 + 1, width - 2, height - 2, Color.white)
    Canvas.rectfill(Canvas.width / 4 + 2, Canvas.height / 4 + 2, width - 4, height - 4, Color.black)
    var top = Canvas.height / 4 + 4
    var y = top
    var x = Canvas.width / 4 + 4 + 8
    for (item in _items) {
      Canvas.print(item[0], x, y, Color.green)
      y = y + 8
    }
    Canvas.print(">", x - 8, top + _position * 8, Color.green)
  }
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
  construct begin(frames) {
    _bounds = frames
  }
  construct begin() {
    _bounds = 10
  }
  update(view) {
    super.update(view)
    if (t > _bounds) {
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
      camera.x = player.x // M.round(camera.x)
      camera.y = player.y // M.round(camera.y)
    }
  }
}



class GameView {
  construct init(gameModel) {
    _model = gameModel
    init()
  }
  init() {
    _log = []
    _events = []
    _animations = [ WaitAnimation.begin(), GameBeginAnimation.begin() ]
    _ready = true
    _gameOver = false
    _camera = Vec.new(_model.player.x, _model.player.y)
    updateState()
    /*
    GridVisitor.bfs(_model.map, Vec.new(), Fn.new {|pos|
      Canvas.rectfill(pos.x * TILE_WIDTH, pos.y * TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT, Color.purple)
    })
    */
  }

  camera { _camera }
  model { _model }
  model=(v) {
    _model = v
    init()
  }

  update() {
      Inputs.each { |input| input.update() }
    _ready = _animations.count == 0
    // _ready = _ready && !result.progress && result.events.count == 0
    if (_ready) {
      for (input in Inputs) {
        if (input.firing) {
          _model.player.action = input.action
          break
        }
      }
      var result = _model.process()
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
        return  [ GameLoseAnimation.begin() ]
      } else if (event is WinEvent) {
        _gameOver = true
        return  [ GameWinAnimation.begin() ]
      } else if (event is LogEvent) {
        System.print(event.text)
        _log.add([ event.priority, event.text ])
        _log = _log.skip(M.max(0, _log.count - 3)).toList
      } else if (event is MenuEvent) {
        return [ WaitAnimation.begin(8), MenuEffect.begin(event.menu) ]
      } else if (event is DamagePlayerEvent) {
        return  [ QuickFlashAnimation.begin() ]
      } else if (event is SelfDestructEvent) {
        return [ FlashAnimation.begin() ]
      } else if (event is MoveEvent) {
        if (event.source == _model.player) {
          camera.x = _model.player.x // M.round(camera.x)
          camera.y = _model.player.y // M.round(camera.y)
          return [ CameraAnimation.begin() ]
        }
      }
      return []
    }.reduce ([]) {|acc, animation| acc + animation }.toList
  }

  draw() {
    Canvas.cls()
    var map = _currentMap
    var player = _model.player


    // Border is number of tiles
    var border = BORDER
    var displayW = (2 * border + 1) * TILE_WIDTH
    var displayH = (2 * border + 1) * TILE_HEIGHT
    var top = 0 // (Canvas.height - displayH) / 2
    var left = 0
    var offX = left + (displayW / 2) - (camera.x * TILE_WIDTH)
    var offY = top + (displayH / 2) - (camera.y * TILE_HEIGHT)

    var minX = M.max(player.x - border, 0)
    var maxX = M.min(player.x + border, map.width)
    var minY = M.max(player.y - border, 0)
    var maxY = M.min(player.y + border, map.height)


    for (y in minY...maxY) {
      for (x in minX...maxX) {
        var tile = map.get(x, y)
        if (tile["light"] != null && tile["light"] > 0) {
        // if (!tile["dark"] && (Vec.new(x, y) - camera).length < border) {
          if (tile.type == Tiles.floor.type) {
            if (tile["light"] == 2) {
              Canvas.print(tile.type, offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT, Color.darkgray)
            } else {
              Canvas.print(tile.type, offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT, Color.darkblue)
            }
          } else if (tile.type == Tiles.wall.type) {
            if (tile["light"] == 2) {
              Canvas.print(tile.type, offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT, Color.darkgray)
            } else {
              Canvas.print(tile.type, offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT, Color.darkblue)
            }
          } else if (tile.type == Tiles.console.type) {
            Canvas.print(tile.type, offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT, Color.blue)
          } else if (tile.type == Tiles.sludge.type) {
            if (tile["light"] == 2) {
              Canvas.rectfill(offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT, 7, 8, Color.brown)
              Canvas.print(tile.type, offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT + 3, Color.white)
            } else {
              Canvas.print(tile.type, offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT + 3, Color.darkblue)
            }
          } else if (tile.type == Tiles.airlock.type) {
            Canvas.rectfill(offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT, 7, 8, Color.red)
            Canvas.print(tile.type, offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT, Color.black)

          } else if (tile.type == Tiles.door.type) {
            // What kind of door is it?
            var color = Color.darkgreen
            if (tile["locked"]) {
              color = Color.hex("#800000")
            }
            if (tile["light"] < 2) {
              color = Color.darkblue
            }
            Canvas.rectfill(offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT, 7, 8, color)
            Canvas.print(tile.type, offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT, Color.black)
          } else {
            Canvas.print(tile.type, offX + x * TILE_WIDTH, offY + y * TILE_HEIGHT, Color.blue)
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
        Canvas.print("j", offX + TILE_WIDTH * entity.x, offY + TILE_HEIGHT * entity.y, Color.green)
      } else if (entity.type == "chargeball") {
        if (entity.state == "charging") {
          var diff = entity.pos - player.pos
          Canvas.print("*", offX + TILE_WIDTH * (camera.x + diff.x), offY + TILE_HEIGHT * (camera.y +  diff.y), Color.blue)
        } else {
          Canvas.print("*", offX + TILE_WIDTH * (entity.x), offY + TILE_HEIGHT * (entity.y), Color.blue)
        }
      }
    }
    // Canvas.rectfill(left, top - 12, displayW, TILE_HEIGHT, Color.black)
    Canvas.rect(left, top, displayW+1, displayH, Color.darkgray)

    drawLog(0, displayH + 8 + 4)
    drawPowerBar(0, top + displayH)
    Canvas.line(displayW, top, displayW, Canvas.height, Color.darkgray)
    if (!_gameOver) {
      drawSidebar(displayW, top)
    }

    // Render one animation at a time
    if (_animations.count > 0) {
      _animations[0].draw()
    }
  }
  drawLog(left, top) {
    // Canvas.rectfill(left, top, 64, Canvas.height, Color.black)
    var baseline = top + 8 * 2
    for (logIndex in 0..._log.count)  {
      var lineY = baseline + (logIndex - 2) * 8
      var line = _log[logIndex][1]
      var priority = _log[logIndex][0]
      var color = Color.white
      if (priority == "high") {
        color = Color.red
      }
      if (priority == "success") {
        color = Color.green
      }
      if (logIndex != _log.count - 1) {
        // color = priority == "high" ? Color.red : Color.white
        color = Color.rgb(color.r, color.g, color.b, color.a * 0.5)
      }
      Canvas.print(line, left, lineY, color)
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
    var percentage = (100 * player.power / FULL_POWER).ceil
    var percentX = 8 + 3 * 30
    if (percentage < 100) {
      percentX = percentX + 8
    }
    Canvas.print("]", 5 + 3 * 29, top, Color.white)
    Canvas.print("%(percentage)\%", percentX, top, Color.white)
  }

  drawSidebar(left, top) {

    var uiTop = top + 4
    var width = Canvas.width - left
    var textCenter = left + (width - 8 * 8) / 2
    Canvas.rectfill(left, top, width, Canvas.height, Color.darkgray )
    if (_model["currentRooms"].all {|room| !room.light }) {
      Canvas.rectfill(left + 2, uiTop, width - 4, 12, Color.red)
      Canvas.print("Darkness", textCenter, uiTop + 2, Color.black)
    } else {
      Canvas.rectfill(left, uiTop, width, 12, Color.black)
      Canvas.print("Darkness", textCenter, uiTop + 2, Color.darkgray)
      Canvas.rectfill(left, uiTop, 2, 12, Color.darkgray)
      Canvas.rectfill(Canvas.width - 2, uiTop, 2, 12, Color.darkgray)
    }
    var nameTop = Canvas.height - 30
    Canvas.rectfill(left + 2, nameTop - 2, width - 4, Canvas.height - (nameTop - 2), Color.darkgray)
    uiTop = uiTop + 12 + 4
    Canvas.rectfill(left + 2, uiTop, width - 4, (Canvas.height - uiTop - 2), Color.black)
    if (_model["self-destruct"] != null) {
      Canvas.print("%(_model["self-destruct"]) turns", Canvas.width - 10 * TILE_WIDTH, Canvas.height - 10, Color.red)
    }
    var name = _model["currentRooms"][0].breed.name
    var nameLeft = left + (width - name.count * 8) / 2
    Canvas.print(name, nameLeft, nameTop, Color.orange)

  }

}

