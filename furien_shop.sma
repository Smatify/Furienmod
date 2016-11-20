#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <fun>
#include <engine>
#include <cstrike>

#define PLUGIN "Furienmod - Shop"
#define VERSION "1.0.0b"
#define AUTHOR "Smatify"

#define FURIEN_DISABLED 1<<31

new iHealth[33],iArmor[33],iDeagleAmmoPri[33],iDeagleAmmoSec[33]

/* Terror Stuff */
new g_bHasDGL[33],g_bHasRB[33]
new g_iHpGot[33],g_iApGot[33],g_iHeGot[33], g_iFlashGot[33],g_iSmokeGot[33]

/* CT Stuff */
new g_bHasSDGL[33],g_bHasDEF[33],g_bHasPARA[33],g_bHasRBCT[33],g_bHasBratz[33]
new g_iHpGotCT[33],g_iApGotCT[33],g_iHeGotCT[33], g_iFlashGotCT[33],g_iSmokeGotCT[33]

new DG_V_MODEL[64] = "models/kiasfurien/v_golden_deagle.mdl"
new DG_P_MODEL[64] = "models/kiasfurien/p_golden_deagle.mdl"
new SK_V_MODEL[64] = "models/kiasfurien/v_superknife_v3.mdl"

/* Superknife */
new bool:g_bHasSK[33];

#define XO_WEAPON 4
#define m_pPlayer 41

#define XO_PLAYER		5
#define m_pActiveItem	373

/* No Flash */
new g_msgScreenFade
new bool:g_bHasNF[33]

/* Wallhang Stuff */
#define XTRA_OFS_PLAYER			5
#define m_Activity				73
#define m_IdealActivity			74
#define m_flNextAttack			83
#define m_afButtonPressed		246

#define FIRST_PLAYER_ID	1
#define MAX_PLAYERS		32

#define PLAYER_JUMP		6

#define ACT_HOP 7

//#define FBitSet(%1,%2)		(%1 & %2)

new g_iMaxPlayers
#define IsPlayer(%1)	( FIRST_PLAYER_ID <= %1 <= g_iMaxPlayers )

#define IsHidden(%1)	IsPlayer(%1)

#define KNIFE_DRAW			3

new g_bHasWallHang
#define SetUserWallHang(%1)		g_bHasWallHang |=	1<<(%1&31)
#define RemoveUserWallHang(%1)	g_bHasWallHang &=	~(1<<(%1&31))
#define HasUserWallHang(%1)		g_bHasWallHang &	1<<(%1&31)

new g_bHanged
#define SetUserHanged(%1)	g_bHanged |=	1<<(%1&31)
#define RemoveUserHanged(%1)	g_bHanged &=	~(1<<(%1&31))
#define IsUserHanged(%1)		g_bHanged &	1<<(%1&31)

new Float:g_fVecMins[MAX_PLAYERS+1][3]
new Float:g_fVecMaxs[MAX_PLAYERS+1][3]
new Float:g_fVecOrigin[MAX_PLAYERS+1][3]

new bool:g_bRoundEnd

#define OFFSET_CLIPAMMO        51
#define OFFSET_LINUX_WEAPONS    4
#define fm_cs_set_weapon_ammo(%1,%2)    set_pdata_int(%1, OFFSET_CLIPAMMO, %2, OFFSET_LINUX_WEAPONS)

// players offsets
#define m_pActiveItem 373

const NOCLIP_WPN_BS    = ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))

/* Cost - CVars */
new cvar_ct_def,cvar_ct_para,cvar_ct_hp,cvar_ct_ap,cvar_ct_hp_max,cvar_ct_ap_max,cvar_ct_he,cvar_ct_flash,cvar_ct_smoke,cvar_ct_noflash,cvar_ct_sdgl,cvar_ct_wallhang,cvar_ct_bratz
new cvar_t_sk,cvar_t_dgl,cvar_t_hp,cvar_t_ap,cvar_t_he,cvar_t_hp_max,cvar_t_ap_max,cvar_t_flash,cvar_t_smoke,cvar_t_wallhang,cvar_t_noflash

/* Amount - Cvars
new cvar_ct_hp_amnt,cvar_ct_ap_amnt,cvar_ct_he_amnt,cvar_ct_flash_amnt,cvar_ct_smoke_amnt
new cvar_t_dgl_amnt,cvar_t_hp_amnt,cvar_t_ap_amnt,cvar_t_he_amnt,cvar_t_flash_amnt,cvar_t_smoke_amnt*/

new const g_MaxClipAmmo[] = 
{
    0,
    13, //CSW_P228
    0,
    10, //CSW_SCOUT
    0,  //CSW_HEGRENADE
    7,  //CSW_XM1014
    0,  //CSW_C4
    30,//CSW_MAC10
    30, //CSW_AUG
    0,  //CSW_SMOKEGRENADE
    15,//CSW_ELITE
    20,//CSW_FIVESEVEN
    25,//CSW_UMP45
    30, //CSW_SG550
    35, //CSW_GALIL
    25, //CSW_FAMAS
    12,//CSW_USP
    20,//CSW_GLOCK18
    10, //CSW_AWP
    30,//CSW_MP5NAVY
    100,//CSW_M249
    8,  //CSW_M3
    30, //CSW_M4A1
    30,//CSW_TMP
    20, //CSW_G3SG1
    0,  //CSW_FLASHBANG
    7,  //CSW_DEAGLE
    30, //CSW_SG552
    30, //CSW_AK47
    0,  //CSW_KNIFE
    50//CSW_P90
}

public plugin_precache()
{
	precache_model(DG_V_MODEL)
	precache_model(DG_P_MODEL)
	precache_model(SK_V_MODEL)
}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("furien_shop", VERSION, FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	
	register_clcmd("shop",		"CmdShop")
	register_clcmd("say shop",	"CmdShop")
	register_clcmd("say /shop",	"CmdShop")
	register_clcmd("say_team shop",	"CmdShop")
	register_clcmd("say_team /shop","CmdShop")
	
	register_clcmd("buy",		"CmdShop")

	/* Item Related Stuff */
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage") // Event wen Spieler schaden erhält
	
	register_event("DeathMsg", "Event_DeathMsg", "a") // Wenn Spieler stirbt
	
	register_event("WeapPickup","checkModel","b","1=19") // Aktuelle Waffe prüfe ( wegen Model )
	
	register_event("CurWeapon","checkWeapon","be","1=1") // Bei Waffenwechsel Waffe prüfen
	
	register_event( "ScreenFade", "EventFlash", "be", "4=255", "5=255", "6=255", "7>199");  // Wenn geflashed
	
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "CKnife_Deploy", true)
	
	g_msgScreenFade = get_user_msgid("ScreenFade")
	
	RegisterHam(Ham_Player_Jump, "player", "Player_Jump") 
	
	RegisterHam(Ham_Touch, "func_wall", "World_Touch") 
	RegisterHam(Ham_Touch, "func_breakable", "World_Touch") 
	RegisterHam(Ham_Touch, "worldspawn", "World_Touch") 
	
	g_iMaxPlayers = get_maxplayers()     
	
	RegisterHam(Ham_Spawn,"player","playerSpawn");
	
	register_event("HLTV", "Event_HLTV_New_Round", "a", "1=0", "2=0") 
	register_logevent("Logevent_Round_End", 2, "1=Round_End") 
	
	/* Cost - CVars */
	cvar_ct_def = register_cvar("furien_ct_defuse_costs", "300", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_ct_para = register_cvar("furien_ct_para_costs", "16000", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_ct_hp	= register_cvar("furien_ct_hp_costs", "4000", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_ct_ap = register_cvar("furien_ct_ap_costs", "3500", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_ct_he = register_cvar("furien_ct_he_costs", "2000", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_ct_flash = register_cvar("furien_ct_flash_costs", "1000", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_ct_smoke = register_cvar("furien_ct_smoke_costs", "1000", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_ct_noflash = register_cvar("furien_ct_noflash_costs", "4000", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_ct_sdgl = register_cvar("furien_ct_superdgl_costs", "16000", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_ct_wallhang = register_cvar("furien_ct_wallhang_costs", "10000", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_ct_bratz = register_cvar("furien_ct_bratz_costs", "24000", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	
	cvar_t_sk = register_cvar("furien_t_sknife_costs", "16000", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_t_dgl = register_cvar("furien_t_dgl_costs", "10000", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_t_hp = register_cvar("furien_t_hp_costs", "4000", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_t_ap = register_cvar("furien_t_ap_costs", "2000", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_t_he = register_cvar("furien_t_he_costs", "1000", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_t_flash = register_cvar("furien_t_flash_costs", "1000", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_t_smoke = register_cvar("furien_t_smoke_costs", "1000", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_t_wallhang = register_cvar("furien_t_wallhang_costs", "10000", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_t_noflash = register_cvar("furien_t_noflash_costs", "500", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	
	/* Undefined _ CVars */
	cvar_ct_hp_max = register_cvar("furien_ct_hp_max", "200", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_ct_ap_max = register_cvar("furien_ct_ap_max", "175", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	
	cvar_t_hp_max = register_cvar("furien_t_hp_max", "250", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	cvar_t_ap_max = register_cvar("furien_t_ap_max", "200", FCVAR_SERVER | FCVAR_SPONLY | FCVAR_EXTDLL)
	
	/* Amount - Cvars
	cvar_ct_hp_amnt = register_cvar("furien_amount_ct_hp", "2")
	cvar_ct_ap_amnt = register_cvar("furien_amount_ct_ap", "2")
	cvar_ct_he_amnt = register_cvar("furien_amount_ct_he", "1")
	cvar_ct_flash_amnt = register_cvar("furien_amount_ct_flash", "1")
	cvar_ct_smoke_amnt = register_cvar("furien_amount_ct_smoke", "1")
	
	cvar_t_dgl_amnt = register_cvar("furien_amount_t_dgl", "1")
	cvar_t_hp_amnt = register_cvar("furien_amount_t_hp", "2")
	cvar_t_ap_amnt = register_cvar("furien_amount_t_ap", "2")
	cvar_t_he_amnt = register_cvar("furien_amount_t_he", "1")
	cvar_t_flash_amnt = register_cvar("furien_amount_t_flash", "1")
	cvar_t_smoke_amnt = register_cvar("furien_amount_t_smoke", "1")*/
	
}

public playerSpawn(id)
{
	if(is_user_alive(id))
	{
		set_task(0.5,"giveHealth",id)
	}
}

public giveHealth(id)
{
	set_user_health(id, iHealth[id])
	cs_set_user_armor(id,iArmor[id],CS_ARMOR_KEVLAR)
	if(g_bHasDGL[id] && cs_get_user_team(id) == CS_TEAM_T)
	{
		new iWeapon = give_item(id,"weapon_deagle")
		cs_set_weapon_ammo(iWeapon,iDeagleAmmoPri[id])
		cs_set_user_bpammo(id,CSW_DEAGLE,iDeagleAmmoSec[id])
		
	}
}

public MoneyDebug(id)
{
	if(get_user_flags(id) && ADMIN_BAN)
		cs_set_user_money(id, 16000)
}

public CmdShop(id)
{
	if(is_user_alive(id))
	{
		switch(cs_get_user_team(id))
		{
		case CS_TEAM_CT : AntiFurienMenu(id)
		case CS_TEAM_T : FurienMenu(id)
		}
	}
}

public AntiFurienMenu(id)
{
	if(cs_get_user_team(id) != CS_TEAM_CT)
		return PLUGIN_HANDLED
	
	if(!is_user_alive(id))
		return PLUGIN_HANDLED
	
	new antifurientitle[64]
	new money = cs_get_user_money(id)
	
	formatex(antifurientitle, 63, "\yAnti Furien Shop - \yYou have \r$%i - ", money)
	
	new menu = menu_create(antifurientitle,"ctshop_handler")
	
	new def[64],para[64],hp[64],ap[64],he[64],flash[64],smoke[64],noflash[64],sdgl[64],wallhang[64],bratz[64]
	
	formatex(def,charsmax(def),				"Defuse Kit - $%i", get_pcvar_num(cvar_ct_def))
	formatex(para,charsmax(para),			"Para (200 Bullets) - $%i", get_pcvar_num(cvar_ct_para))
	formatex(hp,charsmax(hp),				"50 HP - $%i", get_pcvar_num(cvar_ct_hp))
	formatex(ap,charsmax(ap),				"75 AP - $%i", get_pcvar_num(cvar_ct_ap))
	formatex(he,charsmax(he),				"1 HE Grenade - $%i", get_pcvar_num(cvar_ct_he))
	formatex(flash,charsmax(flash),			"1 Flash Grenade - $%i", get_pcvar_num(cvar_ct_flash))
	formatex(smoke,charsmax(smoke),			"1 Smoke Grenade - $%i", get_pcvar_num(cvar_ct_smoke))
	formatex(noflash,charsmax(noflash),		"No Flash - $%i", get_pcvar_num(cvar_ct_noflash))
	formatex(sdgl,charsmax(sdgl),			"Super Deagle - $%i", get_pcvar_num(cvar_ct_sdgl))
	formatex(wallhang,charsmax(wallhang),	"Wallhang - $%i", get_pcvar_num(cvar_ct_wallhang))
	formatex(bratz,charsmax(bratz),			"Bratzhead - $%i", get_pcvar_num(cvar_ct_bratz))
	

	if(g_bHasDEF[id] || money < get_pcvar_num(cvar_ct_def))
		menu_additem(menu,def,"1",1<<31)
	else
		menu_additem(menu,def,"1",0)
	if(g_bHasPARA[id] || money < get_pcvar_num(cvar_ct_para))
		menu_additem(menu,para,"2",1<<31)
	else
		menu_additem(menu,para,"2",0)
	
	if(g_iHpGotCT[id] > 1 || money < get_pcvar_num(cvar_ct_hp))
		menu_additem(menu,hp,"3",1<<31)
	else
		menu_additem(menu,hp,"3",0)
	
	if(g_iApGotCT[id] > 1 || money < get_pcvar_num(cvar_ct_ap))
		menu_additem(menu,ap,"4",1<<31)
	else
		menu_additem(menu,ap, "4",0)
	
	if(g_iHeGotCT[id] > 0 || money < get_pcvar_num(cvar_ct_he))
		menu_additem(menu,he, "5",1<<31)
	else
		menu_additem(menu,he, "5",0)
	
	if(g_iFlashGotCT[id] > 1 || money < get_pcvar_num(cvar_ct_flash))
		menu_additem(menu,flash, "6",1<<31)
	else
		menu_additem(menu,flash, "6",0)
	
	if(g_iSmokeGotCT[id] > 1 || money < get_pcvar_num(cvar_ct_smoke))
		menu_additem(menu,smoke, "7",1<<31)
	else
		menu_additem(menu,smoke, "7",0)
	
	if(g_bHasNF[id] || money < get_pcvar_num(cvar_ct_noflash))
		menu_additem(menu,noflash, "8",1<<31)
	else
		menu_additem(menu,noflash, "8",0)
	
	if(g_bHasSDGL[id] || money < get_pcvar_num(cvar_ct_sdgl))
		menu_additem(menu,sdgl, "9",1<<31)
	else
		menu_additem(menu,sdgl, "9",0)
		
	if(g_bHasRBCT[id] || money < get_pcvar_num(cvar_ct_wallhang))
		menu_additem(menu,wallhang, "10",1<<31)
	else
		menu_additem(menu,wallhang, "10",0)	
	if(g_bHasBratz[id] || money < get_pcvar_num(cvar_ct_bratz))
		menu_additem(menu,bratz, "11",1<<31)
	else
		menu_additem(menu,bratz, "11",0)
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED
}

public ctshop_handler(id, menu, item)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED
	
	if(cs_get_user_team(id) != CS_TEAM_CT)
		return PLUGIN_HANDLED
	
	new money = cs_get_user_money(id)
	new data[6], szName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback);
	new key = str_to_num(data);
	switch(key)
	{
		case 1:
		{
			g_bHasDEF[id] = true
			cs_set_user_defuse(id, 1)
			cs_set_user_money(id, money - get_pcvar_num(cvar_ct_def))
			
		}
		case 2:
		{
			
			give_item(id, "weapon_m249")
			cs_set_user_bpammo(id, CSW_M249, 100)
			g_bHasPARA[id] = true
			cs_set_user_money(id, money - get_pcvar_num(cvar_ct_para))
			
		}
		case 3:
		{
			
			new hp = get_user_health(id)
			if(hp < get_pcvar_num(cvar_ct_hp_max))
			{
				set_user_health(id, hp + 50)
			}
			g_iHpGotCT[id] ++
			cs_set_user_money(id, money - get_pcvar_num(cvar_ct_hp))
			
			if(hp > get_pcvar_num(cvar_ct_hp_max))
			{
				set_user_health(id, get_pcvar_num(cvar_ct_hp_max))
			}
			
		}
		case 4:
		{
			
			new ap = get_user_armor(id)
			if(get_user_armor(id) < get_pcvar_num(cvar_ct_ap_max))
			{
				cs_set_user_armor(id,ap + 75,CS_ARMOR_KEVLAR)
			}
			g_iApGotCT[id] ++
			cs_set_user_money(id, money - get_pcvar_num(cvar_ct_ap))
			
			if(ap > get_pcvar_num(cvar_ct_ap_max))
			{
				set_user_armor(id, get_pcvar_num(cvar_ct_hp_max))
			}
			
		}
		case 5:
		{
			
			if(cs_get_user_bpammo(id, CSW_HEGRENADE) < 1)
			{
				give_item(id, "weapon_hegrenade")
				g_iHeGotCT[id] ++
				cs_set_user_money(id, money - get_pcvar_num(cvar_ct_he))
				return PLUGIN_HANDLED
			}
			cs_set_user_bpammo(id,CSW_HEGRENADE, cs_get_user_bpammo(id, CSW_HEGRENADE) + 1)
			g_iHeGotCT[id] ++
			cs_set_user_money(id, money - get_pcvar_num(cvar_ct_he))
			
		}
		case 6:
		{
			if(cs_get_user_bpammo(id, CSW_FLASHBANG) < 1)
			{
				give_item(id, "weapon_flashbang")
				g_iFlashGotCT[id] ++
				cs_set_user_money(id, money - get_pcvar_num(cvar_ct_flash))
				return PLUGIN_HANDLED
			}
			cs_set_user_bpammo(id,CSW_FLASHBANG, cs_get_user_bpammo(id, CSW_FLASHBANG) + 1)
			g_iFlashGotCT[id] ++
			cs_set_user_money(id, money - get_pcvar_num(cvar_ct_flash))
			
		}
		case 7:
		{
			if(cs_get_user_bpammo(id, CSW_SMOKEGRENADE) < 1)
			{
				give_item(id, "weapon_smokegrenade")
				g_iSmokeGotCT[id] ++
				cs_set_user_money(id, money - get_pcvar_num(cvar_ct_smoke))
				return PLUGIN_HANDLED
			}
			cs_set_user_bpammo(id,CSW_SMOKEGRENADE, cs_get_user_bpammo(id, CSW_SMOKEGRENADE) + 1)
			g_iSmokeGotCT[id] ++
			cs_set_user_money(id, money - get_pcvar_num(cvar_ct_smoke))
			
		}
		case 8:
		{
			g_bHasNF [id] = true
			cs_set_user_money(id, money - get_pcvar_num(cvar_ct_noflash))
		}
		case 9:
		{
			g_bHasSDGL[id] = true
			cs_set_user_money(id, money - get_pcvar_num(cvar_ct_sdgl))
		}
		case 10:
		{
			SetUserWallHang( id )
			cs_set_user_money(id, money - get_pcvar_num(cvar_ct_wallhang))
			
		}
		case 11:
		{
			g_bHasBratz[id] = true
			cs_set_user_money(id, money - get_pcvar_num(cvar_ct_bratz))
		}
	}
	return PLUGIN_HANDLED
}

public FurienMenu(id)
{
	if(cs_get_user_team(id) != CS_TEAM_T)
		return PLUGIN_HANDLED
	
	new furientitle[64]
	
	new money = cs_get_user_money(id)
	
	formatex(furientitle, 63, "\yFurien Shop - \yYou have \r$%i - ",money)
	
	new menu = menu_create(furientitle,"tshop_handler")
	
	new sk[64],dgl[64],hp[64],ap[64],he[64],flash[64],smoke[64],noflash[64],wallhang[64]
	
	formatex(sk,charsmax(sk),				"Superknife - $%i", get_pcvar_num(cvar_t_sk))
	formatex(dgl,charsmax(dgl),				"Deagle (14 Bullets) - $%i", get_pcvar_num(cvar_t_dgl))
	formatex(hp,charsmax(hp),				"50 HP - $%i", get_pcvar_num(cvar_t_hp))
	formatex(ap,charsmax(ap),				"75 AP - $%i", get_pcvar_num(cvar_t_ap))
	formatex(he,charsmax(he),				"1 HE Grenade - $%i", get_pcvar_num(cvar_t_he))
	formatex(flash,charsmax(flash),			"1 Flash Grenade - $%i", get_pcvar_num(cvar_t_flash))
	formatex(smoke,charsmax(smoke),			"1 Smoke Grenade - $%i", get_pcvar_num(cvar_t_smoke))
	formatex(noflash,charsmax(noflash),		"No Flash - $%i", get_pcvar_num(cvar_t_noflash))
	formatex(wallhang,charsmax(wallhang),	"Wallhang - $%i", get_pcvar_num(cvar_t_wallhang))
	
	if(g_bHasSK[id] || money < get_pcvar_num(cvar_t_sk))
		menu_additem(menu,sk, "1",1<<31)
	else
		menu_additem(menu,sk, "1",0)
	if(g_bHasDGL[id] || money < get_pcvar_num(cvar_t_dgl))
		menu_additem(menu,dgl, "2",1<<31)
	else
		menu_additem(menu,dgl, "2",0)
	
	if(g_iHpGot[id] > 2 || money < get_pcvar_num(cvar_t_hp))
		menu_additem(menu,hp, "3",1<<31)
	else
		menu_additem(menu,hp, "3",0)
	
	if(g_iApGot[id] > 2 || money < get_pcvar_num(cvar_t_ap))
		menu_additem(menu,ap, "4",1<<31)
	else
		menu_additem(menu,ap, "4",0)
	
	if(g_iHeGot[id] > 2 || money < get_pcvar_num(cvar_t_he))
		menu_additem(menu,he, "5",1<<31)
	else
		menu_additem(menu,he, "5",0)
	
	if(g_iFlashGot[id] > 1 || money < get_pcvar_num(cvar_t_flash))
		menu_additem(menu,flash, "6",1<<31)
	else
		menu_additem(menu,flash, "6",0)
	
	if(g_iSmokeGot[id] > 2 || money < get_pcvar_num(cvar_t_smoke))
		menu_additem(menu,smoke, "7",1<<31)
	else
		menu_additem(menu,smoke, "7",0)
	
	if(g_bHasNF[id] || money < get_pcvar_num(cvar_t_noflash))
		menu_additem(menu,noflash, "8",1<<31)
	else
		menu_additem(menu,noflash, "8",0)
		
	if(g_bHasRBCT[id] || money < get_pcvar_num(cvar_t_wallhang))
		menu_additem(menu,wallhang, "9",1<<31)
	else
		menu_additem(menu,wallhang, "9",0)
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED
}

public tshop_handler(id, menu, item)
{
	if(cs_get_user_team(id) != CS_TEAM_T)
		return PLUGIN_HANDLED
	
	new money = cs_get_user_money(id)
	new data[6], szName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback);
	new key = str_to_num(data);
	switch(key)
	{
		case 1:
		{
			g_bHasSK[id] = true
			give_item(id, "weapon_knife")
			ExecuteHamB(Ham_Item_Deploy, get_pdata_cbase(id, m_pActiveItem, XO_PLAYER))
			cs_set_user_money(id, money - get_pcvar_num(cvar_t_sk))
			
		}
		case 2:
		{
			
			give_item(id, "weapon_deagle")
			cs_set_user_bpammo(id, CSW_DEAGLE, 7)
			cs_set_user_money(id, money - get_pcvar_num(cvar_t_dgl))
			
		}
		case 3:
		{
			
			new hp = get_user_health(id)
			if(hp < get_pcvar_num(cvar_t_hp_max))
			{
				set_user_health(id, hp + 50)
			}
			g_iHpGot[id] ++
			cs_set_user_money(id, money - get_pcvar_num(cvar_t_hp))
			if(hp > get_pcvar_num(cvar_t_hp_max))
			{
				set_user_health(id, get_pcvar_num(cvar_t_hp_max))
			}
			
		}
		case 4:
		{
			new ap = get_user_armor(id)
			if(ap < get_pcvar_num(cvar_t_ap_max))
			{
				cs_set_user_armor(id,ap + 75,CS_ARMOR_KEVLAR)
			}
			g_iApGot[id] ++
			cs_set_user_money(id, money - get_pcvar_num(cvar_t_ap))
			
			if(ap > get_pcvar_num(cvar_t_ap_max))
			{
				set_user_armor(id, get_pcvar_num(cvar_t_ap_max))
			}
			
		}
		case 5:
		{
			if(cs_get_user_bpammo(id, CSW_HEGRENADE) < 1)
			{
				give_item(id, "weapon_hegrenade")
				g_iHeGot[id] ++
				cs_set_user_money(id, money - get_pcvar_num(cvar_t_he))
				return PLUGIN_HANDLED
			}
			cs_set_user_bpammo(id,CSW_HEGRENADE, cs_get_user_bpammo(id, CSW_HEGRENADE) + 1)
			g_iHeGot[id] ++
			cs_set_user_money(id, money - get_pcvar_num(cvar_t_he))
			
		}
		case 6:
		{
			if(cs_get_user_bpammo(id, CSW_FLASHBANG) < 1)
			{
				give_item(id, "weapon_flashbang")
				g_iFlashGot[id] ++
				cs_set_user_money(id, money - get_pcvar_num(cvar_t_flash))
				return PLUGIN_HANDLED
			}
			cs_set_user_bpammo(id,CSW_FLASHBANG, cs_get_user_bpammo(id, CSW_FLASHBANG) + 1)
			g_iFlashGot[id] ++
			cs_set_user_money(id, money - get_pcvar_num(cvar_t_flash))
			
		}
		case 7:
		{
			if(cs_get_user_bpammo(id, CSW_SMOKEGRENADE) < 1)
			{
				give_item(id, "weapon_smokegrenade")
				g_iSmokeGot[id] ++
				cs_set_user_money(id, money - get_pcvar_num(cvar_t_smoke))
				return PLUGIN_HANDLED
			}
			cs_set_user_bpammo(id,CSW_SMOKEGRENADE, cs_get_user_bpammo(id, CSW_SMOKEGRENADE) + 1)
			g_iSmokeGot[id] ++
			cs_set_user_money(id, money - get_pcvar_num(cvar_t_smoke))
			
		}
		case 8:
		{
			g_bHasNF [id] = true
			cs_set_user_money(id, money - get_pcvar_num(cvar_t_noflash))
		}
		case 9:
		{
			SetUserWallHang(id)
			cs_set_user_money(id, money - get_pcvar_num(cvar_t_wallhang))
		}
	}
	return PLUGIN_HANDLED
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) // Event wen Spieler schaden erhält
{
	if (inflictor == attacker && is_user_alive( attacker ) && get_user_weapon( attacker ) == CSW_KNIFE && g_bHasSK [attacker] || inflictor == attacker && is_user_alive( attacker ) && get_user_weapon(attacker) == CSW_DEAGLE && g_bHasSDGL[attacker] && cs_get_user_team(attacker) == CS_TEAM_CT) // Wenn Spieler Knife und SK hatt
	{
		SetHamParamFloat(4, damage * 3) // Schaden verdreifachen
	}
}

public Event_DeathMsg(id) // Wenn Spieler stirbt
{
	new iVictim = read_data(2)  // Opfer ( trolololol xD )
	
	g_bHasSK[iVictim] = false
	g_bHasSDGL[iVictim] = false 
	g_bHasNF[iVictim] = false
	g_bHasDEF[iVictim] = false
	g_bHasPARA[iVictim] = false
	g_bHasRB[iVictim] = false
	g_bHasRBCT[iVictim] = false
	g_bHasBratz[iVictim] = false
	
	g_iHpGot[iVictim] = 0
	g_iApGot[iVictim] = 0
	g_iHeGot[iVictim] = 0
	g_iFlashGot[iVictim] = 0
	g_iSmokeGot[iVictim] = 0
	g_iHpGotCT[iVictim] = 0
	g_iApGotCT[iVictim] = 0
	g_iHeGotCT[iVictim] = 0
	g_iFlashGotCT[iVictim] = 0
	g_iSmokeGotCT[iVictim] = 0
	
}

public CKnife_Deploy( iKnife )
{
	new id = get_pdata_cbase(iKnife, m_pPlayer, XO_WEAPON)
	
	if( g_bHasSK[id] )
	{
		entity_set_string( id, EV_SZ_viewmodel, SK_V_MODEL)
	}
}

public checkModel(id)
{
	new szWeapID = read_data(2)
	
	if ( szWeapID == CSW_DEAGLE && g_bHasSDGL[id] && cs_get_user_team(id) == CS_TEAM_CT)
	{
		set_pev(id, pev_viewmodel2, DG_V_MODEL)
		set_pev(id, pev_weaponmodel2, DG_P_MODEL)
	}
	return PLUGIN_HANDLED
}

public checkWeapon(id)
{
	if(g_bHasBratz[id] && cs_get_user_team(id) == CS_TEAM_CT)
	{
		new iWeapon = read_data(2)
		if( !( NOCLIP_WPN_BS & (1<<iWeapon) ) )
		{
			fm_cs_set_weapon_ammo( get_pdata_cbase(id, m_pActiveItem) , g_MaxClipAmmo[ iWeapon ] )
			return PLUGIN_CONTINUE
		}
		return PLUGIN_CONTINUE
	}
	
	
	new plrClip, plrAmmo
	new plrWeapId
	
	plrWeapId = get_user_weapon(id, plrClip , plrAmmo)
	
	if (plrWeapId == CSW_DEAGLE && g_bHasSDGL[id])
	{
		checkModel(id)
	}
	else 
	{
		return PLUGIN_CONTINUE
	}
	
	return PLUGIN_HANDLED
}

public EventFlash(id)
{
	if(g_bHasNF[id])
	{
		message_begin(MSG_ONE, g_msgScreenFade, {0,0,0},id)
		write_short(1)
		write_short(1)
		write_short(1)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(255)
		message_end()
	}
	
}

public Event_HLTV_New_Round() 
{ 
	g_bRoundEnd = false 

	new players[32], pnum, tempid
	get_players(players, pnum, "a"); 
	for( new i; i<pnum; i++ ) 
	{ 
		tempid = players[i];
		g_bHasBratz[tempid] = false
	}
		
} 
public Logevent_Round_End() 
{ 
	g_bRoundEnd = true
	g_bHanged = 0
	
	new players[32], pnum, tempid
	get_players(players, pnum, "a"); 
	for( new i; i<pnum; i++ ) 
	{ 
		tempid = players[i];
		new health = get_user_health(tempid)
		new armor = get_user_armor(tempid)
		
		switch(armor)
		{
			case 0..74:
			{
				iArmor[tempid] = 0
			}
			case 75..255: 
			{
				iArmor[tempid] = armor
			}
		}
		
		switch(health)
		{
			case 1..100:
			{
				iHealth[tempid] = 100
			}
			case 101..255:
			{
				iHealth[tempid] = health
			}
		}
		
		if(g_bHasDGL[tempid] && cs_get_user_team(tempid) == CS_TEAM_T)
		{
			iDeagleAmmoPri[tempid] = cs_get_weapon_ammo(tempid)
			iDeagleAmmoSec[tempid] = cs_get_user_bpammo(tempid,CSW_DEAGLE)
		}
	}
} 

public client_putinserver( id ) 
{ 
	RemoveUserWallHang( id ) 
	RemoveUserHanged( id ) 
	g_bHasSK[id] = false
	g_bHasNF[id] = false
	g_bHasSDGL[id] = false
	g_bHasDEF[id] = false
	g_bHasPARA[id] = false
	g_bHasRB[id] = false
	g_bHasRBCT[id] = false
	
	g_iHpGot[id] = 0
	g_iApGot[id] = 0
	g_iHeGot[id] = 0
	g_iFlashGot[id] = 0
	g_iSmokeGot[id] = 0
	g_iHpGotCT[id] = 0
	g_iApGotCT[id] = 0
	g_iHeGotCT[id] = 0
	g_iFlashGotCT[id] = 0
	g_iSmokeGotCT[id] = 0
	
	iHealth[id] = 100
	iArmor[id] = 0
	iDeagleAmmoPri[id] = 0
	iDeagleAmmoSec[id] = 0
} 

public Player_Jump(id)
{
	if(	g_bRoundEnd
	||	~HasUserWallHang(id)
	||	~IsUserHanged(id)
	||	!is_user_alive(id)	)
	{
		return HAM_IGNORED
	}

	if( (pev(id, pev_flags) & FL_WATERJUMP) || pev(id, pev_waterlevel) >= 2 )
	{
		return HAM_IGNORED
	}

	static afButtonPressed ; afButtonPressed = get_pdata_int(id, m_afButtonPressed)

	if( ~afButtonPressed & IN_JUMP )
	{
		return HAM_IGNORED
	}

	RemoveUserHanged(id)

	new Float:fVecVelocity[3]

	velocity_by_aim(id, 600, fVecVelocity)
	set_pev(id, pev_velocity, fVecVelocity)

	set_pdata_int(id, m_Activity, ACT_HOP)
	set_pdata_int(id, m_IdealActivity, ACT_HOP)
	set_pev(id, pev_gaitsequence, PLAYER_JUMP)
	set_pev(id, pev_frame, 0.0)
	set_pdata_int(id, m_afButtonPressed, afButtonPressed & ~IN_JUMP)

	return HAM_SUPERCEDE
}


public client_PostThink(id)
{
	if( HasUserWallHang(id) && IsUserHanged(id) )
	{
		engfunc(EngFunc_SetSize, id, g_fVecMins[ id ], g_fVecMaxs[ id ])
		engfunc(EngFunc_SetOrigin, id, g_fVecOrigin[ id ])
		set_pev(id, pev_velocity, 0)
		set_pdata_float(id, m_flNextAttack, 1.0, XTRA_OFS_PLAYER)
	}
}

public World_Touch(iEnt, id)
{
	if(	!g_bRoundEnd
	&&	IsPlayer(id)
	&&	HasUserWallHang(id)
	&&	~IsUserHanged(id)
	&&	is_user_alive(id)
	&&	pev(id, pev_button) & IN_USE
	&&	~pev(id, pev_flags) & FL_ONGROUND	)
	{
		SetUserHanged(id)
		pev(id, pev_mins, g_fVecMins[id])
		pev(id, pev_maxs, g_fVecMaxs[id])
		pev(id, pev_origin, g_fVecOrigin[id])
	}
}
