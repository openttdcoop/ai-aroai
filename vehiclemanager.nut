/*
 * vehiclemanager.nut
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

class VehicleManager
	{
		function BuildBusEngines(depot_tile, town_start, town_end);
		function SelectVehicles(cargo_id);
		function DealWithBuildVehicleErrors(err);
		
		engine = -1;
	}

function VehicleManager::BuildBusEngines(depot_tile, town_start, town_end)
	{
		Info("Using a " + AIEngine.GetName(VehicleManager.SelectVehicles(AICargo.CC_PASSENGERS)) + " to carry passengers");
//		Debug("depot_tile = " + depot_tile);
//		Debug("engine = " + engine);

		local town_start_id = AITile.GetClosestTown(town_start);
		Info("Buying buses in " + AITown.GetName(town_start_id));

		local vehicle_id = AIVehicle.BuildVehicle(depot_tile, engine);
		if(AIVehicle.IsValidVehicle(vehicle_id) == false)
		{
			local dwbve = VehicleManager.DealWithBuildVehicleErrors(AIError.GetLastError());
			if(dwbve == null)
				return null;
			if(dwbve == 3)
			{
				while(AICompany.GetBankBalance(AICompany.COMPANY_SELF) < AIEngine.GetPrice(engine))
				{
					AIController.Sleep(50);
				}
				vehicle_id = AIVehicle.BuildVehicle(depot_tile, engine);
			}
		}
		Info("1/5 buses built");
		AIOrder.AppendOrder(vehicle_id, town_start, AIOrder.AIOF_NON_STOP_INTERMEDIATE);
		AIOrder.AppendOrder(vehicle_id, town_end, AIOrder.AIOF_NON_STOP_INTERMEDIATE);
		AIOrder.AppendOrder(vehicle_id, depot_tile, AIOrder.AIOF_SERVICE_IF_NEEDED);
		if(AIOrder.GetOrderCount(vehicle_id) < 3)
		{
			//Debug("orders failed because " + AIError.GetLastErrorString());
			Error("Ordering vehicles failed");
			return null;
		}
		AIVehicle.StartStopVehicle(vehicle_id);
		local c = 2;
		while (c <= 5)
		{
			local builtVehicle_id = vehicle_id;
			vehicle_id = AIVehicle.CloneVehicle(depot_tile, builtVehicle_id, true);
			if(AIVehicle.IsValidVehicle(vehicle_id) == false)
			{
				local dwbve = VehicleManager.DealWithBuildVehicleErrors(AIError.GetLastError());
				if(dwbve == null)
					return null;
				if(dwbve == 3)
				{
					while(AICompany.GetBankBalance(AICompany.COMPANY_SELF) < AIEngine.GetPrice(engine))
					{
						AIController.Sleep(50);
					}
					vehicle_id = AIVehicle.CloneVehicle(depot_tile, builtVehicle_id, true);
				}
			/*	if(dwbve == 5)
				{					//keep this for now
				Debug("c = " + c);
				Debug("engine = " + engine);
				Debug("depot_tile = " + depot_tile);
				Debug("vehicle_id = " + vehicle_id);
				//Debug("old_vehicle_id = " + old_vehicle_id);
				}*/
			}
			AIVehicle.StartStopVehicle(vehicle_id);
			Info(c + "/5  buses built");
			c++; //lol :)
		}
		Info("Buses successfully bought");
			return true;
	}
	
function VehicleManager::SelectVehicles(cargo_id)
	{
		local list = AICargoList();
		local passenger_cargo_id = -1;
		for (local i = list.Begin(); !list.IsEnd(); i = list.Next())
		{
			if (AICargo.HasCargoClass(i, AICargo.CC_PASSENGERS))
			{
				passenger_cargo_id = i;
				break;
			}
		}
		local engine_list = AIEngineList(AIVehicle.VT_ROAD);
		engine_list.Valuate(AIEngine.GetRoadType)
		engine_list.KeepValue(AIRoad.ROADTYPE_ROAD);
		engine_list.Valuate(AIEngine.GetCargoType);
		engine_list.KeepValue(passenger_cargo_id);

		engine_list.Valuate(AIEngine.GetDesignDate);
		engine_list.Sort(AIList.SORT_BY_VALUE, false);
		engine = engine_list.Begin();
			return engine;
		
	}
	
function VehicleManager::DealWithBuildVehicleErrors(err)
	{
		switch(err)
		{
			case AIError.ERR_NOT_ENOUGH_CASH:
				Warning("Not enough money. Waiting for more");
					return 3;
			break;
			case AIVehicle.ERR_VEHICLE_TOO_MANY:
				//TODO: deal with
				AIController.Sleep(5000);
				Error("Too many vehicles");
					return null;
			break;
			case AIVehicle.ERR_VEHICLE_BUILD_DISABLED:
				//shouldn't happen, but still:
				Error("ROADS VEHICLE TYPE IS DISABLED. THIS VERSION OF AROAI ONLY USES ROAD VEHICLES");
				Error("PLEASE RE-ENABLE THEM, THEN RESTART GAME");
				AroAI.Stop();
			break;
			case AIVehicle.ERR_VEHICLE_WRONG_DEPOT:
					//can't happen? silent ignore
			break;
			case AIError.ERR_PRECONDITION_FAILED:
				Warning("Error: ERR_PRECONDITION_FAILED");
					return 5;
			break;
			default:
				Warning("Unknown error during vehicle building: " + AIError.GetLastErrorString());
			break;
		}
	}

function VehicleManager::Info(string)
	{
		AILog.Info(Util.GameDate() + " [Vehicle Manager] " + string + ".");
	}


function VehicleManager::Warning(string)
	{
		AILog.Warning(Util.GameDate() + " [Vehicle Manager] " + string + ".");
	}

function VehicleManager::Error(string)
	{
		AILog.Error(Util.GameDate() + " [Vehicle Manager] " + string + ".");
	}

function VehicleManager::Debug(string)
	{
		AILog.Warning(Util.GameDate() + " [Vehicle Manager] DEBUG: " + string + ".");
		AILog.Warning(Util.GameDate() + " [Vehicle Manager] (if you see this, please inform the AI Dev in charge, as it was supposed to be removed before release)");
	}
