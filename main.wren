import "dome" for Window
import "graphics" for Canvas, Color
import "dome" for Process
import "input" for Keyboard
import "./model" for GameModel
import "./view" for GameView
import "./generator" for StaticRoomGenerator

class Game {
  static init() {
    // var level = StaticRoomGenerator.generate([])
    // __view = GameView.init(GameModel.level(level))
    var scale = 3
    Canvas.resize(256, 192)
    Window.resize(scale * Canvas.width, scale * Canvas.height)
    Window.title = "Salvage"
    __view = TitleMenu.init()
  }

  static update() {
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
    var left = 15
    var top = 10
    Canvas.print("Press space to begin", left, top, Color.white)
    Canvas.print("    the mission", left, top + 8, Color.white)
  }

}
