import "graphics" for Canvas, Color, ImageData
import "input" for Keyboard

var Keys = [
  "left", "right", "up", "down"
]

class Game {

  static init() {
    __previous = {
      "left": false,
      "right": false,
      "up": false,
      "down": false
    }
    var map = [
      0,0,0,2,0,0,0,
      0,0,0,0,0,0,0,
      0,0,0,0,0,0,0,
      0,1,0,1,0,1,0,
      0,0,0,0,0,0,0,
      0,0,0,0,0,0,0,
      0,0,0,0,0,0,0
    ]
    __events = []
    __animations = []
    var entities = [
      Player.new(3,2),
      Enemy.new("enemy", 2,1)
    ]

    __model = GameModel.level(map, entities)
    __tiles = ImageData.loadFromFile("res/tilemap.png")
    __playerSprite = ImageData.loadFromFile("res/robot.png")
    __enemySprite = ImageData.loadFromFile("res/enemy.png")
    __ready = true

    updateState()
  }

  static updateState() {
    __currentMap = __model.map.toList
    __currentEnergy = __model.energy
    __sprites = __model.entities.map {|entity|
      if (entity.type == "player") {
        return PlayerSprite.new(entity)
      } else {
        return Sprite.new(entity)
      }
    }
  }

  static draw(dt) {
    Canvas.cls()
    Canvas.print("Energy: %(__currentEnergy)", 0, 0, Color.white)
    var map = __currentMap
    for (y in 0...7) {
      for (x in 0...7) {
        var index = y * 7 + x
        var tile = map[index]
        __tiles.drawArea(16 * tile, 0, 16, 16, 8 + x * 16, 8 + y * 16)
      }
    }
    Canvas.rect(7, 7, 16*7+2, 16*7+2, Color.blue)

    __sprites.each {|sprite| sprite.draw() }
    __model.entities.each {|entity|
      if (entity.type == "enemy") {
        Canvas.draw(__enemySprite, entity.x*16+8, entity.y*16+8)
        if (entity.state == "charging") {
          Canvas.circlefill(entity.x*16+15, entity.y*16+24, 3, Color.yellow)

        }
      }
    }

    if (__animations.count > 0) {
      var a = __animations[0]
      var h = (a.source.y-a.target[1]).abs - 1
      Canvas.rectfill(a.source.x*16+12, a.source.y*16+24, 8, h*16,Color.yellow)


      __animations.removeAt(0)
    }
  }


  static update() {
    if (__ready) {
      var previous = __previous
      var found = false
      for (key in Keys) {
        var current = Keyboard.isKeyDown(key)
        if (!found) {
          if (current && !previous[key]) {
            found = true
            System.print("action %(key)")
            __model.player.action = MoveAction.new(key)
          }
          previous[key] = current
        }
      }
      var result = __model.process()
      __ready = __ready && !result.progress && result.events.count == 0
      __animations = processEvents(result.events)
    } else {
      System.print(__events)

      // TODO: Initiate animations and state transitions here

      __ready = __animations.count == 0
      if (__ready) {
        updateState()
      }
    }

  }
  static processEvents(events) {
    return events.map {|event|
      return event
    }.toList
  }
}

class Sprite {
  construct new(entity) {
    _entity = entity
    _x = entity.x * 16 + 8
    _y = entity.y * 16 + 8
  }
  x { _x }
  y { _y }
  x=(v) { _x = v }
  y=(v) { _y = v }
  entity { _entity }
  image {}
  draw() {
    Canvas.draw(image, x, y)
  }
}

class PlayerSprite is Sprite {
  construct new(entity) {
    super(entity)
    _image = ImageData.loadFromFile("res/robot.png")

  }
  image { _image }
}

import "./action" for MoveAction
import "./actor" for Enemy, Player
import "./game" for GameModel
