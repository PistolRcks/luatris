function love.conf(t)
  t.title = "LuaTris"
  t.version = "11.1" --Remember, this is the LOVE version
  t.window.width = "400" --These should probably be configurable later
  t.window.height = "800"
  t.window.vsync = true
  t.window.resizable = true
  t.window.refreshrate = 62
  t.console = true
end
