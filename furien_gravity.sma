#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>

#define PLUGIN "Furienmod - Gravity"
#define VERSION "1.0.0b"
#define AUTHOR "Smatify"

new bool:g_enabled[33]
new cvar_grav

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_cvar("furien_gravity", VERSION, FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	
	register_clcmd("say /gravity", "grav_toggle")
	register_clcmd("say_team /gravity", "grav_toggle")
	register_clcmd("say gravity", "grav_toggle")
	register_clcmd("say_team gravity", "grav_toggle")
	register_clcmd("gravity","grav_toggle")
	
	cvar_grav = register_cvar("furien_t_gravity", "0.375")
	
	register_event("CurWeapon", "event_CurWeapon", "be", "1=1")
}

public client_disconnect(id)
{
	g_enabled[id] = false
}

public grav_toggle(id)
{
	if (cs_get_user_team(id) == CS_TEAM_T) 
	{ 
		if(!g_enabled[id])
		{
			g_enabled[id] = true
			set_hudmessage(0, 255, 0, -1.0, 0.22, 0, 6.0, 3.0)
			show_hudmessage(id, "You have now normal gravity!")
			set_user_gravity(id, 1.0)
		}
		
		else if (g_enabled[id])
		{
			g_enabled[id] = false
			set_hudmessage(0, 255, 0, -1.0, 0.22, 0, 6.0, 3.0)
			show_hudmessage(id, "You have now LOW-Gravity!")
			set_user_gravity(id, 0.375)
		}
	}
	else if(cs_get_user_team(id) == CS_TEAM_CT)
	{
		if(!g_enabled[id])
		{
			g_enabled[id] = true
			set_hudmessage(0, 255, 0, -1.0, 0.22, 0, 6.0, 3.0)
			show_hudmessage(id, "You cannot set your gravity as CT!")
		}
		else if (g_enabled[id])
		{
			g_enabled[id] = false
			set_hudmessage(0, 255, 0, -1.0, 0.22, 0, 6.0, 3.0)
			show_hudmessage(id, "You cannot set your gravity as CT!")
		}
	}
		
		
}

public event_CurWeapon(id)
{
	if (cs_get_user_team(id) == CS_TEAM_T) 
	{ 
		if(!g_enabled[id])
		{
			set_user_gravity(id, get_pcvar_float(cvar_grav))
		}
		
		else if(g_enabled[id])
		{
			set_user_gravity(id, 1.0)
		}
	}
}
