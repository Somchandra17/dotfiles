-- Viewport strip for niri. The published ribbon is a Quickshell plugin, which
-- Noctalia 5 cannot load, so this entry speaks the current plugin API.

local ratioStart = 0
local ratioWidth = 1
local leftCount = 0
local rightCount = 0

local function render()
  local track = 132
  local viewW = math.max(16, math.floor(track * ratioWidth + 0.5))
  local leftW = math.floor(track * ratioStart + 0.5)
  if leftW + viewW > track then
    leftW = math.max(0, track - viewW)
  end
  local rightW = math.max(0, track - leftW - viewW)
  local trackChildren = {}
  if leftW > 0 then
    table.insert(trackChildren, ui.box({ width = leftW, height = 8 }))
  end
  table.insert(trackChildren, ui.box({ width = viewW, height = 8, fill = "primary", radius = 3 }))
  if rightW > 0 then
    table.insert(trackChildren, ui.box({ width = rightW, height = 8 }))
  end

  local children = {}
  if leftCount > 0 then
    table.insert(children, ui.label({
      text = tostring(leftCount),
      fontSize = 12,
      fontWeight = "bold",
      color = "on_surface",
    }))
  end
  table.insert(children, ui.row({
    width = track,
    height = 10,
    align = "center",
    gap = 0,
    radius = 4,
    fill = "surface_variant/0.45",
    tooltip = string.format("%d columns off to the left, %d off to the right", leftCount, rightCount),
  }, trackChildren))
  if rightCount > 0 then
    table.insert(children, ui.label({
      text = tostring(rightCount),
      fontSize = 12,
      fontWeight = "bold",
      color = "on_surface",
    }))
  end
  barWidget.render(ui.row({ gap = 6, align = "center" }, children))
end

local function apply(line)
  local leftText, rightText, startText, widthText = string.match(line, "^(%d+)|(%d+)|([%d%.]+)|([%d%.]+)$")
  if leftText == nil then
    return
  end
  leftCount = tonumber(leftText) or 0
  rightCount = tonumber(rightText) or 0
  ratioStart = tonumber(startText) or 0
  ratioWidth = tonumber(widthText) or 1
  render()
end

local script = noctalia.expandPath("~/.local/share/noctalia/plugins/niri-ribbon/niri_ribbon.py")
noctalia.runStream("python3 " .. script, apply)

function update()
  noctalia.setUpdateInterval(60000)
  render()
end
