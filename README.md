# Multi CFG
***The plugin allows you to change and set the game mode right during the match using a configurable configuration file***

## Requirements
 - MYSQL or SQLITE

## Setup
1) Move all files according to the current directories. 
2) Add **"multicfg"** section in configuration file **addons/sourcemod/configs/database.cfg**:
```
"multicfg"
{
  "driver"      "mysql"
  "host"	"255.255.255.255"
  "database"	"dbname"
  "user"	"dbuser"
  "pass"	"password"
}
```
3) To configure **multimode.ini** for yourself in the source code before compilation or after file generation
4) Compile **Multicfg.sp** and move it to the **plugins** folder
5) Restart a server
## Commands 
- **sm_multi** - Select mode and map for **(ROOT)**

## Thanks
- [Trekken](https://hlmod.ru/members/trekken.132185/) (tests & ideas)

## About possible problems, please let me know: 
- Quake#2601 - DISCORD
- [HLMOD](https://hlmod.ru/members/palonez.92448/)
- [STEAM](https://steamcommunity.com/id/comecamecame/)
