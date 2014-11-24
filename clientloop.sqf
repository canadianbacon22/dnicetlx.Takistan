#include "Awesome\Functions\macro.h"
#define BORDER_INCOME 20000
if (not(isNil "client_loop_functions_defined")) exitWith {};
sleep 6;
liafu = true;
//playerIsHacker = false;
//voiceOnGlobal = false;

player_is_armed = false;

check_armed_player = {
	private["_player"];
	_player = _this select 0;

	if ((primaryWeapon _player) != "") exitWith {true};
	if ((secondaryWeapon _player) != "") exitWith {true};
	
	//check if player is gunner
	private["_vehicle", "_in_vehicle", "_is_commander", "_is_driver", "_is_gunner"];
	_vehicle = (vehicle _player);
	_is_driver = (driver(_vehicle) == _player);
	_in_vehicle = (_vehicle != _player);
	_is_commander = (commander(_vehicle) == _player) && not(_is_driver);
	_is_gunner = (gunner(_vehicle) == _player);
	if (_in_vehicle && (_is_gunner || _is_commander))  exitWith { true };
	
	//Check if player has a suicide vest or similar bomb
	private["_armed_items"];
	//Remote bomb, timed bomb, activated bomb (ied), speed bomb, suicide vest, lighter
	_armed_items = ["fernzuenderbombe", "zeitzuenderbombe", "aktivierungsbombe", "geschwindigkeitsbombe", "selbstmordbombe", "lighter"];
	if([_player, _armed_items] call INV_HasItem) exitWith { true };
	
	//check if player has pistol
	private["_weapon"];
	_weapon = (currentWeapon _player);
	if ([_weapon, "GrenadeLauncher"] call shop_weapon_inherits_from) exitWith { true }; //Throw (Grenades), Put (IEDs)
	if ([_weapon, "PistolCore"] call shop_weapon_inherits_from) exitWith { true };
	if (call holster_pistol_in_inventory) exitWith { true };
	false;
};

check_armed_mounted = {
	private["_vehicle"];
	
	_vehicle = _this select 0;
	
	//check if the vehicle has a mounted player with a weapon
	private["_occupants"];
	_occupants = [_vehicle] call mounted_get_occupants;
	//player groupChat format["_occupants = %1", _occupants];
	private["_armed_occupant"];
	_armed_occupant = nil;
	
	{
		private["_occupant"];
		_occupant = _x;
		if (([_occupant] call check_armed_player)) exitWith {
			_armed_occupant = _occupant;
		};
	} forEach _occupants;
	
	not(isNil "_armed_occupant")
};


check_armed_vehicle = {
	private["_in_vehicle", "_horns",  "_player", "_vehicle"];
	
	_player = _this select 0;
	_vehicle = (vehicle player);
	
	_in_vehicle = (_vehicle != _player);
	
	if (not(_in_vehicle)) then {
		_vehicle = [_player] call mounted_player_get_vehicle;
	};
	if (isNil "_vehicle") exitWith {false};
	//check if the vehicle has a weapon
	private["_weapon"];
	_weapon = currentWeapon _vehicle;
	if ([(currentWeapon _vehicle), "CarHorn"] call shop_weapon_inherits_from) exitWith { false };
	
	([_vehicle] call check_armed_mounted)
};

check_armed_stunning = {
	private["_player"];
	_player = _this select 0;
	
	if (isNil "was_stunning_count") then { was_stunning_count = 0; };
	if (isNil "stunning" ) then { stunning = false;};
	if (isNil "was_stunning") then { was_stunning = false;};
	
	private["_delay"];
	_delay = 30;
	//Delayed check for player stunning within the last X seconds
	if (stunning) then 	{ 
		was_stunning = true; 
		was_stunning_count = 0;
	}
	else { if ( !stunning && was_stunning) then {
		if (was_stunning_count < _delay) then { was_stunning_count = was_stunning_count + 1;};
		if (was_stunning_count >= _delay) then { was_stunning = false; was_stunning_count = 0;};
	};};
	
	//player groupChat format["STUNNING: %1, WAS STUNNING: %2", stunning, was_stunning];
	was_stunning
};

check_armed = {
	private["_player"];
	_player = _this select 0;
	
	if (isNil "_player") exitWith { false };
	if (not(alive _player)) exitWith {false};
	
	private["_armed_vehicle", "_armed_player"];
	_armed_vehicle = ([_player] call check_armed_vehicle);
	_armed_player =  ([_player] call check_armed_player);
	_was_stunning = ([_player] call check_armed_stunning);
	
	//player groupChat format["_armed_vehicle = %1, _armed_player = %2, _was_stunning = %3", _armed_vehicle, _armed_player, _was_stunning];
	
	private["_armed"];
	_armed = _armed_vehicle || _armed_player || _was_stunning;
	[_player, _armed] call player_update_armed;
	_player setVariable ["armed", _armed];
	_armed
};



compare_array = {
	private["_a", "_b"];
	_a = _this select 0;
	_b = _this select 1;
	if (isNil "_a") exitWith { false };
	if (isNil "_b") exitWith { false };
	if (typeName _a != "ARRAY") exitWith {false};
	if (typeName _b != "ARRAY") exitWith {false};
	if (count _a != count _b) exitWith {false};
	
	private["_i"];
	_i = (count _a) - 1;
	while {_i >= 0} do {
		if (str(_a select _i) != str(_b select _i)) exitWith { false };
		_i = _i - 1;
	};
	
	(_i == -1)
};


check_mobile = {
	private["_player"];
	_player = player;
	if (([_player, "handy"] call INV_GetItemAmount) == 1) exitWith {};	
	[_player, "handy", 1] call INV_SetItemAmount;
	[_player, "mobile", true] call player_set_bool;
};

check_keychain = {
	private["_player"];
	_player = player;
	if (([_player, "keychain"] call INV_GetItemAmount) == 1) exitWith {};	
	[_player, "keychain", 1] call INV_SetItemAmount;
};


check_treefixer = {
	private["_player"];
	_player = player;
	if (([_player, "treefixer"] call INV_GetItemAmount) == 1) exitWith {};	
	[_player, "treefixer", 1] call INV_SetItemAmount;
};

check_inventory = {
	if (not(alive player)) exitWith {};
	
	private["_player"];
	_player = player;
	
	call check_mobile;
	call check_keychain;
	call check_treefixer;
};

cop_stun_gun_modify = {
	if (!(iscop or isopf)) exitWith {};
	//if (isNil "weaponsloaded") exitWith {};
	//if (not(weaponsloaded)) exitWith {};
	if((player ammo (currentWeapon player)) <= stunshotsmax) exitWith {};
	if (not(alive player)) exitWith {};
	if ((((currentWeapon player) == "M9" || (currentWeapon player) == "M9SD")) && ((currentMagazine player) == ("15Rnd_9x19_M9SD"))) then {	
		_magazines = magazines player;
		_magazines_count = {_x == "15Rnd_9x19_M9SD"} count (_magazines);
		_ammo = player ammo (currentWeapon player);
		//player globalChat format ["1%", _ammo];		
		if (_ammo > stunshotsmax) then {
			{
				if (_x == "15Rnd_9x19_M9SD") then {
					player removeMagazine _x;
				};
			} forEach _magazines;
						
			for [{_c=0}, {_c < (_magazines_count)}, {_c=_c+1}] do {
				player addMagazine ["15Rnd_9x19_M9SD", stunshotsmax];
			};
		};
	};	
};

check_money = {
	private ["_player", "_money"];
	_player = player;
	
	_money = [player, 'money'] call INV_GetItemAmount;
	if (_money < 0) then {
		[_player, 'money', 0] call INV_SetItemAmount; 
		_money = 0;
	};
		
	if (_money > money_limit) then {
		[_player, 'money', money_limit] call INV_SetItemAmount; 
		player groupChat format["You can't carry more than $%1 in your inventory. Money was removed.", strM(money_limit)];
	}; 
};

check_bank = {
	private ["_bank_account", "_player"];
	_player = player;
	_bank_account = [_player] call get_bank_valuez;
	
	if (_bank_account > bank_limit) exitWith {
		[_player, bank_limit] call set_bank_valuez; 
		player groupChat format["You can't have more than $%1 in your bank account. Money has been removed.", strM(bank_limit)];
	};
};

check_actions = {
	private["_vehicle"];
	_vehicle = (vehicle player);
	_in_vehicle = (_vehicle != player);
	if (not(_in_vehicle)) exitWith {};
		
	if ((typeOf _vehicle == "ArmoredSUV_PMC")) then {
		[_vehicle] call armored_suv_add_actions;
	};
	
	if (_vehicle isKindOf "Air") then {
		[_vehicle] call halo_jump_add_actions;
	};
};


check_factory_actions = {
	if (iscop or isopf) exitwith{};
	private["_player"];
	_player = player;
	private["_vehicle", "_in_vehicle"];
	_vehicle = (vehicle _player);
	_in_vehicle = (_vehicle != _player);
	
	private["_factory"];
	waitUntil {!isNil "factory_player_near"};
	_factory = [_player, 5] call factory_player_near;
	if (isNil "_factory" || not(INV_shortcuts) || _in_vehicle || not(alive _player)) exitWith {
		waitUntil {!isNil "factory_remove_actions"};
		[_player] call factory_remove_actions;
	};
	
	private["_factory_id"];
	_factory_id = _factory select factory_id;
	
	[_player, _factory_id] call factory_add_actions;
};

check_workplaces = {
	{
		private["_workplace", "_object", "_radius"];
		_workplace = _x;
		_object = _workplace select workplace_object;
		_radius = _workplace select workplace_radius;
		if ((player distance _object) < _radius) then {
			timeinworkplace = timeinworkplace + 1;
		};
	} forEach workplacearray;
};

border_checkpoints = ["checkpoint_alpha", "checkpoint_bravo", "checkpoint_delta"];
border_time = 0;
check_checkpoints = {
	{
		private["_checkpoint"];
		_checkpoint = getMarkerPos _x;

		if ((player distance _checkpoint) < 70) then {
			border_time = border_time + 1;
		};
	} count border_checkpoints;
	if (border_time >= 120) then {
		border_time = 0;
		[player, BORDER_INCOME] call transaction_bank;
		player groupchat format["You've received $%1 for manning a border checkpoint", strM(BORDER_INCOME)];
	};
};



check_camera = {
	if (isnil "admin_camera_on") then {	admin_camera_on = false; };
};

bases_check_faction_bool = 0;
bases_check_trigger_area = 1;
bases_check_teleport_height = 2;
bases_check_teleport_marker = 3;
bases_check_teleport_message = 4;

bases_checks = [
	["isins", "ins_area_1", 20, "telehesnotins", "You were teleported out of the Insurgent base!"],
	["ispmc", "pmc_area_1", 20, "telehesnotpmc", "You were teleported out of the PMC base!"],
	["isopf", "opfor_area_1", 20, "telehesnottla", "You were teleported out of the TLA base!"],
	["iscop", "blufor_area_1", 20, "telehesnotcop", "You were teleported out of the Police base!"]	
];
if(!isciv) then {
	(bases_checks select 3) set [1, "blufor_area_2"];
};
check_bases = {
	private["_vehicle"];
	_vehicle = vehicle player;
	if (admin_camera_on) exitWith {};
	
	{
		private["_base_check", "_faction_bool", "_trigger_area", "_teleport_height", "_teleport_marker", "_teleport_message"];
		_base_check = _x;
		
		_faction_bool =  missionNamespace getVariable (_base_check select bases_check_faction_bool);
		_trigger_area = missionNamespace getVariable (_base_check select bases_check_trigger_area);
		_teleport_height = _base_check select bases_check_teleport_height;
		_teleport_marker = _base_check select bases_check_teleport_marker;
		_teleport_message = _base_check select bases_check_teleport_message;
		
		private["_altitude"];
		_altitude = (getPosATL _vehicle) select 2;
		
		if (_vehicle in (list _trigger_area) && (_altitude < _teleport_height) && not(_faction_bool)) exitWith {
			_vehicle setVelocity [0,0,0];
			_vehicle setPos (getMarkerPos _teleport_marker);
			player groupChat _teleport_message;
		};
	} forEach bases_checks;
};


check_static_weapons = {
	private["_vehicle","_isStatic"];
	_vehicle = (vehicle player);
	_isStatic = (_vehicle isKindOf "StaticWeapon");
	if (not(_isStatic)) exitWith {};
	
	_vehicle lock false;
};



check_smoke_grenade = {
	private["_flashed"];
	_flashed = player getVariable "flashed";
	
	if (isNil "_flashed") exitWith {};
	if (typeName _flashed != "BOOL") exitWith {};
	if (not(_flashed)) exitWith {};
	
	private ["_mask", "_fadeInTime", "_fadeOutTime"];
	
	_mask = player getvariable "gasmask";
	_mask = if (isNil "_mask") then { false } else { _mask };
	_mask = if (typeName "_mask" != "BOOL") then { false } else { _mask };
	
	player setVariable ["gasmask", _mask, true];
	if (_mask) exitWith {};
	
	
	[] spawn {
		private ["_fadeInTime", "_fadeOutTime"];
		_fadeInTime   = 1;
		_fadeOutTime  = 5;
		if (not(alive player)) exitWith {};
		titleCut ["","WHITE OUT",0];
		sleep _fadeOutTime;
		titleCut ["","WHITE IN",0];
		sleep _fadeInTime;
		player setVariable ["flashed", false, true];
	};
		
};

iactionarr = [];

check_droppable_items = {
	private["_objects"];

	_objects = nearestobjects [getpos player, droppableitems, 5];
	
	{
		private ["_exit", "_i", "_array", "_object"];
		_exit = false;
		_object = _x;
		
		for "_i" from 0 to (count iactionarr) do {
			_array = iactionarr select _i;
			if(!isNil "_array") then {
			if(_object in _array) exitWith{ 
				_exit = true;
			};
			};
		};

		if(_exit) exitWith {};
		
		private["_near_players", "_near_players_count"];
		_near_players = [_object, 3] call players_object_near;
		_near_players_count = (count _near_players);
		//player groupChat format["_near_players = %1", _near_players];
		
		if (((_object distance player) < 3) && (_near_players_count < 2)) then {
			private["_amount", "_item", "_infos", "_name", "_action"];
			_array	= _object getvariable "droparray";
			if(isNil "_array") exitWith {};
			
			_amount	= [_array select 0] call decode_number;
			_item 	= _array select 1;
			_infos	= _item call INV_GetItemArray;
			_name	= _infos call INV_GetItemName;
			
			_action = player addaction [format["Pickup %1 (%2)", _name, _amount], "pickup.sqf", [_object, _item, ([_amount] call encode_number)]];
			iactionarr = iactionarr + [[_object, _action]];
		};	
	} foreach _objects;

	for [{_i=0}, {_i < (count iactionarr)}, {_i=_i+1}] do {
		private["_object", "_action", "_variable"];
		_array	= iactionarr select _i;
		_object    = _array select 0;
		_action = _array select 1;
		_variable	= _object getvariable "droparray";

		private["_near_players", "_near_players_count"];
		_near_players = [_object, 3] call players_object_near;
		_near_players_count = (count _near_players);
		if(isnull _object or _object distance player > 2 or (isnil "_variable") || _near_players_count > 1) then {	
			player removeAction _action;
			iactionarr set [_i, 0];
			iactionarr = iactionarr - [0];
		};
	};
};

check_restrains = {
	if (iscop or isopf) exitWith {};
	if (not(alive player)) exitWith {};
	
	private["_physicallyRestrained", "_logicallyRestrained"];
	_physicallyRestrained = ((animationState player) ==  "civillying01");
	_logicallyRestrained = [player, "restrained"] call player_get_bool;
	
    if (([_player, "restrained"] call player_get_bool) or ([_player, "isstunned"] call player_get_bool)) exitWith {
        if(vehicle player != player) then {
            player action ["Eject", vehicle _unit];
            hint "You are restained! Entering a vehicle is rule breaking."; // Quick Fix, todo figure out how to stop player from entering.
        };
    };
    
	if (_logicallyRestrained && not(_physicallyRestrained)) then {
		format['%1 switchMove "civillying01";', player] call broadcast;
	}
	else { if (not(_logicallyRestrained) && _physicallyRestrained) then {
		format['%1 switchMove "amovppnemstpsnonwnondnon";', player] call broadcast;
		[player, "isstunned", false] call player_set_bool;
		StunActiveTime=0;
	}
	else { if (_logicallyRestrained && _physicallyRestrained) then {
		if (not([player, 50] call player_near_cops) && not([player, 50] call player_near_opf)) then {
			[player, "restrained", false] call player_set_bool;
			player groupChat format["You have managed to unrestrain yourself!"];
		};
	};};};
};




check_respawn_time = {
	if (not(alive player)) exitWith {};
	private["_interval"];
	_interval = 30;
	if (not((time % _interval) == 0)) exitWith {};
	[player, "extradeadtime", -(_interval)] call player_update_scalar;
	
};

jail_player_punish = {
	private["_player", "_time"];
	_player = _this select 0;
	_time = _this select 1;
	format['server globalChat"%1 was sent to jail for %2 minutes for using Donator weapons without Donator credentials";', name _player, _time] call broadcast;
	format['[%1, %2] call player_prison_time;', _player, _time] call broadcast;
	format['[%1, 100] call player_prison_bail;', _player] call broadcast;
	format['[%1] call player_prison_convict;', _player] call broadcast;
};


check_donator_items = {
	private["_pWeps", "_donWepArray", "_vipWepArray"]; 
_vipWepArray = ["AKS_74_GOSHAWK", "BAF_L85A2_RIS_CWS", "FN_FAL_ANPVS4", "m107", "m8_tws", "m8_tws_sd", "MetisLauncher", "STRELA", "Javelin"];
_donWepArray = ["Pecheneg","MG36","MG36_camo","ksvk","SVD_NSPU_EP1", "M110_NVG_EP1", "BAF_AS50_scoped", "AKS_74_NSPU","bizon_silenced", "Igla", "Stinger"];
	
	
	_pWeps = currentWeapon player;
	if(!isvip) then {
		if(["_TWS", _pWeps] call KK_fnc_inString) then {
			[player, 10] call jail_player_punish;
		}
		else{
			{
				if(_x == _pWeps) then {
					[player, 10] call jail_player_punish;
				};
			} forEach _vipWepArray;
		};
	};
	if(!ispmc) then {
		{
			
			if(_x == _pWeps) then {
				[player, 5] call jail_player_punish;
			};
		} forEach _donWepArray;
	};
};

player_onGlobal = compile preprocessFile "addons\player_onGlobal.sqf";

check_global_voice = {
	player spawn player_onGlobal;
};

group_counter = {
	hint format ["Total number of groups = %1", (count allGroups)];
};


client_loop = {
	private ["_client_loop_i"];
	_client_loop_i = 0; 

	while {_client_loop_i < 5000} do {
	//player globalChat 'running';
		[player] call check_armed;
		call check_money;
		call check_bank;
		call check_actions;
		call check_factory_actions;
		call check_inventory;
		call cop_stun_gun_modify;
		call check_workplaces;
		//call check_logics;
		call check_camera;
		call check_bases;
		call check_static_weapons;
		call check_respawn_time;
		call check_smoke_grenade;
		call check_droppable_items;
		call check_restrains;
		call check_global_voice;
		call check_donator_items;
		if(!isciv) then {
			call check_checkpoints;
		};
		sleep 0.5;
		/*if(isNil "playerIsHacker" && isNil "voiceOnGlobal") then { 
			disableUserInput false;
		};	*/
		_client_loop_i = _client_loop_i + 1;
	};
	[] spawn client_loop;
};
//player globalChat "CLIENTLOOP LOADED";
[] spawn client_loop;
//player globalChat "CLIENTLOOP running";
client_loop_functions_defined = true;