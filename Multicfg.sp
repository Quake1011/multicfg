#include <sourcemod>

Database gDatabase;

KeyValues kv;

public void OnPluginStart()
{
    if(!SQL_CheckConfig("multicfg"))
    {
        SetFailState("Not found section \"multicfg\" in databases.cfg");
        return;
    }

    char buffer[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, buffer, sizeof(buffer), "configs/multimode.ini");
    kv = CreateKeyValues("Settings");
    kv.ImportFromFile(buffer);
    Database.Connect(SQLCallBack, "multicfg");
    RegConsoleCmd("sm_multi", CommandMultiMode);
}

public void SQLCallBack(Database db, const char[] error, any data)
{
    if(db == INVALID_HANDLE || error[0])
    {
        SetFailState("Error connect database: %s", error);
        return;
    }

    gDatabase = db;

    char sQuery[256];
    Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `multimode` (`active` INTEGER(10) NOT NULL, `mode` VARCHAR(64) NOT NULL PRIMARY KEY)");
    SQL_Query(gDatabase, sQuery);

    kv.Rewind();
    char ModeInDb[64];
    kv.GotoFirstSubKey();
    do{
        kv.GetSectionName(ModeInDb, sizeof(ModeInDb));
        Format(sQuery, sizeof(sQuery), "INSERT INTO `multimode` (`active`, `mode`) VALUES ('0', '%s')", ModeInDb);
        SQL_LockDatabase(gDatabase);
        SQL_Query(gDatabase, sQuery);
        SQL_UnlockDatabase(gDatabase);
    } while(kv.GotoNextKey())
}

public void OnConfigsExecuted()
{
    CreateTimer(2.0, LoadConfig);
}

public Action LoadConfig(Handle hTimer)
{
    char sQuery[256], ActiveMode[64];
    Format(sQuery, sizeof(sQuery), "SELECT * FROM `multimode` WHERE `active`='1'");

    DBResultSet result = SQL_Query(gDatabase, sQuery);
    
    if(result == INVALID_HANDLE || !result.HasResults)
    {
        SetFailState("can`t select from database OnConfigExec");
        delete result;
        return Plugin_Stop;
    }

    if(result.RowCount != 0)
    {
        result.FetchRow();
        result.FetchString(1, ActiveMode, sizeof(ActiveMode));
        delete result;
        char map[256], section[256];
        GetCurrentMap(map, sizeof(map));
        kv.Rewind();
        if(kv.JumpToKey(ActiveMode))
        {
            kv.GotoFirstSubKey();
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
            } while(kv.GotoNextKey())
        }

        Format(sQuery, sizeof(sQuery), "UPDATE `multimode` SET `active`='0' WHERE `mode`='%s'", ActiveMode);
        SQL_Query(gDatabase, sQuery);
    }
    delete result
    return Plugin_Continue;
}

public Action CommandMultiMode(int client, int args)
{
    char mode[64]
    kv.Rewind();
    kv.GotoFirstSubKey();
    Menu hMenu = CreateMenu(MainMenuMulti);
    hMenu.SetTitle("MultiMode");
    do {
        kv.GetSectionName(mode, sizeof(mode));
        hMenu.AddItem(mode, mode);  
    } while(kv.GotoNextKey());
    hMenu.ExitButton = true;
    hMenu.Display(client, 0);

    return Plugin_Continue;
}

public int MainMenuMulti(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[2][64];
            int istyle;
            GetMenuItem(menu, item, info[0], 64, istyle, info[1], 64);
            LookAtMaps(info[0], client);
        }
        case MenuAction_End: delete menu;
    }
    return 0;
}

public void LookAtMaps(char[] ModeName, int client)
{
    char section[MAX_NAME_LENGTH];
    kv.Rewind();
    kv.JumpToKey(ModeName);
    kv.JumpToKey("maps");
    Menu hMenu = CreateMenu(MapsMenu);
    hMenu.SetTitle(ModeName);
    for(int i = 0; i <= 64; i++)
    {
        char map[8];
        IntToString(i, map, sizeof(map));
        kv.GetString(map, section, sizeof(section));
        if(section[0] != '\0') 
        {
            hMenu.AddItem(section, section);
        }
        else break;
    }

    hMenu.ExitBackButton = true;
    hMenu.ExitButton = true;
    hMenu.Display(client, 0);
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
            kv.GotoFirstSubKey();
            Menu hdsMenu = CreateMenu(MainMenuMulti);
            hdsMenu.SetTitle("MultiMode");
            do {
                kv.GetSectionName(mode, sizeof(mode));
                hdsMenu.AddItem(mode, mode);  
            } while(kv.GotoNextKey());
            hdsMenu.ExitButton = true;
            hdsMenu.Display(client, 0);
        }        
        case MenuAction_Select:
        {
            char info[2][64], sQuery[256];
            int istyle;
            char map[256];
            menu.GetTitle(map, sizeof(map));
            menu.GetItem(item, info[0], 64, istyle, info[1], 64);
            Format(sQuery, sizeof(sQuery), "map %s", info[0]);
            ServerCommand(sQuery);

			Format(sQuery, sizeof(sQuery), "UPDATE `multimode` SET `active`='1' WHERE `mode`='%s'", map);
			SQL_Query(gDatabase, sQuery);
        }
    }
    return 0;
}
