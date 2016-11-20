#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fun>

#define FREQ 0.1

#define PLUGIN "Furienmod - Invisibility"
#define VERSION "1.0.0b"
#define AUTHOR "Smatify"

new TaskEnt, maxplayers

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_cvar("furien_invisibility", VERSION, FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	
	register_forward(FM_Think, "Think")
	
	TaskEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))	
	set_pev(TaskEnt, pev_classname, "speedometer_think")
	set_pev(TaskEnt, pev_nextthink, get_gametime() + 1.01)
	
	maxplayers = get_maxplayers()
}

public Think(ent)
{
	if(ent == TaskEnt) 
	{
		SpeedTask()
		set_pev(ent, pev_nextthink,  get_gametime() + FREQ)
	}
}

SpeedTask()
{
	static i, target
	static Float:velocity[3]
	static Float:speed

	for(i=1; i<=maxplayers; i++)
	{
		if(!is_user_connected(i)) continue
	
		target = pev(i, pev_iuser1) == 4 ? pev(i, pev_iuser2) : i
		pev(target, pev_velocity, velocity)
	
		speed = vector_length(velocity)
		if(speed < 5 && get_user_weapon(i) == CSW_KNIFE && get_user_team(i) == 1)
		 {
		 	set_user_rendering(i,kRenderFxNone,0,0,0,kRenderTransAlpha,0)  
		}
		else if(speed > 5)
		{
			set_user_rendering(i,kRenderFxNone,0,0,0,kRenderTransAlpha,255)  
		}
	}
}
