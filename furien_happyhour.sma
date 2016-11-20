#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fun>
#include <cstrike>

#define PLUGIN "Furienmod - Happy Hour"
#define VERSION "1.0.0b"
#define AUTHOR "Smatify"

new cvar_init,cvar_end,cvar_money
new bool:g_bIsHappyHour

new const numbers[11][] = 
{
    "zero",
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "ten"
}
 
new happy_hour_num;
 

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("furien_happyhour", VERSION, FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	
	cvar_init = register_cvar("furien_happyhour_start", "15", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_end = register_cvar("furien_happyhour_end", "17", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_money = register_cvar("furien_happyhour_amount","5750", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	
	RegisterHam(Ham_Spawn,"player","playerSpawn");
	
}

public playerSpawn(id)
{
	if(g_bIsHappyHour && is_user_connected(id))
	{
		set_task(5.0,"HHStuff",id)
	}
}

public HHStuff(id)
{
	new money = cs_get_user_money(id)
	cs_set_user_money(id,money + get_pcvar_num(cvar_money))
	set_hudmessage(0, 255, 0, -1.0, 0.10, 0, 6.0, 5.0)
	show_hudmessage(id, "We have HappyHour! You got extra $%i.",get_pcvar_num(cvar_money))
}

public plugin_cfg()
{
	new data[3]
	get_time("%H", data, 2)
	
	if(get_pcvar_num(cvar_end) > str_to_num(data) >= get_pcvar_num(cvar_init))
	{
		EnableHappyHour()
	}  
	
}

public EnableHappyHour()
{
        // ... client_cmd(0, "spk....");
 
        set_task(1.0, "CountHappyHour", 123456, _, _, "a", 11);
 
        happy_hour_num = 10;
}
 
public CountHappyHour()
{
        client_cmd(0,"spk %s", numbers[happy_hour_num]);
 
        set_hudmessage(random(255), random(255), random(255), 0.35, 0.3, 0, 0.1, 2.5, 1.0, 1.0, 4);
 
        if(happy_hour_num > 0)
            show_hudmessage(0, "The HappyHour starts in: %d seconds", happy_hour_num);
        else
        {
            show_hudmessage(0, "The HappyHour is now over!");
 
            g_bIsHappyHour = false;
        }
 
        happy_hour_num--;
}