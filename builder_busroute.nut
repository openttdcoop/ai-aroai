/*
 * This file is part of AroAI.
 *
 * Copyright (C) 2011 - Charles Pigott (aka Lord Aro)
 *
 * AroAI is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 2.
 * AroAI is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with OpenTTD. If not, see <http://www.gnu.org/licenses/>.
 */

class Builder_BusRoute
{
	/* Declare constants */
	MAX_TOWN_DISTANCE = 125;     ///< Maximum distance from tile_a
	PATHFINDER_ITERATIONS = 100; ///< Number of iterations to try before failing
	SLEEP_TIME_MONEY = 50;       ///< How long to sleep when not enough money
	SLEEP_TIME_VEHICLE = 10;     ///< How long to sleep when vehicle is in the way

	/* Declare variables */	
	townList = null;
	town_a = null;
	town_b = null;
	numToRemove = null;
	manageOnly = null;
	stopMoneyDebug = null;

	constructor()
	{
		/* Initialise variables */
		numToRemove = 1;
		manageOnly = false;
		stopMoneyDebug = 0;
	}
}

function Builder_BusRoute::Main()
{
	Util.Debug(0, 1, "Planning on building bus route");
	if ((AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_ROAD)) || (AIController.GetSetting("enable_road_vehs") == 0)) {
		Util.Debug(2, 1, "ROAD VEHICLES ARE DISABLED. THIS VERSION OF AROAI ONLY USES ROAD VEHICLES");
		Util.Debug(2, 1, "PLEASE RE-ENABLE THEM, THEN RESTART GAME");
		AroAI.Stop();
	}
	/* TODO: Remove failed bus stops */
	if (GetTowns() == null) return;

	if (BuildRoad(town_a, town_b) == null) return;

	local town = town_a;
	local busStation_a = BuildBusStop(town);
	if (busStation_a == null) return;

	local depot_tile_a = BuildRVStation(town_a, "depot");
	if (depot_tile_a == null) return;
		
	town = town_b;
	local busStation_b = BuildBusStop(town);
	if (busStation_b == null) return;
		
	local depot_tile_b = BuildRVStation(town_b, "depot");
	if (depot_tile_b == null) return;
	
	if (VehicleManager.BuildBusEngines(depot_tile_a, busStation_a, busStation_b) == null) return;
	
	/* Never mind if this fails, there are five buses on the route already */
	VehicleManager.BuildBusEngines(depot_tile_b, busStation_b, busStation_a);
}

function Builder_BusRoute::GetTowns()
{
	/* Reset variables */
	town_a = null;
	town_b = null;

	townList = AITownList();
	townList.Valuate(AITown.GetPopulation);
	townList.Sort(AIList.SORT_BY_VALUE, false);
	townList.RemoveTop(numToRemove);
	town_a = townList.Begin();
	if (townList.IsEnd()) {
		Util.Debug(1, 1, "No towns left to build in. Now managing only");
		manageOnly = true;
		return null;
	}
	/* Remove town_a */
	townList.RemoveTop(1);

	local tile_a = AITown.GetLocation(town_a);
	townList.Valuate(AITown.GetDistanceManhattanToTile, tile_a);

	/* Keep towns within certain distance */
	townList.KeepBelowValue(MAX_TOWN_DISTANCE);
	townList.Valuate(AITown.GetRating, AICompany.COMPANY_SELF);
	townList.KeepValue(AITown.TOWN_RATING_NONE);// TODO: Improve
	if (townList.IsEmpty()) {
		Util.Debug(1, 1, "No serviceable towns within radius of " + AITown.GetName(town_a) + ". Moving to next town");
		numToRemove++;
		return null;
	}
	townList.Valuate(AITown.GetPopulation);
	townList.Sort(AIList.SORT_BY_VALUE, false);

	/* Pick the top one */
	town_b = townList.Begin();
	return town_a, town_b;
}

function Builder_BusRoute::BuildRoad(town_a, town_b)
{
	/* Set roadtype */
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);

	/* Reset variable */
	stopMoneyDebug = 10;
	Util.Debug(0, 1, "Planning route from " + AITown.GetName(town_a) + " to " + AITown.GetName(town_b));
	local pathfinder = RoadPathFinder();
	pathfinder.cost.turn = 1;
	pathfinder.InitializePath([AITown.GetLocation(town_b)], [AITown.GetLocation(town_a)]);
	local path = false;
	local counter = 0;
	while (path == false) {
		/* Number of attempts at finding path */
		path = pathfinder.FindPath(PATHFINDER_ITERATIONS);
		counter++;
		AIController.Sleep(1);
	}
	/* No path was found */
	if (path == null) {
		Util.Debug(2, 1, "No route found");
		numToRemove++;
		return null;
	}
	Util.Debug(0, 1, "Route found. (Tried " + counter + " times) Building started");
	/* If a path found, build a road over it */
	while (path != null) {
		local par = path.GetParent();
		if (par != null) {
			local last_node = path.GetTile();
			if (AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1) {
				if (!AIRoad.BuildRoad(path.GetTile(), par.GetTile())) {
					local dwbre = this.DealWithBuildRouteErrors(AIError.GetLastError());
					if (dwbre == 2) { //Not enough money
						while (!AIRoad.BuildRoad(path.GetTile(), par.GetTile()));
					}
					if (dwbre == 3) { //Area not clear
						local sign = AISign.BuildSign(path.GetTile(), "Clearing tile");
						/* Demolish and retry */
						AITile.DemolishTile(path.GetTile())
						if (!AIRoad.BuildRoad(path.GetTile(), par.GetTile())) return null;
						AISign.RemoveSign(sign);
					}
					if (dwbre == 4) { //Vehicle in the way
						/* Keep trying until vehicle moved */
						while (!AIRoad.BuildRoad(path.GetTile(), par.GetTile()));
					}
					if (dwbre == null) { //Unknown + land sloped wrong + one-way junction
						AISign.BuildSign(path.GetTile(), AIError.GetLastErrorString());
						return null;
					}
				}
			} else {
			/* Build a bridge or tunnel. */
				if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile())) {
					/* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
					if (AIRoad.IsRoadTile(path.GetTile())) AITile.DemolishTile(path.GetTile());

					if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == par.GetTile()) {
						if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path.GetTile())) {
							/* An error occured while building a tunnel. TODO: handle it. */
							Util.Debug(2, 1, "Build tunnel error: " + AIError.GetLastErrorString());
							Util.Debug(2, 1, "TODO: Handle it");
							return null;
						}
					} else {
						local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) + 1);
						bridge_list.Valuate(AIBridge.GetMaxSpeed);
						bridge_list.Sort(AIList.SORT_BY_VALUE, false);
						if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), path.GetTile(), par.GetTile())) {
							/* An error occured while building a bridge. TODO: handle it. */
							Util.Debug(2, 1, "Build bridge error: " + AIError.GetLastErrorString());
							Util.Debug(2, 1, "TODO: Handle it");
							return null;
						}
					}
				}
			}
		}
		path = par;
	}
	Util.Debug(0, 1, "Road building finished");
	Util.Debug(0, 1, AITown.GetName(town_a) + " is now connected to " + AITown.GetName(town_b))
	return true;
}

function Builder_BusRoute::BuildBusStop(town)
{
	Util.Debug(0, 1, "Building bus stop in " + AITown.GetName(town));
	/* Find empty square as close to town centre as possible */
	local range = 1;
	local max_range = Util.Sqrt(AITown.GetPopulation(town)/100) + 2;
	local area = AITileList();
		
	while (range < max_range) {
		area.AddRectangle(AITown.GetLocation(town) - AIMap.GetTileIndex(range, range), AITown.GetLocation(town) + AIMap.GetTileIndex(range, range));
		area.Valuate(AIRoad.IsRoadTile);
		area.KeepValue(1);
		area.Valuate(AIRoad.IsDriveThroughRoadStationTile);
		area.KeepValue(0);
		area.Valuate(AITile.GetSlope);
		area.KeepValue(AITile.SLOPE_FLAT);
		area.Valuate(AIRoad.GetNeighbourRoadCount);

		/* Entrance and exit. TODO: allow 1 as well? */
		area.KeepValue(2);
		if (area.Count()) {
			for (local station = area.Begin(); !area.IsEnd(); station = area.Next()) {
				local opening = getRoadTile(station);
				if (opening) {
					if (!AIRoad.BuildDriveThroughRoadStation(station, opening, AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_JOIN_ADJACENT)) {
						switch (AIError.GetLastError()) {
							case AIError.ERR_NOT_ENOUGH_CASH:
								Util.Debug(1, 1, "Not enough money to build bus stop. Waiting for more");
								while (AICompany.GetBankBalance(AICompany.COMPANY_SELF) < AIRoad.GetBuildCost(AIRoad.ROADTYPE_ROAD, AIRoad.BT_BUS_STOP)) {
									if (AIRoad.IsDriveThroughRoadStationTile(station)) continue;
									AIController.Sleep(SLEEP_TIME_MONEY);
								}
								if (!AIRoad.BuildDriveThroughRoadStation(station, opening, AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_JOIN_ADJACENT)) return null; //TODO: handle errors again
								break;
							case AIRoad.ERR_ROAD_CANNOT_BUILD_ON_TOWN_ROAD:
								Util.Debug(0, 1, "Building on town roads disabled. Building a bus station instead");
								station = BuildRVStation(town, "station");
								if (station == null) return null;
								else return station;
							case AIError.ERR_VEHICLE_IN_THE_WAY: //TODO: handle it
							default:
								Util.Debug(1, 1, "Unhandled error building bus stop: " + AIError.GetLastErrorString() + " Trying again");
								continue;
						}
					}
					Util.Debug(0, 1, "Successfully built bus stop");
					townList.RemoveValue(town);
					return station;
				}
			}
			range++;
		} else {
			range++;
		}
	}
	Util.Debug(2, 1, "Building bus stop in " + AITown.GetName(town) + " failed");
	return null;
}

function Builder_BusRoute::BuildRVStation(townid, type)
{
	local buildType = null;
	Util.Debug(0, 1, "Building bus " + type + " in " + AITown.GetName(townid));
	if (type == "station") {
		buildType = AIRoad.BT_BUS_STOP;
	}
	else if (type == "depot") {
		buildType = AIRoad.BT_DEPOT;
		/* Check for depot in town. If yes, use that one */
		Util.Debug(0, 1, "Checking for pre-built depots in " + AITown.GetName(townid));
		local depotList = AIDepotList(AITile.TRANSPORT_ROAD);
		depotList.Valuate(AITile.GetClosestTown);
		depotList.KeepValue(townid);
		if (!depotList.IsEmpty()) {
			Util.Debug(0, 1, "Depot in " + AITown.GetName(townid) + " found. Using it instead of building one");
			local depotTile = depotList.Begin();
			return depotTile;
		}
		Util.Debug(0, 1, "No depot in " + AITown.GetName(townid) + " found");
	}
	/* Find empty square as close to station as possible */
	local range = 1;
	local area = AITileList();
	local townLocation = AITown.GetLocation(townid);
	
	while (range < 15) {
		area.AddRectangle(townLocation - AIMap.GetTileIndex(range, range), townLocation + AIMap.GetTileIndex(range, range));
		area.Valuate(AITile.IsBuildable);
		area.KeepValue(1);
		if (area.Count()) {
			for (local buildTile = area.Begin(); !area.IsEnd(); buildTile = area.Next()) {
				local buildFront = getRoadTile(buildTile);
				if (buildFront) {
					if (!AIRoad.BuildRoad(buildTile, buildFront)) {
						switch (AIError.GetLastError()) {
							case AIError.ERR_NOT_ENOUGH_CASH: //Wait for more money
								Util.Debug(1, 1, "Not enough money to build road for bus " + type + ". Waiting for more");
								while (AICompany.GetBankBalance(AICompany.COMPANY_SELF) < AIRoad.GetBuildCost(AIRoad.ROADTYPE_ROAD, AIRoad.BT_ROAD)) {
									if (!AITile.IsBuildable(buildTile)) continue;
									AIController.Sleep(SLEEP_TIME_MONEY);
								}
								if (!AIRoad.BuildRoad(buildTile, buildFront)) return null; //TODO: Handle errors again
								break;
							case AIError.ERR_VEHICLE_IN_THE_WAY: //Wait for vehicle to get out of the way
								while (!AIRoad.BuildRoad(buildTile, buildFront)) {
									if (!AITile.IsBuildable(buildTile)) continue;
									AIController.Sleep(SLEEP_TIME_VEHICLE);
								}
								break;
							case AIError.ERR_ALREADY_BUILT: //Probably too much road, but build depot anyway TODO: Check I'm right
							break;
							case AIError.ERR_LAND_SLOPED_WRONG: //TODO: Handle it, give up for now
							case AIError.ERR_AREA_NOT_CLEAR: //TODO: Handle it, give up for now
							case AIRoad.ERR_ROAD_ONE_WAY_ROADS_CANNOT_HAVE_JUNCTIONS: //Can't happen? Just give up
							case AIRoad.ERR_ROAD_WORKS_IN_PROGRESS: //Just give up
							default:
								Util.Debug(1, 1, "Unhandled error while building bus " + type + ": " + AIError.GetLastErrorString() + ". Trying again");
								continue;
						}
					}
					local buildStructure = null;
					if (type == "depot") buildStructure = AIRoad.BuildRoadDepot(buildTile, buildFront);
					else if (type == "station") buildStructure = AIRoad.BuildRoadStation(buildTile, buildFront, AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_JOIN_ADJACENT);
					/* Something wrong, shouldn't happen */
					else return null;
					if (!buildStructure) {
						switch (AIError.GetLastError()) {
							case AIError.ERR_NOT_ENOUGH_CASH:
								Util.Debug(1, 1, "Not enough money to build bus " + type + ". Waiting for more");
								while (AICompany.GetBankBalance(AICompany.COMPANY_SELF) < AIRoad.GetBuildCost(AIRoad.ROADTYPE_ROAD, buildType)) {
									if (!AITile.IsBuildable(buildTile)) continue;
									AIController.Sleep(SLEEP_TIME_MONEY);
								}
								if (type == "depot" && !AIRoad.BuildRoadDepot(buildTile, buildFront)) return null; //TODO: handle errors again
								else if (type == "station" && !AIRoad.BuildRoadStation(buildTile, buildFront, AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_JOIN_ADJACENT)) return null; //TODO: handle errors again
								break;
							case AIError.ERR_FLAT_LAND_REQUIRED:
							case AIError.ERR_AREA_NOT_CLEAR: //TODO: Handle them, for now just give up and try somewhere else
							default:
								Util.Debug(1, 1, "Unhandled error while building bus " + type + ": " + AIError.GetLastErrorString() + ". Trying again");
								continue;
						}
					}
					Util.Debug(0, 1, "Successfully built bus " + type);
					return buildTile;
				}
			}
			/* The tiles found had no road connections; enlarge search area */
			range++;
		} else {
			range++;
			area.Clear;
		}
	}
	Util.Debug(2, 1, "Building bus " + type + " in " + AITown.GetName(town) + " failed");
	return null;
}

function Builder_BusRoute::getRoadTile(tile) //From OTVI
{
	local adjacent = AITileList();
	adjacent.AddTile(tile - AIMap.GetTileIndex(1,0));
	adjacent.AddTile(tile - AIMap.GetTileIndex(0,1));
	adjacent.AddTile(tile - AIMap.GetTileIndex(-1,0));
	adjacent.AddTile(tile - AIMap.GetTileIndex(0,-1));
	adjacent.Valuate(AIRoad.IsRoadTile);
	adjacent.KeepValue(1);
	adjacent.Valuate(AIRoad.IsRoadStationTile);
	adjacent.KeepValue(0);
	adjacent.Valuate(AITile.GetSlope);
	adjacent.KeepValue(AITile.SLOPE_FLAT);
	if (adjacent.Count()) return adjacent.Begin();
	else return null;
}

function Builder_BusRoute::DealWithBuildRouteErrors(err)
{
	switch (err) {
		case AIError.ERR_VEHICLE_IN_THE_WAY:
			Util.Debug(1, 1, "Building road failed temporarily - vehicle in the way");
			return 4;
		case AIError.ERR_ALREADY_BUILT: return 1; //Someone else already built this - silent ignore
		case AIError.ERR_AREA_NOT_CLEAR:
			Util.Debug(1, 1, "Building road failed: not clear, demolishing tile..");
			return 3;
		case AIError.ERR_NOT_ENOUGH_CASH:
			if (stopMoneyDebug == 10) { //Only display debug every ten times
				Util.Debug(1, 1, "Not enough money to build road. Waiting for more");
				stopMoneyDebug = 0;
			}
			stopMoneyDebug++;
			return 2;
		case AIError.ERR_LAND_SLOPED_WRONG: //TODO: Terraform
		case AIRoad.ERR_ROAD_ONE_WAY_ROADS_CANNOT_HAVE_JUNCTIONS:
		case AIRoad.ERR_ROAD_WORKS_IN_PROGRESS:
		default:
			Util.Debug(2, 1, "Unhandled error during road building " + AIError.GetLastErrorString());
			return null;
	}
}

