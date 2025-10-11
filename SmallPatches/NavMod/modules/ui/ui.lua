
UI = {
    NavMod = nil,
}

function UI.init(NavMod)
    UI.NavMod = NavMod
end

function ftos(number)
    return string.format( "%.3f", number)
end

function vecToString(vec4)
    return "x: " .. ftos(vec4.x) .. " y: " .. ftos(vec4.y) .. " z: " .. ftos(vec4.z)
end

function UI.draw(curPos)
    ImGui.Begin("NavMod")

    if ImGui.SmallButton("To Clipboard") then
        ImGui.SetClipboardText(vecToString(curPos))
    end

    ImGui.Text(vecToString(curPos))

    ImGui.End()
end

return UI