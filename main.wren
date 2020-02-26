import "dome" for Window, Process
import "graphics" for Canvas, Color, ImageData
import "input" for Keyboard
import "./action" for MoveAction, DanceAction
import "./events" for GameOverEvent
import "./actor" for Player
import "./game" for GameModel
import "./map" for TileMap, Tile
import "./dir" for Dir
import "./keys" for Key

var Keys = [
  "left",
  "right",
  "up",
  "down"
].map {|key| Key.new(key, true, MoveAction.new(key)) }.toList
var DanceKey = Key.new("space", true, DanceAction.new())
Keys.add(DanceKey)


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
  update() { _t = t + 1 }
  draw() {}
}

class Game {

  static init() {
    var scale = 3
    Canvas.resize(128, 128)
    Window.resize(scale * 128, scale * 128)
    __previous = {
      "left": false,
      "right": false,
      "up": false,
      "down": false
    }
    var map = TileMap.init(16, 16)
    map.set(3, 0, Tile.new(2, { "teleport": true }))
    __events = []
    __animations = []
    var entities = [
      Player.new(1, 6)
    ]

    __model = GameModel.level(map, entities)
    __tiles = ImageData.loadFromFile("res/tilemap.png")
    __ready = true

    updateState()
  }

  static updateState() {
    __currentMap = __model.map
    __currentEnergy = __model.energy
    __gameOver = __gameOverImminent || false
  }

  static draw(dt) {
    Canvas.cls()
    var map = __currentMap
    if (__gameOver) {
      // TODO UI Stacking system
      Canvas.print("Game Over", 0, map.height * 8, Color.white)

    } else {
      Canvas.print("Energy: %(__currentEnergy)", 0, map.height * 8, Color.white)
    }
    for (y in 0...map.height) {
      for (x in 0...map.width) {
        var tile = map.get(x, y)
        if (tile.type == 0) {
          Canvas.print(".", x * 8, y * 8, Color.darkgray)
        } else {
          Canvas.print("*", x * 8, y * 8, Color.blue)
        }
        // __tiles.drawArea(16 * tile.type, 0, 16, 16, 8 + x * 16, 8 + y * 16)
      }
    }

    // __sprites.each {|sprite| sprite.draw() }

    __model.entities.each {|entity|
      if (entity.type == "player") {
        Canvas.rectfill(8 * entity.x, 8*entity.y, 8, 8, Color.black)
        Canvas.print("@", 8 * entity.x, 8 * entity.y, Color.white)
      }
    }

/*
    if (__animations.count > 0) {
      var a = __animations[0]
      /*
      var h = (a.source.y-a.target[1]).abs - 1
      Canvas.rectfill(a.source.x*16+12, a.source.y*16+24, 8, h*16,Color.yellow)
      */
      a.draw()
      if (a.done) {
        __animations.removeAt(0)
      }
    }
    */
  }



  static update() {
    if (Keyboard.isKeyDown("escape")) {
      Process.exit()
    }
    Keys.each { |key| key.update() }
    if (__ready) {
      var previous = __previous
      for (key in Keys) {
        if (key.firing) {
          System.print("action %(key.action.type)")
          __model.player.action = key.action
          break
        }
      }
      var result = __model.process()
      __ready = __ready && !result.progress && result.events.count == 0
      __animations = processEvents(result.events)
    } else {
      // TODO: Initiate animations and state transitions here
      __animations.each {|animation| animation.update() }

      __ready = __animations.count == 0
      if (__ready) {
        updateState()
        if (__gameOver) {

        }
      }
    }

  }
  static processEvents(events) {
    return events.map {|event|
      if (event is GameOverEvent) {
        __gameOverImminent = true
        return null
      } else {
        return null
      }
      return event
    }.where {|animation| animation != null }.toList
  }
}

