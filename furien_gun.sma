#include <amxmisc>
#include <amxmodx>
#include <hamsandwich>
#include <cstrike>
#include <fun> 
#include <fakemeta>

#define PLUGIN "Furienmod - CT-Guns"
#define VERSION "1.0.0b"
#define AUTHOR "Smatify"

new bool:havealready[33] // Bool das er bereits eine Waffe aus dem Menu hatt

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("furien_guns", VERSION, FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	
	register_clcmd("say /guns", "gunno"); // Command falls man Menu wegdrückt
	
	RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1); // Wenn Runde startet, Menu öffnen
}

public Event_Round_Start(id)
{
	havealready[id] = false
}	

public fwHamPlayerSpawnPost(id) 
{
	havealready[id] = false
	gunno(id);
}


public gunno(id)
{	
	new team = get_user_team(id)
	if(!is_user_connected(id) || team == 1 || havealready[id] || !is_user_alive(id))
	{
		return PLUGIN_HANDLED;
	}
	
	
	new menu = menu_create("Which weapon do you want?", "gunshop_handler")
	menu_additem(menu, "AK47 + Deagle", "1", 0);
	menu_additem(menu, "M4A1 + Deagle", "2", 0);
	menu_additem(menu, "Famas + Deagle", "3", 0);
	menu_additem(menu, "MP5 + Deagle", "4", 0);
	menu_additem(menu, "P90 + Deagle", "5", 0);
	menu_additem(menu, "M3 + Deagle", "6", 0);
	menu_additem(menu, "XM1014 + Deagle", "7", 0);
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0)
	
	return PLUGIN_HANDLED
	
}

public gunshop_handler(id, menu, item)
{
	new team = get_user_team(id)
	
	if(!is_user_connected(id) || team == 1 || havealready[id] || !is_user_alive(id) || item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new data[6], szName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback);
	
	new key = str_to_num(data)
	
	switch(key)
	{
		case 1:
		{
			give_item(id, "weapon_ak47")
			give_item(id, "weapon_deagle")
			
			cs_set_user_bpammo(id, CSW_AK47, 200)
			cs_set_user_bpammo(id, CSW_DEAGLE, 200)
			havealready[id] = true
			
		}
		case 2:
		{
			give_item(id, "weapon_m4a1")
			give_item(id, "weapon_deagle")
			
			cs_set_user_bpammo(id, CSW_M4A1, 200)
			cs_set_user_bpammo(id, CSW_DEAGLE, 200)
			havealready[id] = true
			
		}
		case 3:
		{
			give_item(id, "weapon_famas")
			give_item(id, "weapon_deagle")
			
			cs_set_user_bpammo(id, CSW_FAMAS, 200)
			cs_set_user_bpammo(id, CSW_DEAGLE, 200)
			havealready[id] = true
			
		}
		case 4:
		{
			give_item(id, "weapon_mp5navy")
			give_item(id, "weapon_deagle")
			
			cs_set_user_bpammo(id, CSW_MP5NAVY, 200)
			cs_set_user_bpammo(id, CSW_DEAGLE, 200)
			havealready[id] = true
			
		}
		case 5:
		{
			give_item(id, "weapon_p90")
			give_item(id, "weapon_deagle")
			
			cs_set_user_bpammo(id, CSW_P90, 200)
			cs_set_user_bpammo(id, CSW_DEAGLE, 200)
			havealready[id] = true
		}
		case 6:
		{
			give_item(id, "weapon_m3")
			give_item(id, "weapon_deagle")
			
			cs_set_user_bpammo(id, CSW_M3, 200)
			cs_set_user_bpammo(id, CSW_DEAGLE, 200)
			havealready[id] = true
		}
		case 7:
		{
			give_item(id, "weapon_xm1014")
			give_item(id, "weapon_deagle")
			
			cs_set_user_bpammo(id, CSW_XM1014, 200)
			cs_set_user_bpammo(id, CSW_DEAGLE, 200)
			havealready[id] = true
		}
	}
	return PLUGIN_HANDLED
}

public client_disconnect(id)
{
	havealready[id] = false
}

