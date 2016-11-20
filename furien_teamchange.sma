#include <amxmodx> 
#include <fakemeta> 

#define PLUGIN "Furienmod - Teamchange" 
#define VERSION "0.0.1"
#define AUTHOR "ConnorMcLeod"

#define XO_PLAYER 5 
#define m_iTeam 114 
#define OFFSET_INTERNALMODEL 126 

#define cs_get_user_team_index(%0)    get_pdata_int(%0, m_iTeam, XO_PLAYER) 

enum 
{ 
	TEAM_UNASSIGNED, 
	TEAM_TERRORIST, 
	TEAM_CT, 
	TEAM_SPECTATOR 
} 

new const g_szTeamNames[][] =  
{ 
	"UNASSIGNED", 
	"TERRORIST", 
	"CT", 
	"SPECTATOR" 
} 

enum 
{ 
	CT_URBAN = 1, 
	T_TERROR = 2, 
	T_LEET = 3, 
	T_ARCTIC = 4, 
	CT_GSG9 = 5, 
	CT_GIGN = 6, 
	CT_SAS = 7, 
	T_GUERILLA = 8, 
	CT_VIP = 9, 
	T_MILITIA = 10, 
	CT_SPETSNAZ = 11 
} 

new const g_iModels[][] =  
{ 
	{T_TERROR, CT_URBAN}, 
	{T_LEET , CT_GSG9}, 
	{T_LEET, CT_SAS}, 
	{T_GUERILLA, CT_GIGN}, 
	{T_MILITIA, CT_SPETSNAZ} 
} 

new const g_szModels[][] =  
{ 
	"", 
	"urban", 
	"terror", 
	"leet", 
	"arctic", 
	"gsg9", 
	"gign", 
	"sas", 
	"guerilla", 
	"vip", 
	"militia", 
	"spetsnaz" 
} 

new g_iMaxAppearances = 4 

new g_iTeamInfo 

public plugin_init() 
{ 
	register_plugin(PLUGIN, VERSION, AUTHOR) 
	register_event("SendAudio", "Event_SendAudio_MRAD_ctwin", "a", "2&%!MRAD_ctwin") 
	new szModName[6] 
	get_modname(szModName, charsmax(szModName)) 
	if( equal(szModName, "czero") ) 
	{ 
		g_iMaxAppearances = 5 
	} 
	
	g_iTeamInfo = get_user_msgid("TeamInfo") 
} 

public Event_SendAudio_MRAD_ctwin() 
{ 
	new iPlayers[32], iNum 
	get_players(iPlayers, iNum, "h") 
	if( iNum ) 
	{ 
		new id 
		for(--iNum; iNum>=0; iNum--) 
		{ 
			id = iPlayers[iNum] 
			switch( cs_get_user_team_index(id) ) 
			{ 
				case TEAM_TERRORIST:SetUserTeam(id, TEAM_CT) 
				case TEAM_CT:SetUserTeam(id, TEAM_TERRORIST) 
			} 
		} 
	} 
} 

SetUserTeam(id, iTeam) 
{ 
	if(is_user_connected(id))
	{
		set_pdata_int(id, m_iTeam, iTeam, XO_PLAYER) 
		
		new iNewModel = g_iModels[iTeam-1][  random(g_iMaxAppearances)  ] 
		
		set_pdata_int(id, OFFSET_INTERNALMODEL, iNewModel, XO_PLAYER) 
		
		set_user_info(id, "model", g_szModels[iNewModel]) 
		
		emessage_begin(MSG_ALL, g_iTeamInfo) 
		ewrite_byte(id) 
		ewrite_string(g_szTeamNames[iTeam]) 
		emessage_end() 
	}
}  
