/*
 * This file is part of AroAI.
 *
 * Copyright (C) 2011 - Charles Pigott (aka Lord Aro)
 *
 * AroAI is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 2.
 * AroAI is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with OpenTTD. If not, see <http://www.gnu.org/licenses/>.
 */

class VehicleManager
{
	/* Declare constants */
	NUM_VEHICLES_PER_ROUTE = 5; ///< Number of vehicles to build per route.

	/* Declare variables */
	passengerCargoID = null;        ///< CargoID for passengers.
	cargo_list = null;              ///< List with all cargos.
	cargoTransportEngineIds = null; ///< The best EngineIDs to transport cargo.
	cargoHoldingEngineIds = null;   ///< The best EngineIDs to hold cargo.
	optimalDistances = null;        ///< The best distances per EngineIDs.
	maxCargoID = null;              ///< The highest CargoID number.

	constructor()
	{
		/* Initialise variables */
		cargo_list = AICargoList();
		cargo_list.Sort(AIList.SORT_BY_VALUE, false);

		/* Temporary while only passengers are supported */
		GetPassengerCargoID();
		cargo_list.KeepValue(passengerCargoID);

		maxCargoID = cargo_list.Begin();
	}
}

function VehicleManager::BuildBusEngines(depot_tile, town_start, town_end)
{
	local town_start_id = AITile.GetClosestTown(town_start);
	Util.Debug(0, 3, "Buying buses in " + AITown.GetName(town_start_id));

	local vehicle_id = AIVehicle.BuildVehicle(depot_tile, cargoTransportEngineIds[AIVehicle.VT_ROAD][passengerCargoID]);
	if(!AIVehicle.IsValidVehicle(vehicle_id)) {
		local dwbve = VehicleManager.DealWithBuildVehicleErrors(AIError.GetLastError());
		if(dwbve == 3) {
			while(AICompany.GetBankBalance(AICompany.COMPANY_SELF) < AIEngine.GetPrice(cargoTransportEngineIds[AIVehicle.VT_ROAD][passengerCargoID])) {
				AIController.Sleep(Builder_BusRoute.SLEEP_TIME_MONEY);
			}
			vehicle_id = AIVehicle.BuildVehicle(depot_tile, cargoTransportEngineIds[AIVehicle.VT_ROAD][passengerCargoID]);
		} else {
			Util.Debug(2, 3, "Buying vehicles failed");
			return null;
		}
	}
	Util.Debug(0, 3, "1/" + NUM_VEHICLES_PER_ROUTE + " buses built");
	/* Give vehicle its orders */
	AIOrder.AppendOrder(vehicle_id, town_start, AIOrder.AIOF_NON_STOP_INTERMEDIATE);
	AIOrder.AppendOrder(vehicle_id, town_end, AIOrder.AIOF_NON_STOP_INTERMEDIATE);
	AIOrder.AppendOrder(vehicle_id, depot_tile, AIOrder.AIOF_SERVICE_IF_NEEDED);
	/* If orders are not complete for some reason, give up */
	if(AIOrder.GetOrderCount(vehicle_id) < 3) {
		Util.Debug(2, 3, "Ordering vehicles failed");
		/* TODO: Get rid of failed vehicle(s) */
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
				while(AICompany.GetBankBalance(AICompany.COMPANY_SELF) < AIEngine.GetPrice(cargoTransportEngineIds[AIVehicle.VT_ROAD][passengerCargoID])) {
					AIController.Sleep(Builder_BusRoute.SLEEP_TIME_MONEY);
				}
				vehicle_id = AIVehicle.CloneVehicle(depot_tile, builtVehicle_id, true);
			}
		}
		AIVehicle.StartStopVehicle(vehicle_id); //Start cloned vehicle
		Util.Debug(0, 3, c + "/" + NUM_VEHICLES_PER_ROUTE + " buses built");
		c++; //Funny!
	}
	Util.Debug(0, 3, "Buses successfully bought");
	/* TODO: Test return value without the return */
	return true;
}

function VehicleManager::GetPassengerCargoID()
{
	/* Get passenger cargo ID */
	local list = AICargoList();
	for (local i = list.Begin(); !list.IsEnd(); i = list.Next()) {
		if (AICargo.HasCargoClass(i, AICargo.CC_PASSENGERS) &&
		    AICargo.GetTownEffect(i) == AICargo.TE_PASSENGERS) {
			passengerCargoID = i;
			break;
		}
	}
}

function VehicleManager::InitCargoTransportEngineIds()
{
	cargoTransportEngineIds = array(4);
	cargoHoldingEngineIds = array(4);
	optimalDistances = array(4);

	for (local i = 0; i < cargoTransportEngineIds.len(); i++) {
		cargoTransportEngineIds[i] = array(maxCargoID + 1, -1);
		cargoHoldingEngineIds[i] = array(maxCargoID + 1, -1);
		optimalDistances[i] = array(maxCargoID + 1, -1);
	}

	local engineList = AIEngineList(AIVehicle.VT_ROAD);
	engineList.Valuate(AIEngine.GetRoadType);
	engineList.KeepValue(AIRoad.ROADTYPE_ROAD);
	engineList.AddList(AIEngineList(AIVehicle.VT_AIR));
	engineList.AddList(AIEngineList(AIVehicle.VT_WATER));
	engineList.AddList(AIEngineList(AIVehicle.VT_RAIL));

	for (local engine = engineList.Begin(); !engineList.IsEnd(); engine = engineList.Next())
		ProcessNewEngine(engine);
}

function VehicleManager::ProcessNewEngine(engineID)
{
	if (!AIEngine.IsBuildable(engineID)) return false;

	/* Temporary while only road vehicles are supported */
	if (AIEngine.GetVehicleType(engineID) != AIVehicle.VT_ROAD) return false;

	local vehicleType = AIEngine.GetVehicleType(engineID);
	local updateWagons = false;

	/* We skip trams for now. */
	if (vehicleType == AIVehicle.VT_ROAD && AIEngine.GetRoadType(engineID) != AIRoad.ROADTYPE_ROAD) return false;

	local engineReplaced = false;

	for (local cargo = cargo_list.Begin(); !cargo_list.IsEnd(); cargo = cargo_list.Next()) {
		local cargo = passengerCargoID;
		local oldEngineID = cargoTransportEngineIds[vehicleType][cargo];
		local newEngineID = -1;

		if ((AIEngine.GetCargoType(engineID) == cargo || AIEngine.CanRefitCargo(engineID, cargo) || (!AIEngine.IsWagon(engineID) && AIEngine.CanPullCargo(engineID, cargo)))) {

			/* Different case for trains as the wagons cannot transport themselves and the locomotives are unable to carry any cargo (ignorable cases aside). */
			if (vehicleType == AIVehicle.VT_RAIL) {

				/* Check if we have to process a new rail type. */
				local best_new_rail_type = TrainConnectionAdvisor.GetBestRailType(engineID);
				local best_old_rail_type = TrainConnectionAdvisor.GetBestRailType(oldEngineID);

				if (AIEngine.IsWagon(engineID)) {
					/* We only judge a wagon on its merit to transport cargo. */
					if (AIEngine.GetCapacity(cargoHoldingEngineIds[vehicleType][cargo]) < AIEngine.GetCapacity(engineID) ||
					    AIRail.GetMaxSpeed(AIEngine.GetRailType(engineID)) > AIRail.GetMaxSpeed(AIEngine.GetRailType(cargoHoldingEngineIds[vehicleType][cargo]))) {
						cargoHoldingEngineIds[vehicleType][cargo] = engineID;
						if (oldEngineID == -1) Util.Debug(0, 3, "Using " + AIEngine.GetName(engineID) + " to transport " + AICargo.GetCargoLabel(cargo));
						else Util.Debug(0, 3, "Replaced " + AIEngine.GetName(oldEngineID) + " with " + AIEngine.GetName(engineID) + " to transport " + AICargo.GetCargoLabel(cargo));
						newEngineID = engineID;
						engineReplaced = true;
					}
				} else {
					/* We only judge a locomotive on its merit to transport wagons (don't care about the accidental bit of cargo it can move around). */
					if (AIEngine.GetMaxSpeed(cargoTransportEngineIds[vehicleType][cargo]) < AIEngine.GetMaxSpeed(engineID) ||
					    AIRail.GetMaxSpeed(AIEngine.GetRailType(engineID)) > AIRail.GetMaxSpeed(AIEngine.GetRailType(cargoTransportEngineIds[vehicleType][cargo]))) {
						cargoTransportEngineIds[vehicleType][cargo] = engineID;
						if (oldEngineID == -1) Util.Debug(0, 3, "Using " + AIEngine.GetName(engineID) + " to transport " + AICargo.GetCargoLabel(cargo));
						else Util.Debug(0, 3, "Replaced " + AIEngine.GetName(oldEngineID) + " with " + AIEngine.GetName(engineID) + " to transport " + AICargo.GetCargoLabel(cargo));
						newEngineID = engineID;
						engineReplaced = true;
						updateWagons = true;
					}
				}
			} else if (AIEngine.GetMaxSpeed(cargoTransportEngineIds[vehicleType][cargo]) * AIEngine.GetCapacity(cargoTransportEngineIds[vehicleType][cargo]) < AIEngine.GetMaxSpeed(engineID) * AIEngine.GetCapacity(engineID)) {
				cargoTransportEngineIds[vehicleType][cargo] = engineID;
				cargoHoldingEngineIds[vehicleType][cargo] = engineID;
				newEngineID = engineID;
				if (oldEngineID == -1) Util.Debug(0, 3, "Using " + AIEngine.GetName(engineID) + " to transport " + AICargo.GetCargoLabel(cargo));
				else Util.Debug(0, 3, "Replaced " + AIEngine.GetName(oldEngineID) + " with " + AIEngine.GetName(engineID) + " to transport " + AICargo.GetCargoLabel(cargo));
				engineReplaced = true;
			}
		}
	}

	/* If a train engine has been replaced, check if there are new wagons to accompany them. */
	if (updateWagons) {
		for (local cargo = cargo_list.Begin(); !cargo_list.IsEnd(); cargo = cargo_list.Next()) {

			local transportEngineID = cargoTransportEngineIds[AIVehicle.VT_RAIL][cargo];

			local best_rail_type = TrainConnectionAdvisor.GetBestRailType(transportEngineID);

			local newWagons = AIEngineList(AIVehicle.VT_RAIL);
			newWagons.Valuate(AIEngine.IsWagon);
			newWagons.KeepValue(1);
			newWagons.Valuate(AIEngine.CanRunOnRail, best_rail_type);
			newWagons.KeepValue(1);
			newWagons.Valuate(AIEngine.HasPowerOnRail, best_rail_type);
			newWagons.KeepValue(1);

			for (local wagon = newWagons.Begin(); !newWagons.IsEnd(); wagon = newWagons.Next()) ProcessNewEngine(wagon);
		}
	}
	return engineReplaced;
}

function VehicleManager::DealWithBuildVehicleErrors(err)
{
	switch(err) {
		case AIError.ERR_NOT_ENOUGH_CASH:
			Util.Debug(1, 3, "Not enough money to buy buses. Waiting for more");
			return 3;
		case AIVehicle.ERR_VEHICLE_TOO_MANY:
			/* Gets dealt with in Start() */
			Util.Debug(2, 3, "Too many vehicles");
			return null;
		case AIVehicle.ERR_VEHICLE_BUILD_DISABLED:
			/* Shouldn't happen, but still... */
			Util.Debug(2, 3, "ROADS VEHICLE TYPE IS DISABLED. THIS VERSION OF AROAI ONLY USES ROAD VEHICLES");
			Util.Debug(2, 3, "PLEASE RE-ENABLE THEM, THEN RESTART GAME");
			AroAI.Stop();
			break;
		case AIError.ERR_PRECONDITION_FAILED:
			Util.Debug(1, 3, "Error: ERR_PRECONDITION_FAILED");
			return 5;
		case AIVehicle.ERR_VEHICLE_WRONG_DEPOT:
		default:
			Util.Debug(1, 3, "Unhandled error during vehicle buying: " + AIError.GetLastErrorString());
			break;
	}
}

