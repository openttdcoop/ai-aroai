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
	make sure versions are same (main.nut, info.nut & makefile)
	update changelog
	run makefile

MINOR TODO: (x.x.x++)
	extra debugs
	properly manageonly when no towns left to build in
	less debugs while not enough money for road
	merge BuildDepot() and BuildBusStation()
	simplify Builder_BusRoute.Main()
	deal with company merger ask

MAIN TODO: (x.x++.x) (in rough order)
	re-write town-finder (currently ignoring towns that have ben built through)
	save/load support
	remove failed bus stops (and depots)
	better vehicle+cargo selector (think NoCAB)
	add check for towns being pre-connected (see wiki)
	add time limit for pathfinding
	add configurable no. of buses per town
	autoreplace
	make stations build properly adjacent
	respect town road layout

WISHFUL THINKING TODO: (x++.x.x) (in rough order)
	air support
	road cargo support
	rail support
		Double rail support
		Rail networks
	ship support
	write own pathfinders (road first)

	6.x.x by end :)
*/
import("pathfinder.road", "RoadPathFinder", 3);
require("vehiclemanager.nut");
require("builder_busroute.nut");
require("manager.nut");
require("util.nut");

class AroAI extends AIController
	{
		aiversion = "1.1.0(r72)";
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
		while(true) //Keep running. If Start() exits, the AI dies
		{
			this.Sleep(1);
			Warning("Main loop started");
			Manager.ManageLoan();
			Manager.ManageEvents();
//			Debug("manageOnly = " + Builder_BusRoute.manageOnly);
			if(Builder_BusRoute.manageOnly == false)
			{
				local vehList = AIVehicleList();
				vehList.Valuate(AIVehicle.GetVehicleType);
				vehList.KeepValue(AIVehicle.VT_ROAD);
				local numOfVehs = vehList.Count();
				if(AIGameSettings.GetValue("vehicle.max_roadveh") <=  numOfVehs)
				{
					Info("Max amount of road vehicles reached");
					Builder_BusRoute.manageOnly = true;
				}
				else
				{
					Builder_BusRoute.Main();
				}
			}
			else
			{
				Info("Sleeping because there is nothing to build");
				this.Sleep(500);
			}
		}
	}

function AroAI::Stop()
	{
		Error("Something gone wrong. Clearing all signs");
		Util.ClearAllSigns();
		Error("Stopped");
		Warning("(The error is on purpose)");
		local var = 1/0;
 	}

function AroAI::Save()
	{
		Warning("TODO: Add Save/Load functionality");
		local table = {}; //TODO: Add save data to the table.
			return table;
	}

function AroAI::Load(version, data)
	{
		//TODO: Add loading routines.
	}

function AroAI::SetCompany()
	{
		local a = AIBase.RandRange(15);
		if (0==a)   {AICompany.SetName("Arioa International");}
		if (1==a)   {AICompany.SetName("AroAI");}
		if (2==a)   {AICompany.SetName("Aro Transport");}
		if (3==a)   {AICompany.SetName("Aro & Co.");}
		if (4==a)   {AICompany.SetName("Aro");}
		if (5==a)   {AICompany.SetName("Aro Distribution");}
		if (6==a)   {AICompany.SetName("Aro Logistics");}
		if (7==a)   {AICompany.SetName("Aro Federal Delivery");}
		if (8==a)   {AICompany.SetName("Aro Ltd.");}
		if (9==a)   {AICompany.SetName("Aro Delivery");}
		if (10==a)  {AICompany.SetName("Aro Network");}
		if (11==a)  {AICompany.SetName("Aro Trans");}
		if (12==a)  {AICompany.SetName("Aro Services");}
		if (13==a)  {AICompany.SetName("Aro Management");}
		if (14==a)  {AICompany.SetName("Aro Constructions");}
		Info(AICompany.GetName(AICompany.COMPANY_SELF) + " inaugurated");

		AICompany.SetPresidentGender(0);
		AICompany.SetPresidentName("Lord Aro");
		Info(AICompany.GetPresidentName(AICompany.COMPANY_SELF) + " is the new president");

		AICompany.SetAutoRenewStatus(true);
		AICompany.SetAutoRenewMonths(-3);
		AICompany.SetAutoRenewMoney(0);
		BuildHQ();
	}

function AroAI::GetVersionsAndStuff()
	{
		Info("AroAI v" + aiversion + " by Charles Pigott (Lord Aro) started");
		Info("Special thanks to those who helped with the many problems had when making the AI")
		local version = GetVersion();
		Info("Currently playing on OpenTTD version " + ((version & (15 << 28)) >> 28) + "." +
		((version & (15 << 24)) >> 24) + "." + ((version & (15 << 20)) >> 20) + "" + 
		(((version & (1 << 19)) >> 19)?" stable release, ":" r") + ((version & ((1 << 18) - 1))));
		AILog.Info("=======================================")
	}

function AroAI::BuildHQ() //from Rondje
	{
		if(AIMap.IsValidTile(AICompany.GetCompanyHQ(AICompany.COMPANY_SELF))) //from simpleai
			return;

		//Find second biggest town for HQ, just to be different :p
		local towns = AITownList();
		local HQtown = 0;
		towns.Valuate(AITown.GetPopulation);
		towns.Sort(AIList.SORT_BY_VALUE, false);
		if(towns.Count == 1)
		{
			HQtown = towns.Begin();
		}
		else
		{
			towns.RemoveTop(1);
			HQtown = towns.Begin();
		}

		//Find empty 2x2 square as close to town centre as possible
		local maxRange = Util.Sqrt(AITown.GetPopulation(HQtown)/100) + 5;
		local HQArea = AITileList();

		HQArea.AddRectangle(AITown.GetLocation(HQtown) - AIMap.GetTileIndex(maxRange, maxRange), AITown.GetLocation(HQtown) + AIMap.GetTileIndex(maxRange, maxRange));
		HQArea.Valuate(AITile.IsBuildableRectangle, 2, 2);
		HQArea.KeepValue(1);
		HQArea.Valuate(AIMap.DistanceManhattan, AITown.GetLocation(HQtown));
		HQArea.Sort(AIList.SORT_BY_VALUE, true);
		for (local tile = HQArea.Begin(); !HQArea.IsEnd(); tile = HQArea.Next()) 
		{
			if (AICompany.BuildCompanyHQ(tile)) 
			{
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
