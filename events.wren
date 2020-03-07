class Event {}

class MoveEvent is Event {
  construct new(source, direction) {
    _source = source
    _direction = direction
  }
  source { _source }
  direction { _direction }

}

class DamagePlayerEvent is Event {
  construct new() {}
}

class WinEvent is Event {
  construct new() {}
}
class GameOverEvent is Event {
  construct new() {}
}
class EnergyDepletedEvent is Event {
  construct new() {}
}

class LogEvent is Event {
  construct new(text) {
    _text = text
    _priorty = "low"
  }

  construct new(text, priority) {
    _text = text
    _priority = priority
  }
  text { _text }
  priority { _priority }
}

class MenuEvent is Event {
  construct new(menu) {
    _menu = menu
  }

  menu { _menu }
}

class SelfDestructEvent is Event {
  construct new() {}
}
