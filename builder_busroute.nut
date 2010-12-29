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


class Builder_BusRoute
	{
		function Main();
		function GetTowns();
		function BuildRoad(town_a, town_b);
		function BuildBusStop(town);
		function BuildRoadDepot(town);

		town_list = null;
		old_town_a = null;
		town_a = null;
		town_b = null;
		err = null;
		busStation_a = 0;
		busStation_b = 0;
		depot_tile_a = 0;
		depot_tile_b = 0;
		engine = 0;
		numToRemove = 1;
		manageOnly = false;
	}

function Builder_BusRoute::Main()
	{
		Info("Planning on building bus route"); //TODO: make this more efficent
		if(AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_ROAD))
		{
			Error("ROAD VEHICLES ARE DISABLED. THIS VERSION OF AROAI ONLY USES ROAD VEHICLES");
			Error("PLEASE RE-ENABLE THEM, THEN RESTART GAME");
			AroAI.Stop();
		}
		if(AIController.GetSetting("enable_road_vehs") == 0)
		{
			Error("ROADS VEHICLE TYPE IS DISABLED. THIS VERSION OF AROAI ONLY USES ROAD VEHICLES");
			Error("PLEASE RE-ENABLE THEM, THEN RESTART GAME");
			AroAI.Stop();
		}
		
		local towns = Builder_BusRoute.GetTowns();
		if(towns == null)
			return;

		local route = Builder_BusRoute.BuildRoad(town_a, town_b);
		if(route == null)
			return;
//		town_a = old_town_a;
		local town = town_a;
		busStation_a = Builder_BusRoute.BuildBusStop(town);
		if(busStation_a == null)
			//TODO: Deal with all returns
			return;
		
		depot_tile_a = Builder_BusRoute.BuildRoadDepot(town_a);
		if(depot_tile_a == null)
			return;
		
		town = town_b;
		busStation_b = Builder_BusRoute.BuildBusStop(town);
		if(busStation_b == null)
			return;
		
		depot_tile_b = Builder_BusRoute.BuildRoadDepot(town_b);
		if(depot_tile_b == null)
			return;
		
		local bbe = VehicleManager.BuildBusEngines(depot_tile_a, busStation_a, busStation_b);
		if(bbe == null)
			return;

		bbe = VehicleManager.BuildBusEngines(depot_tile_b, busStation_b, busStation_a);
		if(bbe == null)
			return;
	}

function Builder_BusRoute::GetTowns()
	{
		town_a = null; //reset variables
		town_b = null;
		AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
		town_list = AITownList();
		town_list.Valuate(AITown.GetPopulation);
		town_list.Sort(AIList.SORT_BY_VALUE, false);
		town_list.RemoveTop(numToRemove);
		town_a = town_list.Begin();
		if(town_list.IsEnd())
		{
			this.manageOnly = true;
				return null;
		}
		town_list.RemoveTop(1);//remove town_a
		local tile_a = AITown.GetLocation(town_a);
		town_list.Valuate(AITown.GetDistanceManhattanToTile, tile_a);
		town_list.KeepBelowValue(125); //keep towns within 125 distance
		town_list.Valuate(AITown.GetRating, AICompany.COMPANY_SELF);
		town_list.KeepValue(AITown.TOWN_RATING_NONE);//TODO: improve
		if(town_list.IsEmpty())
		{
			Info("No serviceable towns within radius of " + AITown.GetName(town_a) + ". Moving to next town");
			numToRemove++;
//			AroAI.Stop();
				return null;
		}
		town_list.Valuate(AITown.GetPopulation);
		town_list.Sort(AIList.SORT_BY_VALUE, false);
		town_b = town_list.Begin(); //pick the top one
		      	return town_a, town_b;
	}

function Builder_BusRoute::BuildRoad(town_a, town_b)
	{
		Info("Planning route from " + AITown.GetName(town_a) + " to " + AITown.GetName(town_b));
		local pathfinder = RoadPathFinder();
		pathfinder.cost.turn = 1;
		pathfinder.InitializePath([AITown.GetLocation(town_b)], [AITown.GetLocation(town_a)]);
		local path = false;
		local counter = 0;
		while (path == false)
		{
			path = pathfinder.FindPath(100);//100 attempts at finding path TODO: check
			counter++;
			AIController.Sleep(1);
		}
		if (path == null) //No path was found
		{
			Warning("No route found");
				return null;
		}
		Info("Route found. (Tried " + counter + " times) Building started");
		while (path != null) //If a path found, build a road over it
		{
			local par = path.GetParent();
			if (par != null)
			{
				local last_node = path.GetTile();
				if (AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1 )
				{
					if (!AIRoad.BuildRoad(path.GetTile(), par.GetTile()))
					{
						local dwbre = this.DealWithBuildRouteErrors(AIError.GetLastError());
						if(dwbre == 2)
						{ //not enough money
							while(!AIRoad.BuildRoad(path.GetTile(), par.GetTile()));
						}
						if(dwbre == 3)
						{ //area not clear
							local sign = AISign.BuildSign(path.GetTile(), "Clearing tile");
							// demolish and retry
							AITile.DemolishTile(path.GetTile())
							AIRoad.BuildRoad(path.GetTile(), par.GetTile());
							AISign.RemoveSign(sign);
						}
						if(dwbre == 4)
						{ //vehicle in the way
							// try again till the stupid vehicle moved?
							while(!AIRoad.BuildRoad(path.GetTile(), par.GetTile()));
						}
						if(dwbre == null)
						{ //unknown + oneway junction
							AISign.BuildSign(path.GetTile(), AIError.GetLastErrorString());
						}
					}
				}
				else
				{
					/* Build a bridge or tunnel. */
					if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile()))
					{
						/* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
						if (AIRoad.IsRoadTile(path.GetTile())) AITile.DemolishTile(path.GetTile());
						if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == par.GetTile())
						{
							if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path.GetTile()))
							{
								/* An error occured while building a tunnel. TODO: handle it. */
								Warning("Build tunnel error: " + AIError.GetLastErrorString());
								Warning("TODO: Handle it");
									return null;
							}
						} 
						else
						{
							local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) + 1);
							bridge_list.Valuate(AIBridge.GetMaxSpeed);
							bridge_list.Sort(AIList.SORT_BY_VALUE, false);
							if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), path.GetTile(), par.GetTile()))
							{
								/* An error occured while building a bridge. TODO: handle it. */
								Warning("Build bridge error: " + AIError.GetLastErrorString());
								Warning("TODO: Handle it");
									return null;
							}
						}
					}
				}
			}
			path = par;
		}
		Info("Road building finished");
		Info(AITown.GetName(town_a) + " is now connected to " + AITown.GetName(town_b))
			return true;
	}

function Builder_BusRoute::BuildBusStop(town)
	{
		Info("Building bus stop in " + AITown.GetName(town));
		// Find empty square as close to town centre as possible
		local spotFound = false;
		local range = 1;
		local max_range = sqrt(AITown.GetPopulation(town)/100) + 2; //TODO check value correctness 
		local area = AITileList();
		
		while (range < max_range)
		{
			area.AddRectangle(AITown.GetLocation(town) - AIMap.GetTileIndex(range, range), AITown.GetLocation(town) + AIMap.GetTileIndex(range, range));
			area.Valuate(AIRoad.IsRoadTile);
			area.KeepValue(1);
			area.Valuate(AIRoad.IsDriveThroughRoadStationTile);
			area.KeepValue(0);
			area.Valuate(AITile.GetSlope);
			area.KeepValue(AITile.SLOPE_FLAT);
			area.Valuate(AIRoad.GetNeighbourRoadCount);
			area.KeepValue(2);	// entrance and exit; allow 1 as well?
			if (area.Count())
			{
				for (local station = area.Begin(); !area.IsEnd(); station = area.Next())
				{
//					Debug("station(line258) = " + station);
					local opening = getRoadTile(station);
					if(opening)
					{
						local buildStation = AIRoad.BuildDriveThroughRoadStation(station, opening, AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_JOIN_ADJACENT);
						if(!buildStation)
						{
							switch(AIError.GetLastError())
							{
								case AIError.ERR_VEHICLE_IN_THE_WAY:
									Warning("Bus stop building temporarily stopped - vehicle in the way");
										continue;
								break;
								case AIError.ERR_NOT_ENOUGH_CASH:
									Warning("Not enough money. Waiting for more");
									while(!AIRoad.BuildDriveThroughRoadStation(station, opening, AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_JOIN_ADJACENT));
									Info("Bus stop successfully built");
										return station;
								break;
								case AIRoad.ERR_ROAD_CANNOT_BUILD_ON_TOWN_ROAD:
									Info("Building on town roads disabled. Building a bus station instead");
									local busStation = Builder_BusRoute.BuildBusStation(town);
									if(busStation == null) {return null;}
									else {return busStation;}
								break;
								default:
									Warning("Error building bus stop: " + AIError.GetLastErrorString() + " Trying again");
										continue;
								break;
							}
						}
						else
						{
						Info("Bus stop successfully built");
//						Debug("station(line294) = " + station);
						town_list.RemoveValue(town);
							return station;
						}
					}
				}
				range++;
			}
			else
			{
				range++;
			}
		}
		Warning("No possible bus stop location found");
		return null;
	}

function Builder_BusRoute::BuildBusStation(town)
	{
		// Find square as close to town centre as possible
		local range = 1;
		local area = AITileList();
		local townLocation = AITown.GetLocation(town);
		while (range < 15)
		{
			area.AddRectangle(townLocation - AIMap.GetTileIndex(range, range), townLocation + AIMap.GetTileIndex(range, range));
			area.Valuate(AITile.GetOwner);
			area.KeepValue(AICompany.COMPANY_INVALID);
			area.Valuate(AITile.IsRoadTile);
			area.KeepValue(0); //don't try to build station on road tile
			area.Valuate(AITile.GetSlope);
			area.KeepValue(AITile.SLOPE_FLAT);//TODO: keep other possible slopes
			if (area.Count())
			{
				for (local busStationTile = area.Begin(); !area.IsEnd(); busStationTile = area.Next())
				{
					local busStationFront = getRoadTile(busStationTile);
					if(busStationFront)
					{
						if(!AITile.DemolishTile(busStationTile)) continue;
						local buildBusStationRoad = AIRoad.BuildRoad(busStationTile, busStationFront);
						if(!buildBusStationRoad)
						{
							switch(AIError.GetLastError())
							{
								case AIError.ERR_NOT_ENOUGH_CASH: //wait for money
									Warning("Not enough money. Waiting for more");
									while(!AIRoad.BuildRoad(busStationTile, busStationFront));
								break;
								case AIError.ERR_VEHICLE_IN_THE_WAY: //wait for stupid vehicle to get out of the way
									while(!AIRoad.BuildRoad(busStationTile, busStationFront));
								break;
								case AIError.ERR_ALREADY_BUILT: //probably too much road, but build bus station anyway TODO: check i'm right
								break;
								case AIRoad.ERR_ROAD_WORKS_IN_PROGRESS: //as above
								case AIError.ERR_LAND_SLOPED_WRONG: //TODO: handle it, give up for now
								case AIError.ERR_AREA_NOT_CLEAR: //TODO: handle it, give up for now
								case AIRoad.ERR_ROAD_ONE_WAY_ROADS_CANNOT_HAVE_JUNCTIONS: //can't happen?
								default:
									Warning("Unhandled error while building bus station: " + AIError.GetLastErrorString() + ". Trying again");
										continue;
								break;
							}
						}
						local buildBusStation = AIRoad.BuildRoadStation(busStationTile, busStationFront, AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_JOIN_ADJACENT);
						if(!buildBusStation)
						{
							switch(AIError.GetLastError())
								{
								case AIError.ERR_NOT_ENOUGH_CASH:
									Warning("Not enough money. Waiting for more");
									while(!AIRoad.BuildRoadStation(busStationTile, busStationFront, AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_JOIN_ADJACENT));
									Info("Bus station successfully built");
										return busStationTile;
								break;
								case AIError.ERR_FLAT_LAND_REQUIRED:
								case AIError.ERR_AREA_NOT_CLEAR: //TODO: handle them, for now just give up and try somewhere else
								default:
									Warning("Unhandled error while building bus station: " + AIError.GetLastErrorString() + ". Trying again");
									continue;
								break;
							}
						}
						Info("Bus station successfully built");
								return busStationTile;
					}
				}
				range++; // the found options had no road connections; enlarge search area
			}
			else
			{
				range++;
				area.Clear;
			}
		}
		Warning("Bus station building in " + AITown.GetName(town) + " failed");
			return null;
	}

function Builder_BusRoute::BuildRoadDepot(town)
	{
		Info("Building depot in " + AITown.GetName(town));
		local depotList = AIDepotList(AITile.TRANSPORT_ROAD);
		depotList.Valuate(AITile.GetClosestTown);
		depotList.KeepValue(town); //if depot already in town, use that one
		if(!depotList.IsEmpty())
		{
			local depot_tile = depotList.Begin();
			return depot_tile;
		}
		else
		{
			// Find empty square as close to station as possible
			local range = 1;
			local area = AITileList();
			local townLocation = AITown.GetLocation(town);
	
			while (range < 15)
			{
				area.AddRectangle(townLocation - AIMap.GetTileIndex(range, range), townLocation + AIMap.GetTileIndex(range, range));
				area.Valuate(AITile.IsBuildable);
				area.KeepValue(1);
				if (area.Count())
				{
					for (local depot_tile = area.Begin(); !area.IsEnd(); depot_tile = area.Next())
					{
						local depot_front = getRoadTile(depot_tile);
						if(depot_front)
						{
							local buildDepotRoad = AIRoad.BuildRoad(depot_tile, depot_front);
							if(!buildDepotRoad)
							{
								switch(AIError.GetLastError())
								{
									case AIError.ERR_NOT_ENOUGH_CASH: //wait for money
										Warning("Not enough money. Waiting for more");
										while(!AIRoad.BuildRoad(depot_tile, depot_front));
									break;
									case AIError.ERR_VEHICLE_IN_THE_WAY: //wait for stupid vehicle to get out of the way
										while(!AIRoad.BuildRoad(depot_tile, depot_front));
									break;
									case AIError.ERR_ALREADY_BUILT: //probably too much road, but build depot anyway TODO: check i'm right
									break;
									case AIRoad.ERR_ROAD_WORKS_IN_PROGRESS: //as above
									case AIError.ERR_LAND_SLOPED_WRONG: //TODO: handle it, give up for now
									case AIError.ERR_AREA_NOT_CLEAR: //TODO: handle it, give up for now
									case AIRoad.ERR_ROAD_ONE_WAY_ROADS_CANNOT_HAVE_JUNCTIONS: //can't happen?
									default:
										Warning("Unhandled error while building depot: " + AIError.GetLastErrorString() + ". Trying again");
											continue;
									break;
								}
							}
							local buildDepot = AIRoad.BuildRoadDepot(depot_tile, depot_front);
							if(!buildDepot)
							{
								switch(AIError.GetLastError())
								{
									case AIError.ERR_NOT_ENOUGH_CASH:
										Warning("Not enough money. Waiting for more");
										while(!AIRoad.BuildRoadDepot(depot_tile, depot_front));
										Info("Depot successfully built");
											return depot_tile;
									break;
									case AIError.ERR_FLAT_LAND_REQUIRED:
									case AIError.ERR_AREA_NOT_CLEAR: //TODO: handle them, for now just give up and try somewhere else
									default:
										Warning("Unhandled error while building depot: " + AIError.GetLastErrorString() + ". Trying again");
										continue;
									break;
								}
							}
							Info("Depot successfully built");
								return depot_tile;
						}
					}
					range++; // the found options had no road connections; enlarge search area
				}
				else
				{
					range++;
					area.Clear;
				}
			}
			Warning("Depot building in " + AITown.GetName(town) + " failed");
				return null;
		}
	}

function Builder_BusRoute::getRoadTile(tile) //from otvi
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
		if (adjacent.Count())
			return adjacent.Begin();
		else
			return null;
	}

function Builder_BusRoute::DealWithBuildRouteErrors(err)
	{
		switch(err)
		{
			case AIError.ERR_VEHICLE_IN_THE_WAY:
				Warning("Building road failed temporarily - vehicle in the way");
					return 2
			break;
			case AIRoad.ERR_ROAD_WORKS_IN_PROGRESS:
				// good, someone else is building this, skip tile
					return 1;
			break;
			case AIError.ERR_ALREADY_BUILT:
				// even better; someone else already built this; silent ignore
					return 1;
			break;
			case AIError.ERR_LAND_SLOPED_WRONG:
				Error("Building road failed - wrong slope");
				// TODO terraform
			case AIError.ERR_AREA_NOT_CLEAR:
				Warning("Building road failed: not clear, demolishing tile..");
					return 3;
			break;
			case AIRoad.ERR_ROAD_ONE_WAY_ROADS_CANNOT_HAVE_JUNCTIONS:
				Error("Building road failed - no junctions on one way roads allowed");
				// hopefully can't happen? nobody will ever use those...
					return null;
			case AIError.ERR_NOT_ENOUGH_CASH:
				Warning("Not enough money to build road. Waiting for more");
					return 4;
			break;
			default:
				Warning("Unknown error during road building " + AIError.GetLastErrorString());
					return null;
			break;	// no clue what this is; silent ignore for now
		}
	}

function Builder_BusRoute::Info(string)
	{
		AILog.Info(Util.GameDate() + " [Bus Route Builder] " + string + ".");
	}


function Builder_BusRoute::Warning(string)
	{
		AILog.Warning(Util.GameDate() + " [Bus Route Builder] " + string + ".");
	}

function Builder_BusRoute::Error(string)
	{
		AILog.Error(Util.GameDate() + " [Bus Route Builder] " + string + ".");
	}

function Builder_BusRoute::Debug(string)
	{
		AILog.Warning(Util.GameDate() + " [Bus Route Builder] DEBUG: " + string + ".");
		AILog.Warning(Util.GameDate() + " [Bus Route Builder] (if you see this, please inform the AI Dev in charge, as it was supposed to be removed before release)");
	}
