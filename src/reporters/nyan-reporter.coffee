logger = require './../logger'
tty = require 'tty'

class NyanCatReporter
  constructor: (emitter, stats, tests) ->
    @type = "nyan"
    @stats = stats
    @tests = tests
    @isatty = tty.isatty 1 and tty.isatty 2
    windowWidth = (if @isatty then (if process.stdout.getWindowSize then process.stdout.getWindowSize(1)[0] else tty.getWindowSize()[1]) else 75)
    width = windowWidth * .75 | 0
    @rainbowColors = @generateColors()
    @colorIndex = 0
    @numberOfLines = 4
    @trajectories = [[], [], [], []]
    @nyanCatWidth = 11
    @trajectoryWidthMax = (width - @nyanCatWidth)
    @scoreboardWidth = 5
    @tick = 0
    @errors = []
    @configureEmitter emitter

  configureEmitter: (emitter) =>
    emitter.on 'start', =>
      @cursorHide()
      @draw()

    emitter.on 'end', =>
      @cursorShow()
      i = 0

      while i < @numberOfLines
        write "\n"
        i++

      if @errors.length > 0
          process.stdout.write "\n"
          logger.info "Displaying failed tests..."
          for test in @errors
            logger.fail test.title + " duration: #{test.duration}ms"
            logger.fail test.message
            logger.request "\n" + (JSON.stringify test.request, null, 4) + "\n"
            logger.expected "\n" + (JSON.stringify test.expected, null, 4) + "\n"
            logger.actual "\n" + (JSON.stringify test.actual, null, 4) + "\n\n"

      logger.complete "#{@stats.passes} passing, #{@stats.failures} failing, #{@stats.errors} errors, #{@stats.skipped} skipped"
      logger.complete "Tests took #{@stats.duration}ms"


    emitter.on 'test pass', (test) =>
      @draw()

    emitter.on 'test skip', (test) =>
      @draw()

    emitter.on 'test fail', (test) =>
      @errors.push test
      @draw()

    emitter.on 'test error', (test, error) =>
      @errors.push test
      @draw()

  draw: =>
    @appendRainbow()
    @drawScoreboard()
    @drawRainbow()
    @drawNyanCat()
    @tick = not @tick

  drawScoreboard: =>
    draw = (color, n) ->
      write " "
      write "\u001b[" + color + "m" + n + "\u001b[0m"
      write "\n"
    stats = @stats
    colors =
      fail: 31
      skipped: 36
      pass: 32

    draw colors.pass, @stats.passes
    draw colors.fail, @stats.failures
    draw colors.fail, @stats.errors
    draw colors.skipped, @stats.skipped

    write "\n"
    @cursorUp @numberOfLines + 1

  appendRainbow: =>
    segment = (if @tick then "_" else "-")
    rainbowified = @rainbowify(segment)
    index = 0

    while index < @numberOfLines
      trajectory = @trajectories[index]
      trajectory.shift()  if trajectory.length >= @trajectoryWidthMax
      trajectory.push rainbowified
      index++

  drawRainbow : =>
    scoreboardWidth = @scoreboardWidth
    @trajectories.forEach (line, index) ->
      write "\u001b[" + scoreboardWidth + "C"
      write line.join("")
      write "\n"

    @cursorUp @numberOfLines

  drawNyanCat: =>
    startWidth = @scoreboardWidth + @trajectories[0].length
    color = "\u001b[" + startWidth + "C"
    padding = ""
    write color
    write "_,------,"
    write "\n"
    write color
    padding = (if @tick then "  " else "   ")
    write "_|" + padding + "/\\_/\\ "
    write "\n"
    write color
    padding = (if @tick then "_" else "__")
    tail = (if @tick then "~" else "^")
    face = undefined
    write tail + "|" + padding + @face() + " "
    write "\n"
    write color
    padding = (if @tick then " " else "  ")
    write padding + "\"\"  \"\" "
    write "\n"
    @cursorUp @numberOfLines

  face: =>
    stats = @stats
    if stats.failures
      "( x .x)"
    else if stats.skipped
      "( o .o)"
    else if stats.passes
      "( ^ .^)"
    else
      "( - .-)"

  cursorUp: (n) =>
    write "\u001b[" + n + "A"

  cursorDown: (n) =>
    write "\u001b[" + n + "B"

  cursorShow: =>
    @isatty && process.stdout.write '\u001b[?25h'

  cursorHide: =>
    @isatty and process.stdout.write '\u001b[?25l'

  generateColors: =>
    colors = []
    i = 0

    while i < (6 * 7)
      pi3 = Math.floor(Math.PI / 3)
      n = (i * (1.0 / 6))
      r = Math.floor(3 * Math.sin(n) + 3)
      g = Math.floor(3 * Math.sin(n + 2 * pi3) + 3)
      b = Math.floor(3 * Math.sin(n + 4 * pi3) + 3)
      colors.push 36 * r + 6 * g + b + 16
      i++
    colors

  rainbowify: (str) =>
    color = @rainbowColors[@colorIndex % @rainbowColors.length]
    @colorIndex += 1
    "\u001b[38;5;" + color + "m" + str + "\u001b[0m"


write = (string) ->
  process.stdout.write string


module.exports = NyanCatReporter
