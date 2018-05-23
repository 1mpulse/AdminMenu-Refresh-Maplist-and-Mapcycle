#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <adminmenu>

int iHowMaps;
char sPathMapcycle[] = "mapcycle.txt", sPathMaplist[] = "maplist.txt";
ArrayList g_hMaps;
TopMenu g_hAdminMenu = null;

public Plugin myinfo =
{
	name = "[Admin Menu] Refresh Maplist and Mapcycle",
	author = "1mpulse (skype:potapovdima1)",
	version = "1.0.1",
	url = "http://plugins.thebestcsgo.ru"
};

public void OnPluginStart()
{
	g_hMaps = new ArrayList(ByteCountToCells(128));
	TopMenu hTopMenu;
	if((hTopMenu = GetAdminTopMenu()) != null) OnAdminMenuReady(hTopMenu);
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu hTopMenu = TopMenu.FromHandle(aTopMenu);
	if(hTopMenu == g_hAdminMenu) return;
	g_hAdminMenu = hTopMenu;
	TopMenuObject hMyCategory = g_hAdminMenu.FindCategory("ServerCommands");
	if(hMyCategory != INVALID_TOPMENUOBJECT)
	{
		g_hAdminMenu.AddItem("sm_refresh_maplist_item", MenuCallBack1, hMyCategory, "sm_refresh_maplist_menu", ADMFLAG_ROOT, "Обновить Maplist и Mapcycle");
	}
}

public void MenuCallBack1(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, maxlength, "Обновить Maplist и Mapcycle");
		case TopMenuAction_SelectOption: StartRefresh(iClient);
	}
}

void StartRefresh(int iClient)
{
	char sMap[128], szBuffer[128];
	iHowMaps = 0;
	if(FileExists(sPathMapcycle))
	{
		DeleteFile(sPathMapcycle);
		CloseHandle(CreateFile(sPathMapcycle, "a"));
	}
	if(FileExists(sPathMaplist))
	{
		DeleteFile(sPathMaplist);
		CloseHandle(CreateFile(sPathMaplist, "a"));
	}
	
	DirectoryListing hMaps = OpenDirectory("maps");
	if(hMaps)
	{
		FileType type;
		while(hMaps.GetNext(sMap, sizeof(sMap), type))
		{
			if(type == FileType_File && StrEqual(sMap, ".bsp", true))
			{
				ReplaceString(sMap, sizeof(sMap), ".bsp", "", false);
				g_hMaps.PushString(sMap);
				iHowMaps++;
			}
		}
		delete hMaps;
	}
	
	File hFileMaplist = OpenFile(sPathMaplist, "at");
	File hFileMapcycle = OpenFile(sPathMapcycle, "at");
	if(hFileMaplist && hFileMapcycle)
	{
		for(int i = 0; i < iHowMaps; i++)
		{
			g_hMaps.GetString(i, szBuffer, sizeof(szBuffer));
			hFileMaplist.WriteLine(szBuffer);
			hFileMapcycle.WriteLine(szBuffer);
		}
		delete hFileMaplist;
		delete hFileMapcycle;
	}
	PrintToChat(iClient, "Списки успешно обновлены!");
	g_hAdminMenu.Display(iClient, TopMenuPosition_LastCategory);
}

stock Handle CreateFile(const char[] path, const char[] mode = "w+")
{
	char dir[8][PLATFORM_MAX_PATH];
	int count = ExplodeString(path, "/", dir, 8, sizeof(dir[]));
	for(int i = 0; i < count-1; i++)
	{
		if(i > 0)
			Format(dir[i], sizeof(dir[]), "%s/%s", dir[i-1], dir[i]);
			
		if(!DirExists(dir[i]))
			CreateDirectory(dir[i], 511);
	}
	
	return OpenFile(path, mode);
}