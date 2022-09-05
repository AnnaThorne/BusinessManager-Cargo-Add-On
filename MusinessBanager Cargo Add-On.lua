--[[ 

	Made by akatozi#0691
	Credits
	Ren, ICYPhoenix: MusinessBanager 
	luigistyle: AHK Loop
	Aiko: Tester
	IceDoomfist: TP Function
	Jink: Auto-Update

--]]

util.require_natives(1660775568)
local localVer = 1.43
local mb_version = "0.3.2"
local speed_sell = 1.2
local speed_res = 2.0
local warehouse_capacity = 111
local main_menu = menu.my_root()

-- Update
local response = false
async_http.init("raw.githubusercontent.com", "/akatozi/BusinessManager-Cargo-Add-On/main/Version", function(output)
    currentVer = tonumber(output)
    response = true
    if localVer ~= currentVer then
        util.toast("New BusinessManager Cargo Add-On version is available !")
        menu.action(menu.my_root(), "Update script", {}, "", function()
            async_http.init('raw.githubusercontent.com','/akatozi/BusinessManager-Cargo-Add-On/main/MusinessBanager Cargo Add-On.lua',function(a)
                local err = select(2,load(a))
                if err then
                    util.toast("Script failed to download. Please try again later. If this continues to happen then manually update via github.")
                return end
                local f = io.open(filesystem.scripts_dir()..SCRIPT_RELPATH, "wb")
                f:write(a)
                f:close()
                util.toast("Successfully updated !")
                util.stop_script()
            end)
            async_http.dispatch()
        end)
    end
end, function() response = true end)
async_http.dispatch()
repeat 
    util.yield()
until response

util.toast("Addon Version "..localVer.."\nMusiness Banager Version "..mb_version.."\n\nIMPORTANT! Make sure to check everything in MusinessBanager > Special Cargo")

-- Settings list
settings_menu = menu.list(menu.my_root(), "(Recommended) Settings", {}, "", function(); end)
menu.divider(settings_menu, "Apply settings")
menu.action(settings_menu,'Optimal Settings', {""}, 'Improve FPS and stability of the lua.\nNOTE: Reducing resolution and play on windowed mode also helps a lot.', function()
	-- Settings
	menu.trigger_commands("anticrashcamera on") 
	menu.trigger_commands("nophonespam on")
	menu.trigger_commands("potatomode on")
	menu.trigger_commands("weather clear")
	menu.trigger_commands("nosky on")
	
	-- MusinessBanager
    menu.trigger_commands("monitorcargo on")
    menu.trigger_commands("maxsellcargo on")
    menu.trigger_commands("nobuycdcargo on")
    menu.trigger_commands("nosellcdcargo on")
    menu.trigger_commands("autocompletespecialbuy on")
    menu.trigger_commands("autocompletespecialsell on")
	util.toast("Make sure to check two last toggle manually in Special Cargo !")
end)

menu.action(settings_menu,'Safe mode', {""}, 'Reduces even more risks.\nNOTE: Will make you go in solo session with spoofed session so you cant be crashed or checked by R* Admins.', function()
	menu.trigger_commands("go solo")
	menu.trigger_commands("spoofsession storymode")
end)

menu.divider(settings_menu, "Remove settings")
menu.action(settings_menu,'Default settings', {""}, 'Remove optimised settings', function()
	menu.trigger_commands("anticrashcamera off") 
	menu.trigger_commands("nophonespam off")
	menu.trigger_commands("potatomode off")
	menu.trigger_commands("nosky off")
	menu.trigger_commands("spoofsession off")
	memory.write_float(memory.script_global(262145 + 1), 1)
end)

menu.divider(settings_menu, "Other Stuff")
moneyMultiplier = menu.toggle(settings_menu, 'Remove XP Gain', {""}, 'Dont earn anymore xp with the cargo method.', function()
	if menu.get_value(moneyMultiplier) then
		memory.write_float(memory.script_global(262145 + 1), 0)
	else
		memory.write_float(memory.script_global(262145 + 1), 1)
	end
end)

menu.action(settings_menu,'Restart the game', {""}, 'Use it if you are stuck in the warehouse screen.', function()
	menu.trigger_commands("forcequittosp")
end)

menu.list_select(main_menu, 'Warehouse Size ', {""}, "Chose the size of your warehouse.", {"Large","Medium","Small"}, 1, function(warehouse_type)
	if warehouse_type == 3 then
		warehouse_capacity = 16
	elseif warehouse_type == 2 then
		warehouse_capacity = 42
	elseif warehouse_type == 1 then
		warehouse_capacity = 111
	end
end)

menu.divider(main_menu, "Automatic")
menu.slider(main_menu, 'Sell Speed', {""}, "Lower values means faster loop.\nIf you get stuck in the warehouse menu, increase value.", 0, 5, 2, 1, function(sell_value)
	speed_sell = 1 + 0.1*sell_value
	if sell_value <= 1 then
		util.toast("Low sell speed can get you stuck in the warehouse menu !\nDo it at your own risk.")
	end
end)

menu.slider(main_menu, 'Resupply Speed', {""}, "Lower values means faster loop.\nIf you have issues with ressuply not working, increase value.", 0, 8, 4, 1, function(res_value)
	speed_res = 1 + 0.2*res_value
	if res_value <= 3 then
		util.toast("Low resupply speed can make you miss the resupply !\nDo it at your own risk.")
	end
end)

afkMoneyCargo = menu.toggle_loop(main_menu, 'AFK Money', {""}, 'Auto ressuply and sell crates.', function()
	if menu.get_value(afkMoneyCargo) then
		local i = 0
		refill_crates()
		while i <= warehouse_capacity and menu.get_value(afkMoneyCargo) do
			sell_crates()
			i = i + 1
		end
	end
end)

menu.toggle_loop(main_menu, 'Money Estimation', {""}, 'Show estimated amount of money you will earn an hour.', function()
	estimation_value = warehouse_capacity*(3600/((warehouse_capacity*1.7+2)*speed_sell + 8*speed_res))*10000000
	estimation_value = math.floor(estimation_value+0.5)
	estimation_value = format_int(estimation_value)
	util.draw_debug_text("Money Estimation: "..estimation_value.."$")
end)

menu.divider(main_menu, "Manually")
menu.action(main_menu,'Resupply', {""}, 'Resupply special cargo crates.', function()
	refill_crates()
end)

menu.action(main_menu,'Sell crate', {""}, 'Can be useful if you want to start afk money but you have full warehouse.', function()
	sell_crates()
	sell_crates()
end)

-- Functions
function sell_crates()
	menu.trigger_commands("sellacrate")
	util.yield(1700*speed_sell)
end

function refill_crates()
	menu.trigger_commands("tptocargowarehouse")
	util.yield(3700+*speed_res)
	tp1()
	util.yield(150*speed_res)
	PAD._SET_CONTROL_NORMAL(0, 51, 1)
	util.yield(20*speed_res)
	PAD._SET_CONTROL_NORMAL(0, 51, 1)
	util.yield(20*speed_res)
	tp2()
	util.yield(150*speed_res)
	PAD._SET_CONTROL_NORMAL(0, 51, 1)
	util.yield(20*speed_res)
	PAD._SET_CONTROL_NORMAL(0, 51, 1)
	util.yield(20*speed_res)
	tp3()
	util.yield(150*speed_res)
	PAD._SET_CONTROL_NORMAL(0, 51, 1)
	util.yield(20*speed_res)
	PAD._SET_CONTROL_NORMAL(0, 51, 1)
	util.yield(20*speed_res)
	PAD._SET_CONTROL_NORMAL(0, 201, 1)
	util.yield(20*speed_res)
	PAD._SET_CONTROL_NORMAL(0, 201, 1)
	util.yield(20*speed_res)
	PAD._SET_CONTROL_NORMAL(0, 201, 1)
	util.yield(20*speed_res)
	tpexit()
	util.yield(200*speed_res)
	PAD._SET_CONTROL_NORMAL(0, 201, 1)
	util.yield(4000*speed_res)
	tpchilliad()
end

function tp1()
	TELEPORT(997.9699, -3108.72, -38.999863)
	SET_HEADING(145)
end

function tp2()
	TELEPORT(1024.3882, -3098.5376, -38.99992)
	SET_HEADING(260)
end

function tp3()
	TELEPORT(1002.05, -3093.4438, -38.999928)
	SET_HEADING(20)
end

function tpexit()
	TELEPORT(992.33, -3097.64, -38.999928)
	SET_HEADING(90)
end

function tpchilliad()
	TELEPORT(501.9981, 5605.192, 797.90985)
end

function TELEPORT(X, Y, Z)
    local Handle = PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), false) and PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false) or players.user_ped()
    ENTITY.SET_ENTITY_COORDS(Handle, X, Y, Z)
end

function SET_HEADING(Heading)
    ENTITY.SET_ENTITY_HEADING(players.user_ped(), Heading)
end

function format_int(number) -- Credits to Bart Kiers from stackoverflow
  local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
  int = int:reverse():gsub("(%d%d%d)", "%1,")
  return minus .. int:reverse():gsub("^,", "") .. fraction
end

function SET_FLOAT_GLOBAL(Global, Value)
            memory.write_float(memory.script_global(Global), Value)
        end

util.keep_running()
