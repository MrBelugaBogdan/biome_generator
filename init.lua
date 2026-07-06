-- =======================================================
-- MOD: biome_generator
-- =======================================================

minetest.register_privilege("biome_gen", {
    description = "Allows the player to use the Biome Spawner Commander block.",
    give_to_singleplayer = true,
})

local biomes = {
    fungal = "biome_generator:fungal_dirt",
    radiation = "biome_generator:radioactive_block",
    volcanic = "biome_generator:ash_block",
    frozen = "biome_generator:frozen_dirt",
    cyber = "biome_generator:cyber_block"
}

minetest.register_node(biomes.fungal, {
    description = "Fungal Dirt",
    tiles = {"fungal_dirt.png"},
    groups = {crumbly = 3, soil = 1},
    sounds = minetest.node_sound_dirt_defaults(),
})

minetest.register_node(biomes.radiation, {
    description = "Radioactive Block",
    tiles = {"radioactive_dirt.png"},
    light_source = 9,
    groups = {crumbly = 3},
    sounds = minetest.node_sound_dirt_defaults(),
})

minetest.register_node(biomes.volcanic, {
    description = "Volcanic Ash Block",
    tiles = {"volcanic_ash.png"},
    groups = {crumbly = 3, sand = 1},
    sounds = minetest.node_sound_sand_defaults(),
})

minetest.register_node(biomes.frozen, {
    description = "Frozen Dirt",
    tiles = {"frozen_dirt.png"},
    groups = {crumbly = 3, cools_lava = 1},
    sounds = minetest.node_sound_dirt_defaults(),
})

minetest.register_node(biomes.cyber, {
    description = "Cyber Neon Block",
    tiles = {"cyber_block.png"},
    light_source = 12,
    groups = {cracky = 1},
    sounds = minetest.node_sound_stone_defaults(),
})

local function transform_area(pos, radius, target_node)
    local max_safe_radius = 25
    if radius > max_safe_radius then
        radius = max_safe_radius
    elseif radius < 1 then
        radius = 1
    end

    local minp = {x = pos.x - radius, y = pos.y - radius, z = pos.z - radius}
    local maxp = {x = pos.x + radius, y = pos.y + radius, z = pos.z + radius}
    
    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(minp, maxp)
    local data = vm:get_data()
    local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
    
    local id_target = minetest.get_content_id(target_node)
    local id_dirt = minetest.get_content_id("default:dirt")
    local id_grass = minetest.get_content_id("default:dirt_with_grass")
    local id_desert_sand = minetest.get_content_id("default:desert_sand")

    for z = minp.z, maxp.z do
    for y = minp.y, maxp.y do
    for x = minp.x, maxp.x do
        local vi = area:index(x, y, z)
        if data[vi] == id_dirt or data[vi] == id_grass or data[vi] == id_desert_sand then
            data[vi] = id_target
        end
    end
    end
    end

    vm:set_data(data)
    vm:write_to_map(string)
    vm:update_map()
end

local function get_spawner_formspec()
    return "size[6,6.5]" ..
           "label[0.5,0.5;=== BIOME SPAWNER CONTROL ===]" ..
           "field[0.8,1.8;4.5,1;radius;Enter Radius (1-25 max);15]" ..
           "label[0.5,2.8;Select Target Biome:]" ..
           "dropdown[0.5,3.3;5,1;biome_select;Fungal Biome,Radiation Zone,Volcanic Ash,Frozen Wasteland,Cyber Neon City;1]" ..
           "button_exit[1.5,5.0;3,1;start_spawner;START TERRAFORM]"
end

minetest.register_node("biome_generator:spawner", {
    description = "Biome Spawner Commander",
    tiles = {"spawner_top.png", "spawner_side.png"},
    groups = {cracky = 1, level = 2},
    
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("formspec", get_spawner_formspec())
        meta:set_string("infotext", "Biome Spawner (Requires 'biome_gen' privilege)")
    end,
    
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if not clicker then return end
        local player_name = clicker:get_player_name()
        
        if not minetest.check_player_privs(player_name, {biome_gen = true}) then
            minetest.chat_send_player(player_name, minetest.colorize("#FF0000", "[Access Denied] You do not have the 'biome_gen' privilege!"))
            return itemstack
        end
    end,
    
    on_receive_fields = function(pos, formname, fields, sender)
        if not sender then return end
        local player_name = sender:get_player_name()
        
        if not minetest.check_player_privs(player_name, {biome_gen = true}) then
            return
        end
        
        if fields.start_spawner then
            local radius = tonumber(fields.radius) or 15
            local target_node = biomes.fungal
            
            if fields.biome_select == "Radiation Zone" then
                target_node = biomes.radiation
            elseif fields.biome_select == "Volcanic Ash" then
                target_node = biomes.volcanic
            elseif fields.biome_select == "Frozen Wasteland" then
                target_node = biomes.frozen
            elseif fields.biome_select == "Cyber Neon City" then
                target_node = biomes.cyber
            end
            
            transform_area(pos, radius, target_node)
            minetest.chat_send_player(player_name, "[Biome Spawner] Successfully generated " .. fields.biome_select .. "!")
            minetest.remove_node(pos)
        end
    end
})
