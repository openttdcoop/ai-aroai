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

/*
BEFORE RELEASE CHECK:
	run stress test - check for no crashes
	update readme & changelog
	run makefile
*/

import("pathfinder.road", "RoadPathFinder", 3);
require("vehiclemanager.nut");
require("builder_busroute.nut");
require("manager.nut");
require("util.nut");
require("version.nut");

class AroAI extends AIController
{
	AI_VERSION = "Version: " + _major_ver + "." + _minor_ver + " Rev: " + _repos_ver;

	AUTO_RENEW_MONEY = 0;		///< Amount of money to have before starting autorenew
	AUTO_RENEW_MONTHS = -6;		///< Before/after max age of a vehicle to autorenew
	MANAGE_ONLY_SLEEP_TIME = 1000;	///< Time sleeping when managing only

	constructor()
	{
		Builder_BusRoute = Builder_BusRoute();
		VehicleManager = VehicleManager();
		Manager = Manager();
		Util = Util();
	}
}

function AroAI::Start()
{
	this.Sleep(1);
	GetVersionsAndStuff();
	SetCompany(); //Set company stuff
	while (true) { //Keep running. If Start() exits, the AI dies
		this.Sleep(1);
		Warning("Main loop started");
		Manager.ManageLoan();
		Manager.ManageEvents();
		if (!Builder_BusRoute.manageOnly) {
			local vehList = AIVehicleList();
			vehList.Valuate(AIVehicle.GetVehicleType);
			vehList.KeepValue(AIVehicle.VT_ROAD);
			local maxVehs = vehList.Count();
			if (AIGameSettings.GetValue("vehicle.max_roadveh") <=  maxVehs) {
				Info("Max amount of road vehicles reached");
				Builder_BusRoute.manageOnly = true;
			} else {
				Builder_BusRoute.Main();
			}
		} else {
			Info("Sleeping because there is nothing to build");
			this.Sleep(MANAGE_ONLY_SLEEP_TIME);
		}
	}
}

function AroAI::Stop()
{
	Error("Something gone wrong. Clearing all signs");
	Util.ClearAllSigns();
	Error("Stopped");
	Warning("(The error is on purpose)");
	local crash = 1/0
}

function AroAI::Save()
{
	Warning("TODO: Add Save/Load functionality");
	local table = {}; //TODO: Add save data to the table...maybe
	return table;
}

function AroAI::Load(version, data)
{
	//TODO: Add loading routines...maybe
}

function AroAI::SetCompany()
{ //TODO: More names, just to make sure it's always unique
	local a = AIBase.RandRange(15);
	switch (a) {
		case 0:
			AICompany.SetName("Arioa International");
			break;
		case 1:
			AICompany.SetName("AroAI");
			break;
		case 2:
			AICompany.SetName("Aro Transport");
			break;
		case 3:
			AICompany.SetName("Aro & Co.");
			break;
		case 4:
			AICompany.SetName("Aro");
			break;
		case 5:
			AICompany.SetName("Aro Distribution");
			break;
		case 6:
			AICompany.SetName("Aro Logistics");
			break;
		case 7:
			AICompany.SetName("Aro Federal Delivery");
			break;
		case 8:
			AICompany.SetName("Aro Ltd.");
			break;
		case 9:
			AICompany.SetName("Aro Delivery");
			break;
		case 10:
			AICompany.SetName("Aro Network");
			break;
		case 11:
			AICompany.SetName("Aro Trans");
			break;
		case 12:
			AICompany.SetName("Aro Services");
			break;
		case 13:
			AICompany.SetName("Aro Management");
			break;
		case 14:
			AICompany.SetName("Aro Constructions");
			break;
	}
	Info(AICompany.GetName(AICompany.COMPANY_SELF) + " inaugurated");
	
	AICompany.SetPresidentGender(0);
	AICompany.SetPresidentName("Lord Aro");
	Info(AICompany.GetPresidentName(AICompany.COMPANY_SELF) + " is the new president");
	
	AICompany.SetAutoRenewMonths(AUTO_RENEW_MONTHS);
	AICompany.SetAutoRenewMoney(AUTO_RENEW_MONEY);
	AICompany.SetAutoRenewStatus(true);
	
	BuildHQ();
}

function AroAI::GetVersionsAndStuff()
{
	Info("AroAI v" + AI_VERSION + " by Charles Pigott (Lord Aro) started");
	Info("Special thanks to those who helped with the many problems had when making the AI")
	local version = GetVersion();
	Info("Currently playing on OpenTTD version " + ((version & (15 << 28)) >> 28) + "." +
		((version & (15 << 24)) >> 24) + "." + ((version & (15 << 20)) >> 20) + "" + 
		(((version & (1 << 19)) >> 19)?" stable release, ":" r") + ((version & ((1 << 18) - 1))));
	AILog.Info("=======================================")
}

function AroAI::BuildHQ() //From Rondje
{
	if (AIMap.IsValidTile(AICompany.GetCompanyHQ(AICompany.COMPANY_SELF))) return; //From SimpleAI

	/* Find SECOND biggest town for HQ, just to be different */
	local towns = AITownList();
	local HQtown = 0;
	towns.Valuate(AITown.GetPopulation);
	towns.Sort(AIList.SORT_BY_VALUE, false);
	if (towns.Count == 1) {
		HQtown = towns.Begin();
	} else {
		towns.RemoveTop(1);
		HQtown = towns.Begin();
	}

	/* Find empty 2x2 square as close to town centre as possible */
	local maxRange = Util.Sqrt(AITown.GetPopulation(HQtown)/100) + 5;
	local HQArea = AITileList();

	HQArea.AddRectangle(AITown.GetLocation(HQtown) - AIMap.GetTileIndex(maxRange, maxRange), AITown.GetLocation(HQtown) + AIMap.GetTileIndex(maxRange, maxRange));
	HQArea.Valuate(AITile.IsBuildableRectangle, 2, 2);
	HQArea.KeepValue(1);
	HQArea.Valuate(AIMap.DistanceManhattan, AITown.GetLocation(HQtown));
	HQArea.Sort(AIList.SORT_BY_VALUE, true);
	for (local tile = HQArea.Begin(); !HQArea.IsEnd(); tile = HQArea.Next()) {
		if (AICompany.BuildCompanyHQ(tile)) {
			AISign.BuildSign(tile, "AroAI HQ");
			Info("HQ building completed");
			return;
		}
	}
	Warning("No possible HQ location found");
}

function AroAI::Info(string)
{
	AILog.Info(Util.GameDate() + " [AroAI] " + string + ".");
}

function AroAI::Warning(string)
{
	AILog.Warning(Util.GameDate() + " [AroAI] " + string + ".");
}

function AroAI::Error(string)
{
	AILog.Error(Util.GameDate() + " [AroAI] " + string + ".");
}

function AroAI::Debug(string)
{
	AILog.Warning(Util.GameDate() + " [AroAI] DEBUG: " + string + ".");
	AILog.Warning(Util.GameDate() + " [AroAI] (if you see this, please inform the AI Dev in charge, as it was supposed to be removed before release)");
}
