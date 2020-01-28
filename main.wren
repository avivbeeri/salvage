import "graphics" for Canvas, Color, ImageData
import "input" for Keyboard
import "./action" for MoveAction
import "./events" for BoltEvent, EnergyDepletedEvent
import "./actor" for Enemy, Player
import "./game" for GameModel
import "./dir" for Dir
import "dome" for Window, Process

var Keys = [
  "left", "right", "up", "down"
]

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

class BoltAnimation is Animation {
  construct new(source, target) {
    _source = source
    _target = target

    if (_source.y == _target[1]) {
      if (_source.x - _target[0] > 0) {
        _dir = "left"
      } else {
        _dir = "right"
      }
    } else {
      if (_source.y - _target[1] > 0) {
        _dir = "up"
      } else {
        _dir = "down"
      }
    }
  }

  draw() {
    if (_dir == "down") {
      var h = (_source.y-_target[1]).abs - 1
      Canvas.rectfill(_source.x*16+14, _source.y*16+24, 4, h*16, Color.yellow)
    } else if (_dir == "left") {
      var w = (_source.x-_target[0]).abs - 1
      Canvas.rectfill(_target[0]*16+24, _target[1]*16+14, w*16, 4, Color.yellow)
    } else if (_dir == "right") {
      var w = (_source.x-_target[0]).abs - 1
      Canvas.rectfill(_source.x*16+24, _source.y*16+14, w*16, 4, Color.yellow)
    } else {
      var h = (_source.y-_target[1]).abs - 1
      Canvas.rectfill(_target[0]*16+14, _target[1]*16+24, 4, h*16, Color.yellow)
    }

    if (this.t > 3) {
      this.done = true
    }
  }

}

class Game {

  static init() {
    Canvas.resize(128, 128)
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
      Player.new(1, 6),
      Enemy.new("enemy", 2,1, "down"),
      Enemy.new("enemy", 6,5, "left"),
      Enemy.new("enemy", 2,4, "right"),
      Enemy.new("enemy", 0,6, "up")
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
    __gameOver = __gameOverImminent || false
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
    if (__gameOver) {
      // TODO UI Stacking system
      Canvas.print("Game Over", 0, 0, Color.white)

    } else {
      Canvas.print("Energy: %(__currentEnergy)", 0, 0, Color.white)
    }
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
        __enemySprite.transform({
          "angle": Angles[entity.dir]
        }).draw(entity.x*16+8, entity.y*16+8)
        if (entity.state == "charging") {
          var dir = Dir[entity.dir]
          Canvas.circlefill(entity.x*16+16+(8*dir["x"]), entity.y*16+16+(dir["y"]*8), 3, Color.yellow)
          // Canvas.circlefill(entity.x*16+15, entity.y*16+24, 3, Color.yellow)

        }
      }
    }

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
  }


  static update() {
    if (Keyboard.isKeyDown("escape")) {
      Process.exit()
    }
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
      if (event is BoltEvent) {
        return BoltAnimation.new(event.source, event.target)
      } else if (event is EnergyDepletedEvent) {
        __gameOverImminent = true
        return null
      }
      return event
    }.where {|animation| animation != null }.toList
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

