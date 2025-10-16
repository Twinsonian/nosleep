local active_huds = {}
local hud_timers = {}

-- Show a fading HUD message
local function notify(player, text, duration)
    local name = player:get_player_name()

    if active_huds[name] then
        player:hud_remove(active_huds[name])
        active_huds[name] = nil
    end

    local hud_id = player:hud_add({
        hud_elem_type = "text",
        position = {x = 0.5, y = 0.2},
        offset = {x = 0, y = 0},
        alignment = {x = 0, y = 0},
        scale = {x = 100, y = 100},
        text = text,
        number = 0xFFFFFF,
    })

    active_huds[name] = hud_id

    if hud_timers[name] then
        hud_timers[name].cancelled = true
    end

    local timer = {cancelled = false}
    hud_timers[name] = timer

    minetest.after(duration or 3, function()
        if not timer.cancelled and player and active_huds[name] == hud_id then
            player:hud_remove(hud_id)
            active_huds[name] = nil
            hud_timers[name] = nil
        end
    end)
end

-- Show a black screen overlay to mask respawn flash
local function fade_black(player, duration)
    local hud_id = player:hud_add({
        hud_elem_type = "image",
        position = {x = 0.5, y = 0.5},
        scale = {x = -100, y = -100},
        text = "black.png",
    })

    minetest.after(duration or 1, function()
        if player and hud_id then
            player:hud_remove(hud_id)
        end
    end)
end

-- Override all beds to block sleep and set custom spawn
minetest.after(1, function()
    for name, def in pairs(minetest.registered_nodes) do
        if name:find("bed") then
            minetest.override_item(name, {
                on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
                    local pname = clicker:get_player_name()
                    local pos = clicker:get_pos()
                    if not pos then return itemstack end

                    local spawn_str = minetest.pos_to_string(vector.round(pos))
                    clicker:get_meta():set_string("spawn", spawn_str)
                    notify(clicker, "Spawn point set", 3)

                    return itemstack
                end
            })

        end
    end
end)

-- Teleport player to saved spawn on respawn
minetest.register_on_respawnplayer(function(player)
    local name = player:get_player_name()
    local spawn = player:get_meta():get_string("spawn")

    fade_black(player, 1) -- Mask the default respawn flash

    if spawn and spawn ~= "" then
        local pos = minetest.string_to_pos(spawn)
        if pos then
            minetest.after(0.25, function()
                local p = minetest.get_player_by_name(name)
                if p then
                    p:set_pos(pos)
                end
            end)
        end
    end

    return false -- Let default respawn happen, then override
end)

