#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <csgocolors_fix>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name        = "MakoVoteSystem",
	author 	    = "Neon, .1x (csgo)",
	description = "MakoVoteSystem",
	version     = "2.2",
	url         = "https://steamcommunity.com/id/dot_1x"
}

#define TOTALSTAGE 7

static char g_sStagesList[TOTALSTAGE][256] = {"EXTREME II", "RMZS", "HELLZ", "ZOMBIEDEN", "ZEDDYS", "RACE", "EXTREME II (HealTima)"}; // insert stage name here
static int g_iStageButtonId[TOTALSTAGE] = {140676, 100002, 100000, 100001, 100003, 100004, 100005}; // insert button hammerid here, the index must match of stage name

ArrayList g_aStageList, g_aWinner;
Menu g_mVoteMenu;
bool g_bStageOnCD[TOTALSTAGE], g_bIsRevote = false, g_bMakoVote = false, g_bOneStageLeft = false, g_bIsRaceMode = false, g_bHookSpawn = false;
float g_fVectorPos[3];

public void OnPluginStart(){
	RegServerCmd("sm_makovote", Command_StartVote);
	RegServerCmd("sm_startrace", Command_RaceMode);
	RegServerCmd("sm_endrace", Command_EndRace);
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_spawn", OnPlayerSpawn);
}
public void OnMapStart()
{
	VerifyMap();
	
	PrecacheSound("music/ZombiEden/mako/advent2.mp3", true);
	PrecacheSound("music/ZombiEden/mako/m2.mp3", true);
	PrecacheSound("music/ZombiEden/mako/m3.mp3", true);
	PrecacheSound("music/ZombiEden/mako/m4.mp3", true);
	PrecacheSound("music/ZombiEden/mako/m5.mp3", true);
	PrecacheSound("music/ZombiEden/mako/m6.mp3", true);
	
	AddFileToDownloadsTable("sound/music/ZombiEden/mako/advent2.mp3");
	AddFileToDownloadsTable("sound/music/ZombiEden/mako/m2.mp3");
	AddFileToDownloadsTable("sound/music/ZombiEden/mako/m3.mp3");
	AddFileToDownloadsTable("sound/music/ZombiEden/mako/m4.mp3");
	AddFileToDownloadsTable("sound/music/ZombiEden/mako/m5.mp3");
	AddFileToDownloadsTable("sound/music/ZombiEden/mako/m6.mp3");
	
	g_fVectorPos[0] = -9356.12;
	g_fVectorPos[1] = 4534.69;
	g_fVectorPos[2] = 99.5;
	
	g_bMakoVote = false;
	g_bIsRevote = false;
	g_bIsRaceMode = false;
	g_bHookSpawn = false;
	
	for (int i = 0; i <= (TOTALSTAGE - 1); i++)
		g_bStageOnCD[i] = false;
}
public Action VerifyMap()
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	if (!StrEqual(currentMap, "ze_ffvii_mako_reactor_v5_3_v5", false))
	{
		char sFilename[256];
		GetPluginFilename(INVALID_HANDLE, sFilename, sizeof(sFilename));
		ServerCommand("sm plugins unload %s", sFilename);
	}
}
public Action Command_RaceMode(int args){
	g_bIsRaceMode = true;
	int iRaceFinish = FindEntityByTargetname(INVALID_ENT_REFERENCE, "race_finish", "trigger_multiple");
	HookSingleEntityOutput(iRaceFinish, "OnStartTouch", Race_PlayerWinner);
	int iCells = ByteCountToCells(PLATFORM_MAX_PATH);
	LogAction(-1, -1, "Mako race started");
	g_aWinner = CreateArray(iCells);
	if(g_aWinner.Length > 1)
		g_aWinner.Clear();
	
} 
public void Race_PlayerWinner(const char[] output, int caller, int activator, float delay){
	g_aWinner.Push(activator);
}
public Action Command_EndRace(int args){
	if (!g_bIsRaceMode){
		LogAction(-1, -1, "Mako is not on race mode!");
		return;
	}
	for(int i = 1; i <= MaxClients; i++){
		if(g_aWinner.FindValue(i) != -1){
			continue;
		}
		if(IsClientInGame(i) && IsPlayerAlive(i))
			ServerCommand("zr_infect #%i", GetClientUserId(i));
	}
	CreateTimer(5.0, tTimer_EndRace);
	LogAction(-1, -1, "Mako race ended");
	g_bIsRaceMode = false;
	
}
Action tTimer_EndRace(Handle Timer){
	ServerCommand("sm_slay @t");
}
public Action Command_StartVote(int args){
	if(g_bOneStageLeft){
		GenerateArray();
		char sBuffer[64];
		for(int i = 0; i <= (g_aStageList.Length - 1); i++){
			if(!g_bStageOnCD[i]){
				g_aStageList.GetString(i, sBuffer, sizeof(sBuffer));
				break;
			}
		}
		SetCDOnWinner(sBuffer);
		LogAction(-1, -1, "Mako Vote Stage resetted");
		CPrintToChatAll("{green}[MakoVote] {lime}Only 1 stage left, next stage has set to {darkred}%s", sBuffer);
		g_bOneStageLeft = false;
		for (int i = 0; i <= (TOTALSTAGE - 1); i++)
			g_bStageOnCD[i] = false;
		return Plugin_Handled;
	}
	LogAction(-1, -1, "Mako Vote For Next Round");
	g_bMakoVote = true;
	return Plugin_Handled;
}
public void OnRoundStart(Event hEvent, const char[] sEvent, bool bDontBroadcast){
	if(g_bMakoVote){
		for(int i = 1; i <= MaxClients; i++){
			if(IsClientInGame(i) && IsPlayerAlive(i))
				TeleportEntity(i, g_fVectorPos, NULL_VECTOR, NULL_VECTOR);
		}
		g_bHookSpawn = true;
		int iRelay = INVALID_ENT_REFERENCE;
		while((iRelay = FindEntityByClassname(iRelay, "logic_relay")) != INVALID_ENT_REFERENCE){
			AcceptEntityInput(iRelay, "Disable");
		}
		int iBarrerasfinal2 = FindEntityByTargetname(INVALID_ENT_REFERENCE, "barrerasfinal2", "func_breakable");
		if (iBarrerasfinal2 != INVALID_ENT_REFERENCE){
			AcceptEntityInput(iBarrerasfinal2, "Break");
		}
		int iBarrerasfinal = FindEntityByTargetname(INVALID_ENT_REFERENCE, "barrerasfinal", "prop_dynamic");
		if (iBarrerasfinal != INVALID_ENT_REFERENCE){
			AcceptEntityInput(iBarrerasfinal, "Kill");
		}
		int iLaserTimer = FindEntityByTargetname(INVALID_ENT_REFERENCE, "ex3_laser_timer", "logic_timer");
		if (iLaserTimer != INVALID_ENT_REFERENCE){
			AcceptEntityInput(iLaserTimer, "Enable");
		}
		int iMusic2 = FindEntityByTargetname(INVALID_ENT_REFERENCE, "cancion_2", "ambient_generic");
		if (iMusic2 != INVALID_ENT_REFERENCE){
			AcceptEntityInput(iMusic2, "kill");
		}
		int iButton = FindEntityByTargetname(INVALID_ENT_REFERENCE, "#1918", "func_button");
		if (iButton != INVALID_ENT_REFERENCE){
			AcceptEntityInput(iButton, "lock");
		}
		int iMusic1 = FindEntityByTargetname(INVALID_ENT_REFERENCE, "cancion_1", "ambient_generic");
		if (iMusic1 != INVALID_ENT_REFERENCE){
			SetVariantString("message music/ffvii_tempest.mp3");
			AcceptEntityInput(iMusic1, "AddOutput");
		}
		int iText = FindEntityByTargetname(INVALID_ENT_REFERENCE, "Level_Text", "game_text");
		if (iText != INVALID_ENT_REFERENCE){
			SetVariantString("message Intermission round");
			AcceptEntityInput(iText, "AddOutput");
		}
		int iZone = FindEntityByTargetname(INVALID_ENT_REFERENCE, "race_game_zone", "game_zone_player");
		if (iZone != INVALID_ENT_REFERENCE){
			AcceptEntityInput(iZone, "FireUser1");
		}
		CPrintToChatAll("{green}[MakoVote] {lime}Starting vote in 8s");
		CreateTimer(8.0, tTimerVote);
	}
	CheckStagesLeft();
}
Action tTimerVote(Handle Timer){
	InitVote();
}
public void OnPlayerSpawn(Event hEvent, const char[] sEvent, bool bDontBroadcast){
	if (!g_bMakoVote || !g_bHookSpawn)return;
	int client = GetClientOfUserId(GetEventInt(hEvent,"userid"));
	TeleportEntity(client, g_fVectorPos, NULL_VECTOR, NULL_VECTOR);
}
public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if (IsValidEntity(iEntity))
	{
		SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
	}
}
public void OnEntitySpawned(int iEntity)
{
	if (!g_bMakoVote || !g_bHookSpawn)return;
	char sClassname[128];
	GetEntPropString(iEntity, Prop_Data, "m_iClassname", sClassname, sizeof(sClassname));
	if(StrEqual(sClassname, "trigger_hurt", false)){
		SetVariantString("OnStartTouch !activator:AddOutput:Origin -9356.12 4534.69 99.5:0:-1");
		AcceptEntityInput(iEntity, "AddOutput", 0, 0);
		DispatchKeyValueFloat(iEntity, "damage", 0.0);
	}
}
public void InitVote(){
	if(IsVoteInProgress()){
		CPrintToChatAll("{green}[MakoVote] {lime}Another vote is in progress.");
		CPrintToChatAll("{green}[MakoVote] {lime}Retrying in 5s.");
		CreateTimer(5.0, tTimerVote);
		return;
	}
	if (!g_bIsRevote)GenerateArray();
	g_mVoteMenu = new Menu(hVoteMenu);
	g_mVoteMenu.SetTitle("What Stage to play next?");
	for(int i = 0; i <= (g_aStageList.Length - 1); i++){
		char sBuffer[64];
		g_aStageList.GetString(i, sBuffer, sizeof(sBuffer));
		g_mVoteMenu.AddItem(sBuffer, sBuffer, (g_bStageOnCD[i]) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	}
	//g_mVoteMenu.OptionFlags = MENUFLAG_BUTTON_NOVOTE;
	g_mVoteMenu.VoteResultCallback = hMenu_Result;
	g_mVoteMenu.DisplayVoteToAll(20);
}

public int hVoteMenu(Menu menu, MenuAction action, int param1, int param2){
	switch(action){
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_VoteCancel:
		{
			if(param1 == VoteCancel_NoVotes){
				CPrintToChatAll("{green}[MakoVote] {lime}No vote cast, map will pick stage randomly.");
				char sBuffer[64];
				int iRand = GetRandomInt(0, (g_aStageList.Length - 1));
				g_aStageList.GetString(iRand, sBuffer, sizeof(sBuffer));
				SetCDOnWinner(sBuffer);
				g_bMakoVote = false;
				g_bHookSpawn = false;
				CPrintToChatAll("{green}[MakoVote] {lime}Next stage is: {darkred}%s", sBuffer);
				LogAction(-1, -1, "Picking Stage Randomly : %s", sBuffer);
				CS_TerminateRound(5.0, CSRoundEnd_Draw, false);
			}
		}
	}
}
public void hMenu_Result(Menu menu, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info){
	int highest_votes = item_info[0][VOTEINFO_ITEM_VOTES];
	int required_percent = 60;
	int required_votes = RoundToCeil(float(num_votes) * float(required_percent) / 100);
	if (highest_votes < required_votes && !g_bIsRevote){
		LogAction(-1, -1, "ReVote");
		CPrintToChatAll("{green}[MakoVote] {lime}Vote doesn't met ruquirement, a revote is needed!");
		char sItemBuffer[2][64];
		g_mVoteMenu.GetItem(item_info[0][VOTEINFO_ITEM_INDEX], sItemBuffer[0], sizeof(sItemBuffer[]));
		g_mVoteMenu.GetItem(item_info[1][VOTEINFO_ITEM_INDEX], sItemBuffer[1], sizeof(sItemBuffer[]));
		g_aStageList.Clear();
		g_aStageList.PushString(sItemBuffer[0]);
		g_aStageList.PushString(sItemBuffer[1]);
		g_bIsRevote = true;
		CreateTimer(8.0, tTimerVote);
		return;
	}
	char sStageWinner[64];
	g_mVoteMenu.GetItem(item_info[0][VOTEINFO_ITEM_INDEX], sStageWinner, sizeof(sStageWinner));
	g_bIsRevote = false;
	LogAction(-1, -1, "Stage Winner: %s", sStageWinner);
	CPrintToChatAll("{green}[MakoVote] {lime}Vote Finished! Winner is: {darkred}%s", sStageWinner);
	g_bMakoVote = false;
	g_bHookSpawn = false;
	SetCDOnWinner(sStageWinner);
	CS_TerminateRound(5.0, CSRoundEnd_Draw, false);
}

void ExecuteStage(int iHammerID){
	int iEnt = INVALID_ENT_REFERENCE;
	while((iEnt = FindEntityByClassname(iEnt, "func_button")) != INVALID_ENT_REFERENCE){
		if(GetEntProp(iEnt, Prop_Data, "m_iHammerID") == iHammerID){
			AcceptEntityInput(iEnt, "press", 0, 0);
			break;
		}
	}
}
void SetCDOnWinner(char sStageWinner[64]){
	GenerateArray();
	for(int i = 0; i <= (g_aStageList.Length - 1); i++){
		char sBuffer[64];
		g_aStageList.GetString(i, sBuffer, sizeof(sBuffer));
		if(StrEqual(sBuffer, sStageWinner)){
			ExecuteStage(g_iStageButtonId[i]);
			g_bStageOnCD[i] = true;
			break;
		}
	}
}
void GenerateArray(){
	int iBlockSize = ByteCountToCells(PLATFORM_MAX_PATH);
	g_aStageList = CreateArray(iBlockSize);
	if(g_aStageList.Length > 0)
		g_aStageList.Clear();
	for (int i = 0; i <= (TOTALSTAGE - 1); i++)
		g_aStageList.PushString(g_sStagesList[i]);
}
void CheckStagesLeft(){
	int iCount = 0;
	for(int i = 0; i < TOTALSTAGE; i++){
		if(g_bStageOnCD[i]){
			iCount += 1;
		}
	}
	if((TOTALSTAGE - iCount) == 1){
		g_bOneStageLeft = true;
	}
}
public int FindEntityByTargetname(int entity, const char[] sTargetname, const char[] sClassname)
{
	if(sTargetname[0] == '#') // HammerID
	{
		int HammerID = StringToInt(sTargetname[1]);

		while((entity = FindEntityByClassname(entity, sClassname)) != INVALID_ENT_REFERENCE)
		{
			if(GetEntProp(entity, Prop_Data, "m_iHammerID") == HammerID)
				return entity;
		}
	}
	else // Targetname
	{
		int Wildcard = FindCharInString(sTargetname, '*');
		char sTargetnameBuf[64];

		while((entity = FindEntityByClassname(entity, sClassname)) != INVALID_ENT_REFERENCE)
		{
			if(GetEntPropString(entity, Prop_Data, "m_iName", sTargetnameBuf, sizeof(sTargetnameBuf)) <= 0)
				continue;

			if(strncmp(sTargetnameBuf, sTargetname, Wildcard) == 0)
				return entity;
		}
	}
	return INVALID_ENT_REFERENCE;
}