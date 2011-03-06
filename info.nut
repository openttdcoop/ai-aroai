/*
 * This file is part of AroAI
 *
 * Copyright (C) 2010 - Charles Pigott (Lord Aro)
 *
 * AroAI is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * AroAI is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with AroAI; if not, see <http://www.gnu.org/licenses/> or
 * write to the Free Software Foundation, Inc., 51 Franklin St,
 * Fifth Floor, Boston, MA  02110-1301  USA
 */

require("version.nut");

class AroAI extends AIInfo
{
	function GetAuthor()      {return "Charles Pigott (Lord Aro)";}
	function GetName()        {return "AroAI";}
	function GetDescription() {return "Lord Aro's really feeble attempt at making an AI. Currently buses only. Version: " + _major_ver + "." + _minor_ver + "." + _repos_ver;}
	function GetVersion()     {return  _repos_ver;}
	function GetDate()        {return "2010-10-03";}
	function CreateInstance() {return "AroAI";}
//	function UseAsRandomAI()  {return  false;}
	function GetShortName()   {return "A_AI";}
	function GetAPIVersion()  {return "1.1";}
	function GetURL()         {return "http://www.tt-forums.net/viewtopic.php?t=49496/ OR http://dev.openttdcoop.org/projects/ai-aroai/";}
	function GetSettings()
	{
		AddSetting({
			name = "enable_road_vehs",
			description = "Enable road vehicles",
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = AICONFIG_BOOLEAN
			});
	}
}
/* Tell the core we are an AI */
RegisterAI(AroAI());
