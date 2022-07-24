#include <sourcemod>

int gModes;

Database gDatabase;

KeyValues kv;

public void OnPluginStart()
{
    SQL_CheckConfig("MultiMode");
    Database.Connect(SQLCallBack, "MultiMode");

    char buffer[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, buffer, sizeof(buffer), "configs/multimode.ini");
    kv = CreateKeyValues("Settings");
    kv.ImportFromFile(buffer);

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
    Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `multimode` (`active` INTEGER(10) NOT NULL PRIMARY KEY)");
    SQL_Query(gDatabase, sQuery);
}

public void OnMapStart()
{
    char sQuery[256];
    Format(sQuery, sizeof(sQuery), "SELECT * FROM `multimode` WHERE `active`='1'");
    DBResultSet result = SQL_Query(gDatabase, sQuery);
    int activated;
    if(result != INVALID_HANDLE && result.HasResults)
    {
        result.FetchRow();
        activated = result.FetchInt(0);
    }
    delete result;
    if(activated == 1)
    {
        char map[256];
        GetCurrentMap(map, sizeof(map));
        kv.Rewind();
        kv.GotoFirstSubKey();
        kv.JumpToKey("maps");
        kv.GotoFirstSubKey();
        char section[MAX_NAME_LENGTH];
        do {
            kv.GetSectionName(section, sizeof(section));
            if(strcmp(map, section, true))
            {
                kv.GoBack();
                do {
                    kv.GetSectionName(section, sizeof(section))
                    char setting[256], buffer[256];
                    if(strcmp(section, "variables", true) || strcmp(section, "gametype", true) || strcmp(section, "gamemode", true))
                    {
                        kv.GotoFirstSubKey();
                        do {
                            kv.GetSectionName(setting, sizeof(setting));
                            ServerCommand(setting);
                        } while(kv.GotoNextKey())
                        kv.GoBack();
                    }
                    else if(strcmp(section, "plugins", true))
                    {
                        kv.GotoFirstSubKey();
                        do {
                            kv.GetSectionName(setting, sizeof(setting));
                            Format(buffer, sizeof(buffer), "sm plugins unload %s", setting);
                            ServerCommand(buffer);
                        } while(kv.GotoNextKey())
                        kv.GoBack();
                    }
                    else if(strcmp(section, "config", true))
                    {
                        kv.GotoFirstSubKey();
                        do {
                            kv.GetSectionName(setting, sizeof(setting));
                            Format(buffer, sizeof(buffer), "exec %s", setting);
                            ServerCommand(buffer);
                        } while(kv.GotoNextKey())
                        kv.GoBack();
                    }
                } while(kv.GotoNextKey())
                break;
            }
        } while(kv.GotoNextKey());        
    }
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
        gModes++;    
    } while(kv.GotoNextKey());
    hMenu.ExitBackButton = true;
    hMenu.ExitButton = true;
    hMenu.Display(client, 0);
}

public int MainMenuMulti(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[2][64];
            int istyle;
            GetMenuItem(menu, item, info[0], sizeof(info), istyle, info[1], sizeof(info));
            LookAtMaps(info[0], client);
        }
        case MenuAction_End: delete menu;
    }
}

public void LookAtMaps(char[] ModeName, int client)
{
    kv.Rewind();
    kv.JumpToKey(ModeName);
    kv.JumpToKey("maps");
    kv.GotoFirstSubKey();
    Menu hMenu = CreateMenu(MapsMenu);
    hMenu.SetTitle("Maps");
    char section[MAX_NAME_LENGTH];
    do {
        kv.GetSectionName(section, sizeof(section));
        hMenu.AddItem(section, section);
    } while(kv.GotoNextKey())
    hMenu.ExitBackButton = true;
    hMenu.ExitButton = true;
    hMenu.Display(client, 0);
}

public int MapsMenu(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[2][64], sQuery[256];
            int istyle, count;
            menu.GetItem(item, info[0], sizeof(info), istyle, info[1], sizeof(info));
            Format(sQuery, sizeof(sQuery), "map %s", info[0]);
            ServerCommand(sQuery);
            Format(sQuery, sizeof(sQuery), "SELECT * FROM `multimode` WHERE `active`='1' OR `active`='0'");
            DBResultSet result = SQL_Query(gDatabase, sQuery);
            if(result != INVALID_HANDLE && result.HasResults) count = result.RowCount;
            delete result;
            if(count == 0) Format(sQuery, sizeof(sQuery), "INSERT INTO `multimode` (`active`) VALUES ('1')");
            else if(count == 1) Format(sQuery, sizeof(sQuery), "UPDATE `multimode` SET `active`='1' WHERE `active`='0'");
            SQL_Query(gDatabase, sQuery);
        }
        case MenuAction_End: delete menu;
    }
}