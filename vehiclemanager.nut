/*
 * This file is part of AroAI.
 *
 * Copyright (C) 2011 - Charles Pigott (aka Lord Aro)
 *
 * AroAI is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, version 2.
 * AroAI is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details. You should have
 * received a copy of the GNU General Public License along with AroAI.
 * If not, see <http://www.gnu.org/licenses/>.
 */

class VehicleManager
{	
	NUM_VEHICLES_PER_ROUTE = 5;	///< Number of vehicles to build per route
	
	engine = -1;
}

function VehicleManager::BuildBusEngines(depot_tile, town_start, town_end)
{
	Info("Using a " + AIEngine.GetName(VehicleManager.SelectVehicles()) + " to carry passengers");

	local town_start_id = AITile.GetClosestTown(town_start);
	Info("Buying buses in " + AITown.GetName(town_start_id));

	local vehicle_id = AIVehicle.BuildVehicle(depot_tile, engine);
	if(!AIVehicle.IsValidVehicle(vehicle_id)) {
		local dwbve = VehicleManager.DealWithBuildVehicleErrors(AIError.GetLastError());
		if(dwbve == 3) {
			while(AICompany.GetBankBalance(AICompany.COMPANY_SELF) < AIEngine.GetPrice(engine)) {
				AIController.Sleep(Builder_BusRoute.SLEEP_TIME_MONEY);
			}
			vehicle_id = AIVehicle.BuildVehicle(depot_tile, engine);
		} else {
			Error("Buying vehicles failed");
			return null;
		}
	}
	Info("1/" + NUM_VEHICLES_PER_ROUTE + " buses built");
	/* Give vehicle its orders */
	AIOrder.AppendOrder(vehicle_id, town_start, AIOrder.AIOF_NON_STOP_INTERMEDIATE);
	AIOrder.AppendOrder(vehicle_id, town_end, AIOrder.AIOF_NON_STOP_INTERMEDIATE);
	AIOrder.AppendOrder(vehicle_id, depot_tile, AIOrder.AIOF_SERVICE_IF_NEEDED);
	/* If orders are not complete for some reason, give up */
	if(AIOrder.GetOrderCount(vehicle_id) < 3) {
		Error("Ordering vehicles failed");
		/* TODO: Get rid of failed vehicle */
		return null;
	}
	AIVehicle.StartStopVehicle(vehicle_id); //Start vehicle
	local c = 2;
	while (c <= NUM_VEHICLES_PER_ROUTE) {
		local builtVehicle_id = vehicle_id;
		vehicle_id = AIVehicle.CloneVehicle(depot_tile, builtVehicle_id, true);
		if(!AIVehicle.IsValidVehicle(vehicle_id)) {
			local dwbve = VehicleManager.DealWithBuildVehicleErrors(AIError.GetLastError());
				if(dwbve == null) return null;
				if(dwbve == 3) {
					while(AICompany.GetBankBalance(AICompany.COMPANY_SELF) < AIEngine.GetPrice(engine)) {
						AIController.Sleep(Builder_BusRoute.SLEEP_TIME_MONEY);
					}
					vehicle_id = AIVehicle.CloneVehicle(depot_tile, builtVehicle_id, true);
				}
/*				if(dwbve == 5) {
				Debug("c = " + c);		//Keep this for now
				Debug("engine = " + engine);
				Debug("depot_tile = " + depot_tile);
				Debug("vehicle_id = " + vehicle_id);
				Debug("old_vehicle_id = " + old_vehicle_id);
				}*/
		}
		AIVehicle.StartStopVehicle(vehicle_id); //Start cloned vehicle
		Info(c + "/" + NUM_VEHICLES_PER_ROUTE + " buses built");
		c++; //Funny!
	}
	Info("Buses successfully bought");
	/* TODO: Test return value without the return */
	return true;
}
	
function VehicleManager::SelectVehicles()
{ //TODO: Better vehicle selector
	/* Get passenger cargo ID */
	local list = AICargoList();
	local passenger_cargo_id = null;
	for (local i = list.Begin(); !list.IsEnd(); i = list.Next()) {
		if (AICargo.HasCargoClass(i, AICargo.CC_PASSENGERS) &&
		    AICargo.GetTownEffect(i) == AICargo.TE_PASSENGERS) {
			passenger_cargo_id = i;
			break;
		}
	}
	local engine_list = AIEngineList(AIVehicle.VT_ROAD);
	/* Don't want trams... */
	engine_list.Valuate(AIEngine.GetRoadType);
	engine_list.KeepValue(AIRoad.ROADTYPE_ROAD);
	
	/* Only keep buses for now */
	engine_list.Valuate(AIEngine.GetCargoType);
	engine_list.KeepValue(passenger_cargo_id);

	/* Use newest vehicle (It's what I do) */
	engine_list.Valuate(AIEngine.GetDesignDate);
	engine_list.Sort(AIList.SORT_BY_VALUE, false);
	engine = engine_list.Begin();
	return engine;
}
	
function VehicleManager::DealWithBuildVehicleErrors(err)
{
	switch(err) {
		case AIError.ERR_NOT_ENOUGH_CASH:
			Warning("Not enough money to buy buses. Waiting for more");
			return 3;
		case AIVehicle.ERR_VEHICLE_TOO_MANY:
			/* Gets dealt with in Start() */
			Error("Too many vehicles");
			return null;
		case AIVehicle.ERR_VEHICLE_BUILD_DISABLED:
			/* Shouldn't happen, but still... */
			Error("ROADS VEHICLE TYPE IS DISABLED. THIS VERSION OF AROAI ONLY USES ROAD VEHICLES");
			Error("PLEASE RE-ENABLE THEM, THEN RESTART GAME");
			AroAI.Stop();
			break;
		case AIError.ERR_PRECONDITION_FAILED:
			Warning("Error: ERR_PRECONDITION_FAILED");
			return 5;
		case AIVehicle.ERR_VEHICLE_WRONG_DEPOT:
		default:
			Warning("Unhandled error during vehicle buying: " + AIError.GetLastErrorString());
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
