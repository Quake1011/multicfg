#include <sourcemod>

Database gDatabase;
KeyValues kv;
int gcounter;
Handle repeater;

public Plugin myinfo = 
{
	name = "Multi CFG",
	author = "Quake1011",
	description = "Mode selector by menu",
	version = "0.5",
	url = "https://github.com/Quake1011/"
}

public void OnPluginStart()
{
	
	if(!SQL_CheckConfig("multicfg"))
	{
		SetFailState("Not found section \"multicfg\" in databases.cfg");
		return;
	}

	char sBuffer[PLATFORM_MAX_PATH];
	gcounter = 30;
	
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "configs/multimode.ini");
	kv = CreateKeyValues("Settings");

	if(!kv.ImportFromFile(sBuffer)) return;
	
	Database.Connect(SQLCallBack, "multicfg");
	
	RegAdminCmd("sm_multi", CommandMultiMode, ADMFLAG_ROOT);
}

public void SQLCallBack(Database db, const char[] error, any data)
{
	if(db == INVALID_HANDLE || error[0])
	{
		SetFailState("Error connect database: %s", error);
		return;
	}
	
	gDatabase = db;
	
	char sQuery[256], ModeInDb[64];
	SQL_FormatQuery(gDatabase, sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `multimode` (`active` INTEGER(10) NOT NULL, `mode` VARCHAR(64) NOT NULL PRIMARY KEY)");
	SQL_FastQuery(gDatabase, sQuery);
	
	kv.Rewind();
	if(kv.GotoFirstSubKey())
	{
		do
		{
			kv.GetSectionName(ModeInDb, sizeof(ModeInDb));
			SQL_FormatQuery(gDatabase, sQuery, sizeof(sQuery), "INSERT INTO `multimode` (`active`, `mode`) VALUES ('0', '%s')", ModeInDb);
			SQL_FastQuery(gDatabase, sQuery);
		} while(kv.GotoNextKey());
	}
}

public void OnConfigsExecuted()
{
	CreateTimer(2.0, LoadConfig);
}

public Action LoadConfig(Handle hTimer)
{
	char sQuery[256], ActiveMode[64];
	SQL_FormatQuery(gDatabase, sQuery, sizeof(sQuery), "SELECT * FROM `multimode` WHERE `active`='1'");
	
	DBResultSet result = SQL_Query(gDatabase, sQuery);
	
	if(result == INVALID_HANDLE || !result.HasResults)
	{
		SetFailState("Can`t select from database OnConfigExec");
		delete result;
	}
	
	else if(result.RowCount != 0 && result.FetchRow())
	{
		result.FetchString(1, ActiveMode, sizeof(ActiveMode));
		delete result;
		
		char map[256], section[256];
		GetCurrentMap(map, sizeof(map));
		
		kv.Rewind();
		if(kv.JumpToKey(ActiveMode) && kv.GotoFirstSubKey())
		{
			do
			{
				kv.GetSectionName(section, sizeof(section));
				if(StrEqual("variables", section, false))
				{
					for(int i = 0; i <= 1024; i++)
					{
						char temp[8];
						IntToString(i, temp, sizeof(temp));
						kv.GetString(temp, section, sizeof(section));
						if(section[0] != '\0') ServerCommand(section);
						else break;
					}
				}
				if(StrEqual("unload", section, false))
				{
					for(int i = 0; i <= 1024; i++)
					{
						char temp[8];
						IntToString(i, temp, sizeof(temp));
						kv.GetString(temp, section, sizeof(section));
						if(section[0] != '\0') ServerCommand("sm plugins unload %s", section);
						else break;
					}
				}
				if(StrEqual("configs", section, false))
				{
					for(int i = 0; i <= 1024; i++)
					{
						char temp[8];
						IntToString(i, temp, sizeof(temp));
						kv.GetString(temp, section, sizeof(section));
						if(section[0] != '\0') ServerCommand("exec %s", section);
						else break;
					}
				}
			} while(kv.GotoNextKey());			
		}
	
		SQL_FormatQuery(gDatabase, sQuery, sizeof(sQuery), "UPDATE `multimode` SET `active`='0' WHERE `mode`='%s'", ActiveMode);
		SQL_FastQuery(gDatabase, sQuery);
	}
	
	return Plugin_Continue;
}

public Action CommandMultiMode(int client, int args)
{
	char mode[64]
	kv.Rewind();
	if(kv.GotoFirstSubKey())
	{
		Menu hMenu = CreateMenu(MainMenuMulti);
		hMenu.SetTitle("MultiMode");
		do 
		{
			kv.GetSectionName(mode, sizeof(mode));
			hMenu.AddItem(mode, mode);  
		} while(kv.GotoNextKey());
		
		hMenu.ExitButton = true;
		hMenu.Display(client, 0);	
	}
	
	return Plugin_Handled;
}

public int MainMenuMulti(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			char info[64];
			menu.GetItem(item, info, sizeof(info));
			LookAtMaps(info, client);
		}
	}
	return 0;
}

public void LookAtMaps(char[] ModeName, int client)
{
	char section[MAX_NAME_LENGTH];
	kv.Rewind();
	if(kv.JumpToKey(ModeName) && kv.JumpToKey("maps"))
	{
		Menu hMenu = CreateMenu(MapsMenu);
		hMenu.SetTitle(ModeName);
		for(int i = 0; i <= 64; i++)
		{
			char map[8];
			IntToString(i, map, sizeof(map));
			kv.GetString(map, section, sizeof(section));
			if(section[0] != '\0') hMenu.AddItem(section, section);
			else break;
		}

		hMenu.ExitBackButton = true;
		hMenu.ExitButton = true;
		hMenu.Display(client, 0);			
	}
}

public int MapsMenu(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel: 
		{
			char mode[64]
			kv.Rewind();
			if(kv.GotoFirstSubKey())
			{
				Menu hMenu = CreateMenu(MainMenuMulti);
				hMenu.SetTitle("MultiMode");
				do 
				{
					kv.GetSectionName(mode, sizeof(mode));
					hMenu.AddItem(mode, mode);  
				} while(kv.GotoNextKey());
				hMenu.ExitButton = true;
				hMenu.Display(client, 0);				
			}
		}        
		case MenuAction_Select:
		{
			char info[64], sQuery[256], map[256];
			
			menu.GetTitle(map, sizeof(map));
			menu.GetItem(item, info, sizeof(info));
			
			Format(info, sizeof(info), "map %s", info);
			SQL_FormatQuery(gDatabase, sQuery, sizeof(sQuery), "UPDATE `multimode` SET `active`='1' WHERE `mode`='%s'", map);
			
			DataPack dp = CreateDataPack();
			
			CreateTimer(30.0, Execution, dp);
			repeater = CreateTimer(1.0, Advert, TIMER_REPEAT);
			
			dp.WriteString(info);
			dp.WriteString(sQuery);
		}
	}
	return 0;
}

public Action Advert(Handle hTimer)
{
	if(gcounter == 30 || gcounter == 20 || gcounter == 10 || gcounter < 10) PrintCenterTextAll("Режим сменится через: %i секунд", gcounter);
	gcounter = --gcounter;
	
	return Plugin_Continue;
}

public Action Execution(Handle hTimer, any dp)
{
	gcounter = 30;
	char sQuery[256], cmd[256];
	DataPack hPack = view_as<DataPack>(dp);
	
	hPack.Reset();
	hPack.ReadString(cmd, sizeof(cmd));
	hPack.ReadString(sQuery, sizeof(sQuery));
	delete hPack;

	SQL_FastQuery(gDatabase, sQuery);
	ServerCommand(cmd);
	
	return Plugin_Continue;
}

public void OnMapEnd()
{
	if(repeater != INVALID_HANDLE)
	{
		KillTimer(repeater);
		repeater = null;
	}
}
