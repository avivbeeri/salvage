import "dome" for Window
import "graphics" for Canvas, Color
import "dome" for Process
import "input" for Keyboard
import "./model" for GameModel
import "./view" for GameView
import "./keys" for Key
import "./generator" for StaticRoomGenerator
import "./filter" for ColorBlindFilter

var PAL_KEY = Key.new("tab", 1, true)

class Game {
  static init() {
    // var level = StaticRoomGenerator.generate([])
    // __view = GameView.init(GameModel.level(level))
    var scale = 3
    Canvas.resize(256, 192)
    Window.resize(scale * Canvas.width, scale * Canvas.height)
    Window.title = "Salvage"
    __view = TitleMenu.init()
    __pal = 0
  }

  static update() {
    if (PAL_KEY.update()) {
      __pal = __pal + 1
    }
    if (Keyboard.isKeyDown("escape")) {
      Process.exit()
    }
    var next = __view.update()
    if (next) {
      __view = next
    }
  }

  static draw(dt) {
    __view.draw()
    ColorBlindFilter.apply(__pal)
  }

}


class TitleMenu {
  construct init() {}
  update() {
    if (Keyboard.isKeyDown("space")) {
      var level = StaticRoomGenerator.generate([])
      var view = GameView.init(GameModel.level(level))
      return view
    }
    return null
  }
  draw() {
    var left = Canvas.width / 2 - 8 * 10
    var top = 10
    Canvas.print("Press space to begin", left, top, Color.white)
    Canvas.print("    the mission", left, top + 8, Color.white)

  }

}
