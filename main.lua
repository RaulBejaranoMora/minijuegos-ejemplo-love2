local menu = {
    {"Crazy Basket", "crazybasket"},
    {"Crazy Racing", "crazyracing"},
    -- Se puede agregar más mini-juegos aquí, por ejemplo:
    -- {"Otro Juego", "otro_juego"}
}
local selected = 1
local state = "menu"

-- Referencia a los módulos de mini-juegos
local games = {}

-- Variables de color para el menú
local COLOR_BG = {0, 0, 0}
local COLOR_TEXT = {255, 255, 255}
local COLOR_SELECTED = {255, 255, 0}

function resetMenu()
    love.window.setMode(800, 600) -- Dimensiones del menú
    love.window.setTitle("Menú Principal")
    love.graphics.setFont(love.graphics.newFont(24)) -- Tamaño de letra para el menú
end

function love.load()
    games.crazybasket = require("crazybasket")
    -- Si tienes más mini-juegos, cárgalos aquí
    resetMenu()
end

function love.keypressed(key)
    if state == "menu" then
        if key == "down" then
            selected = math.min(selected + 1, #menu)
        elseif key == "up" then
            selected = math.max(selected - 1, 1)
        elseif key == "return" or key == "space" then
            state = menu[selected][2]
            if games[state] and games[state].start then
                games[state].start()
            end
        end
    else
        if key == "escape" then
            if games[state] and games[state].finish then
                games[state].finish()
            end
            state = "menu"
            resetMenu()
        end
        -- Propaga el evento al mini-juego si existe
        if games[state] and games[state].keypressed then
            games[state].keypressed(key)
        end
    end
end

function love.update(dt)
    if state == "menu" then
        -- No hace nada en el menú
    elseif games[state] and games[state].update then
        games[state].update(dt)
    end
end

function love.draw()
    if state == "menu" then
        love.graphics.setBackgroundColor(COLOR_BG)
        love.graphics.setColor(COLOR_TEXT)
        love.graphics.printf("Selecciona un mini-juego:", 0, 100, love.graphics.getWidth(), "center")
        for i, item in ipairs(menu) do
            if i == selected then
                love.graphics.setColor(COLOR_SELECTED)
            else
                love.graphics.setColor(COLOR_TEXT)
            end
            love.graphics.printf(item[1], 0, 150 + i * 40, love.graphics.getWidth(), "center")
        end
        love.graphics.setColor(COLOR_TEXT)
        love.graphics.printf("Usa teclas arriba/abajo para navegar, Enter para seleccionar", 0, 350, love.graphics.getWidth(), "center")
    elseif games[state] and games[state].draw then
        games[state].draw()
    end
end
