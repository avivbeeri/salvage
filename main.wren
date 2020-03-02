import "dome" for Process
import "input" for Keyboard
import "./model" for GameModel
import "./view" for GameView
import "./generator" for StaticRoomGenerator


class Game {
  static init() {
    var level = StaticRoomGenerator.generate([])
    __view = GameView.init(GameModel.level(level))
  }

  static update() {
    if (Keyboard.isKeyDown("escape")) {
      Process.exit()
    }
    __view.update()
  }

  static draw(dt) {
    __view.draw()
  }

}

