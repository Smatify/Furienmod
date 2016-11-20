/*__________________________________________________________________________________________________
| Credits:
| ConnorMcLeod		- Original Idea, For his Wallhang
| Kia				- For his Source Code
| KRoTaL/JTP10181	- For his parachute
|___________________________________________________________________________________________________
| CVars:
|
| Main
| furien_ct_gravity // (default: 1)
| furien_t_gravity // (default: 0.375)
| furien_t_speed // (default: 1100)
|
| Shop
| furien_ct_defuse_costs // (default: 300)
| furien_ct_para_costs // (default: 16000)
| furien_ct_hp_costs // (default: 4000)
| furien_ct_ap_costs // (default: 3500)
| furien_ct_he_costs // (default: 2000)
| furien_ct_flash_costs // (default: 1000)
| furien_ct_smoke_costs // (default: 1000)
| furien_ct_noflash_costs // (default: 4000)
| furien_ct_superdgl_costs // (default: 16000)
| furien_ct_wallhang_costs // (default: 10000)
| furien_ct_bratz_costs // (default: 24000)
| furien_t_sknife_costs // (default: 16000)
| furien_t_dgl_costs // (default: 10000)
| furien_t_hp_costs // (default: 4000)
| furien_t_ap_costs // (default: 2000)
| furien_t_he_costs // (default: 1000)
| furien_t_flash_costs // (default: 1000)
| furien_t_smoke_costs // (default: 1000)
| furien_t_wallhang_costs // (default: 10000)
| furien_t_noflash_costs // (default: 500)
|
| Happyhour
| furien_happyhour_start // (default: 15)
| furien_happyhour_end // (default: 17)
| furien_happyhour_amount // (default: 5750)
|___________________________________________________________________________________________________
| Made by:
| Smatify - https://smatify.com
|___________________________________________________________________________________________________
| Changelog:
| Version 1.0.0
|		- First release
|_________________________________________________________________________________________________*/

#include <amxmisc>
#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <fun> 
#include <fakemeta_util>
#include <fakemeta>
#include <engine>

#define VERSION "1.0.0"

#define IsPlayer(%1)    ( 1 <= %1 <= g_iMaxPlayers ) 

new g_MaxPlayers

// Booleans
new bool:g_bAccepted[33]
new bool:has_parachute[33]
new bool:g_bHasAlready[33]

// PCVars
new g_pCTGrav
new g_pTGrav, g_pTSpeed

new para_ent[33]
new pDetach

// Models
new const models[][] =
{
	"models/w_backpack.mdl",
	"models/w_flashbang.mdl",
	"models/w_hegrenade.mdl",
	"models/w_smokegrenade.mdl"
}
new const g_szFurienModel[] 		= "models/player/furien/furien.mdl"
new const g_szAntiFurienModel[] 	= "models/player/antifurien/antifurien.mdl"

//Plugin Precache
public plugin_precache()
{
	precache_model(g_szFurienModel),
	precache_model(g_szAntiFurienModel)
	precache_model("models/parachute.mdl")
}

// Plugin Init
public plugin_init() 
{
	register_plugin			("Furienmod - Core", VERSION, "Smatify")
	register_cvar			("furien_version", VERSION, FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	g_pCTGrav = register_cvar("furien_ct_gravity", "1")
	g_pTGrav = register_cvar("furien_t_gravity", "0.375")
	g_pTSpeed = register_cvar("furien_t_speed", "640")
	
	//Registers
	RegisterHam(Ham_Spawn, "player", "settings_menu", 1)
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")
	register_event("CurWeapon", "CurWeapon_Event", "be", "1=1")
	register_forward		( FM_GetGameDescription, "GameDesc" )
	register_message		(get_user_msgid("Health"), "message_Health")
	register_event			("WeapPickup", "ev_weaponpickup", "b")
	register_forward		(FM_Touch,"fw_Touch")
	server_cmd				("mp_freezetime 0")
	register_clcmd			("say /guns", "ct_gun_menu")
	
	g_MaxPlayers 		= 	get_maxplayers()
}

// Client put in server
public client_putinserver(id)
{
	g_bAccepted[id] = false
	g_bHasAlready[id] = false
	parachute_reset(id)
}

// Client disconnect
public client_disconnect(id)
{
	g_bAccepted[id] = false
	g_bHasAlready[id] = false
	parachute_reset(id)
}
public event_new_round(id)
{
	g_bHasAlready[id] = false
	parachute_reset(id)
}

// Settings Menu
public settings_menu(id)
{
	fm_strip_user_weapons(id)
	if(g_bAccepted[id])
	{
		if(cs_get_user_team(id) == CS_TEAM_T)
		{
			set_task(0.1,"TStuff",id)
			client_print(id, print_chat, "Accepted TStuff")
		}
		else if(cs_get_user_team(id) == CS_TEAM_CT)
		{
			set_task(0.1,"CTStuff",id)
			set_task(0.2,"ct_gun_menu", id)
			client_print(id, print_chat, "Accepted CTStuff")
		}
		return PLUGIN_HANDLED
	}
	
	new menu = menu_create("\wTo play on this server we need to change your settings.^n\yDo you agree?","settings_handler")
	menu_additem(menu, "\wYes","1",0);
	menu_additem(menu, "\rNo (You can't run)","2",0);
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0);
	return PLUGIN_CONTINUE
}

// Settings Handler
public settings_handler(id, menu, item)
{	
	client_print(id, print_chat, "Settings Hanlder")
	new data[6], szName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback);
	new key = str_to_num(data);
	
	switch(key)
	{
		case 1:
		{
			g_bAccepted [id] = true
			if(is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_T)
			{
				set_task(0.1, "TStuff")
				client_print(id, print_chat, "TStuff")
			}
			else if(is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT)
			{
				CTStuff(id)
				ct_gun_menu(id)
				client_print(id, print_chat, "CTStuff")
			}
		}
		case 2:
		{
			g_bAccepted[id] = false
			settings_declined(id)
		}
	}
}
// Settings declined
public settings_declined(id)
{
	if(!g_bAccepted[id])
	{
		set_hudmessage(255, 255, 255, -0.5, 0.5, 0, 6.0, 12.0, 0.1)
		show_hudmessage(id, "You declined to change your settings. ^nThe menu will be open again at your next spawn")
		set_user_maxspeed(id, 0.0)
	}
}


// TStuff
public TStuff(id)
{
	if(g_bAccepted[id])
	{
		client_print(id, print_chat, "public TStuff")
		give_item(id, "weapon_knife")
		give_item(id, "weapon_hegrenade")
		give_item(id, "weapon_flashbang")
		give_item(id, "weapon_flashbang")
		give_item(id, "weapon_smokegrenade")
		
		set_user_gravity(id, get_pcvar_float(g_pTGrav))
		set_user_footsteps(id, 1)
		set_user_maxspeed(id, get_pcvar_float(g_pTSpeed))
		client_print(id, print_chat, "T-Speed")
		
		client_cmd(id, "cl_forwardspeed %d",get_pcvar_float(g_pTSpeed))
		client_cmd(id, "cl_sidespeed %d",get_pcvar_float(g_pTSpeed))
		client_cmd(id, "cl_backspeed %d",get_pcvar_float(g_pTSpeed))
		client_print(id, print_chat, "T-Client-Speed")
		
		client_cmd(id, "cl_minmodels 0")
		cs_set_user_model(id, "furien")
	}
	
}

// CTStuff
public CTStuff(id)
{
	if(g_bAccepted[id])
	{
		client_print(id, print_chat, "public CTStuff")
		set_user_gravity(id, get_pcvar_float(g_pCTGrav))
		set_user_footsteps(id, 0)
		set_user_maxspeed(id, 320.0)
		
		client_cmd(id, "cl_minmodels 0")
		cs_set_user_model(id, "antifurien")
	}
}

// CT-Gunmenu
public ct_gun_menu(id)
{
	if(cs_get_user_team(id) == CS_TEAM_T || g_bHasAlready[id] || !is_user_alive(id))
	{
		client_print(id, print_chat, "CTGunMenu abgelehnt")
		return PLUGIN_HANDLED
	}
	client_print(id, print_chat, "CTGunMenu")
	new menu = menu_create("Which weapon do you want?", "ct_gun_menu_handler")
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
public ct_gun_menu_handler(id, menu, item) 
{ 
    switch(item) 
    { 
        case 0: 
        { 
            give_item(id, "weapon_ak47")       
            cs_set_user_bpammo(id, CSW_AK47, 200) 
        } 
        case 1: 
        { 
            give_item(id, "weapon_m4a1") 
            cs_set_user_bpammo(id, CSW_M4A1, 200) 
        } 
        case 2: 
        { 
            give_item(id, "weapon_famas") 
            cs_set_user_bpammo(id, CSW_FAMAS, 200) 
        } 
        case 3: 
        { 
            give_item(id, "weapon_mp5navy") 
            cs_set_user_bpammo(id, CSW_MP5NAVY, 200) 
        } 
        case 4: 
        { 
            give_item(id, "weapon_p90") 
            cs_set_user_bpammo(id, CSW_P90, 200) 
        } 
        case 5: 
        { 
            give_item(id, "weapon_m3")  
            cs_set_user_bpammo(id, CSW_M3, 200) 
        } 
        case 6:
        { 
            give_item(id, "weapon_xm1014") 
            cs_set_user_bpammo(id, CSW_XM1014, 200) 
        } 
        case MENU_EXIT:
        {
            menu_destroy(menu)
            return PLUGIN_HANDLED
        }
    } 
    give_item(id, "weapon_knife")  
    give_item(id, "weapon_deagle") 
    give_item(id, "weapon_smokegrenade")     
    cs_set_user_bpammo(id, CSW_DEAGLE, 200)         
    g_bHasAlready[id] = true 
    return PLUGIN_HANDLED 
} 

// CurWeapon
public CurWeapon_Event(id)
{
	if(is_user_alive(id) && g_bAccepted[id])
	{
		if(cs_get_user_team(id) == CS_TEAM_T)
		{
			set_user_gravity(id, get_pcvar_float(g_pTGrav))
			set_user_footsteps(id, 1)
			set_user_maxspeed(id, get_pcvar_float(g_pTSpeed))
			client_print(id, print_chat, "CurWeapon T")
		}
		else if(cs_get_user_team(id) == CS_TEAM_CT)
		{
			set_user_gravity(id, get_pcvar_float(g_pCTGrav))
			set_user_footsteps(id, 0)
			set_user_maxspeed(id, 200.0)
			client_print(id, print_chat, "CurWeapon CT")
		}
		
	}
	else if(is_user_alive(id) && !g_bAccepted[id])
	{
		set_user_maxspeed(id, 0.0)
	}
	return PLUGIN_HANDLED
}


// Game description
public GameDesc( )
{ 
	forward_return( FMV_STRING, "Furienmod v%s by Smatify", VERSION); 
	return FMRES_SUPERCEDE; 
}

// Weapon pickup
public ev_weaponpickup(id, weapon)
{
	if(cs_get_user_team(id) == CS_TEAM_T)
	{
		if(get_user_weapon(id) == CSW_C4)
		{
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

// Message Health
public message_Health(msgid, dest, id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
	
	static hp;
	hp = get_msg_arg_int(1);
	
	if(hp > 255 && (hp % 256) == 0)
		set_msg_arg_int(1, ARG_BYTE, ++hp);
	
	return PLUGIN_CONTINUE;
}

// fw_Touch
public fw_Touch( ent , id )
{
	if (!(1 <= id <= g_MaxPlayers) || get_user_team(id) == 2 || !pev_valid(ent) || !(pev(ent , pev_flags) & FL_ONGROUND))
		return FMRES_IGNORED;
	
	static szEntModel[32];
	pev(ent , pev_model , szEntModel , 31);
	
	return equal(szEntModel , models[random(sizeof(models))]) ? FMRES_IGNORED : FMRES_SUPERCEDE;
}

// Parachute
parachute_reset(id)
{
	if(para_ent[id] > 0) {
		if (is_valid_ent(para_ent[id])) {
			remove_entity(para_ent[id])
		}
	}

	if (is_user_alive(id) && cs_get_user_team(id))
	{
		switch(id)
		{
			case CS_TEAM_CT : set_user_gravity(id, get_pcvar_float(g_pCTGrav))
			case CS_TEAM_T : set_user_gravity(id, get_pcvar_float(g_pTGrav))
		}
	}

	has_parachute[id] = false
	para_ent[id] = 0
}
public client_PreThink(id)
{
	if (!is_user_alive(id) || !has_parachute[id]) return

	new Float:fallspeed = 100 * -1.0
	new Float:frame

	new button = get_user_button(id)
	new oldbutton = get_user_oldbutton(id)
	new flags = get_entity_flags(id)

	if (para_ent[id] > 0 && (flags & FL_ONGROUND)) {

		if (get_pcvar_num(pDetach)) {

			if (get_user_gravity(id) == 0.1 && cs_get_user_team(id))
			{
				switch(id)
				{
					case CS_TEAM_CT : set_user_gravity(id, get_pcvar_float(g_pCTGrav))
					case CS_TEAM_T : set_user_gravity(id, get_pcvar_float(g_pTGrav))
				}
			}

			if (entity_get_int(para_ent[id],EV_INT_sequence) != 2) 
			{
				entity_set_int(para_ent[id], EV_INT_sequence, 2)
				entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
				entity_set_float(para_ent[id], EV_FL_frame, 0.0)
				entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
				entity_set_float(para_ent[id], EV_FL_animtime, 0.0)
				entity_set_float(para_ent[id], EV_FL_framerate, 0.0)
				return
			}

			frame = entity_get_float(para_ent[id],EV_FL_fuser1) + 2.0
			entity_set_float(para_ent[id],EV_FL_fuser1,frame)
			entity_set_float(para_ent[id],EV_FL_frame,frame)

			if (frame > 254.0) {
				remove_entity(para_ent[id])
				para_ent[id] = 0
			}
		}
		else 
		{
			remove_entity(para_ent[id])
			if (is_user_alive(id) && cs_get_user_team(id))
			{
				switch(id)
				{
					case CS_TEAM_CT : set_user_gravity(id, get_pcvar_float(g_pCTGrav))
					case CS_TEAM_T : set_user_gravity(id, get_pcvar_float(g_pTGrav))
				}
			}
			para_ent[id] = 0
		}

		return
	}

	if (button & IN_USE) {

		new Float:velocity[3]
		entity_get_vector(id, EV_VEC_velocity, velocity)

		if (velocity[2] < 0.0) {

			if(para_ent[id] <= 0) {
				para_ent[id] = create_entity("info_target")
				if(para_ent[id] > 0) {
					entity_set_string(para_ent[id],EV_SZ_classname,"parachute")
					entity_set_edict(para_ent[id], EV_ENT_aiment, id)
					entity_set_edict(para_ent[id], EV_ENT_owner, id)
					entity_set_int(para_ent[id], EV_INT_movetype, MOVETYPE_FOLLOW)
					entity_set_model(para_ent[id], "models/parachute.mdl")
					entity_set_int(para_ent[id], EV_INT_sequence, 0)
					entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
					entity_set_float(para_ent[id], EV_FL_frame, 0.0)
					entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
				}
			}

			if (para_ent[id] > 0) {

				entity_set_int(id, EV_INT_sequence, 3)
				entity_set_int(id, EV_INT_gaitsequence, 1)
				entity_set_float(id, EV_FL_frame, 1.0)
				entity_set_float(id, EV_FL_framerate, 1.0)
				set_user_gravity(id, 0.1)

				velocity[2] = (velocity[2] + 40.0 < fallspeed) ? velocity[2] + 40.0 : fallspeed
				entity_set_vector(id, EV_VEC_velocity, velocity)

				if (entity_get_int(para_ent[id],EV_INT_sequence) == 0) {

					frame = entity_get_float(para_ent[id],EV_FL_fuser1) + 1.0
					entity_set_float(para_ent[id],EV_FL_fuser1,frame)
					entity_set_float(para_ent[id],EV_FL_frame,frame)

					if (frame > 100.0) {
						entity_set_float(para_ent[id], EV_FL_animtime, 0.0)
						entity_set_float(para_ent[id], EV_FL_framerate, 0.4)
						entity_set_int(para_ent[id], EV_INT_sequence, 1)
						entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
						entity_set_float(para_ent[id], EV_FL_frame, 0.0)
						entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
					}
				}
			}
		}
		else if (para_ent[id] > 0) {
			remove_entity(para_ent[id])
			if (is_user_alive(id) && cs_get_user_team(id))
			{
				switch(id)
				{
					case CS_TEAM_CT : set_user_gravity(id, get_pcvar_float(g_pCTGrav))
					case CS_TEAM_T : set_user_gravity(id, get_pcvar_float(g_pTGrav))
				}
			}
			para_ent[id] = 0
		}
	}
	else if ((oldbutton & IN_USE) && para_ent[id] > 0 ) {
		remove_entity(para_ent[id])
		if (is_user_alive(id) && cs_get_user_team(id))
		{
			switch(id)
			{
				case CS_TEAM_CT : set_user_gravity(id, get_pcvar_float(g_pCTGrav))
				case CS_TEAM_T : set_user_gravity(id, get_pcvar_float(g_pTGrav))
			}
		}
		para_ent[id] = 0
	}
}

// Colorchat
public print_color(id, cid, color, const message[], any:...)
{
	new msg[192]
	vformat(msg, charsmax(msg), message, 5)
	new param
	if (!cid) 
		return
	else 
		param = cid
	
	new team[32]
	get_user_team(param, team, 31)
	switch (color)
	{
		case 0: msg_teaminfo(param, team)
		case 1: msg_teaminfo(param, "TERRORIST")
		case 2: msg_teaminfo(param, "CT")
		case 3: msg_teaminfo(param, "SPECTATOR")
	}
	if (id) msg_saytext(id, param, msg)
	else msg_saytext(0, param, msg)
		
	if (color != 0) msg_teaminfo(param, team)
}

msg_saytext(id, cid, msg[])
{
	message_begin(id?MSG_ONE:MSG_ALL, get_user_msgid("SayText"), {0,0,0}, id)
	write_byte(cid)
	write_string(msg)
	message_end()
}

msg_teaminfo(id, team[])
{
	message_begin(MSG_ONE, get_user_msgid("TeamInfo"), {0,0,0}, id)
	write_byte(id)
	write_string(team)
	message_end()
}