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


class Manager
	{
		event = null;
	}

function Manager::ManageLoan()
	{
		//TODO:something else :)
		//...or maybe not...it's all i ever do with my loan
		if(AICompany.GetLoanAmount() == 0)
			return;
		Info("Managing loan");
		if(AICompany.GetBankBalance(AICompany.COMPANY_SELF) >= 750000)
		{
			Info(AICompany.GetName("The company now has more than £750000. Reducing Loan to minimum");
			AICompany.SetLoanAmount(0);
				return;
		}
		AICompany.SetLoanAmount(AICompany.GetMaxLoanAmount()); //Why not?
	}

function Manager::ManageEvents()
	{
		if(AIEventController.IsEventWaiting())
		{
			Info("Managing events");
		}
		while (AIEventController.IsEventWaiting())
		{
			event = AIEventController.GetNextEvent();
			switch (event.GetEventType())
			{
				case AIEvent.AI_ET_COMPANY_ASK_MERGER:
					//TODO: deal with it depending on amount of money
				break;
				case AIEvent.AI_ET_COMPANY_BANKRUPT:
					local companyid = AIEventCompanyBankrupt.Convert(event).GetCompanyID();
					local companyname = AICompany.GetName(companyid);
					/*can't get company name because it already gone*/
					AILog.Info(Util.GameDate() + " [Manager] A company has gone bankrupt. FAILED!!"); 
				break;
				case AIEvent.AI_ET_COMPANY_IN_TROUBLE:
					local companyid = AIEventCompanyInTrouble.Convert(event).GetCompanyID();
					local companyname = AICompany.GetName(companyid);
					Info(companyname + " is in trouble and may go bankrupt soon");
				break;
				case AIEvent.AI_ET_COMPANY_MERGER:
					local oldcompanyid = AIEventCompanyMerger.Convert(event).GetOldCompanyID();
					local oldcompanyname = AICompany.GetName(oldcompanyid);
					local newcompanyid = AIEventCompanyMerger.Convert(event).GetNewCompanyID();
					local newcompanyname = AICompany.GetName(newcompanyid);
					if(newcompanyname)
					{
						Info(oldcompanyname + " has been bought by " + newcompanyname);
					}
				break;
				case AIEvent.AI_ET_COMPANY_NEW:
					local companyid = AIEventCompanyNew.Convert(event).GetCompanyID();
					local companyname = AICompany.GetName(companyid);
					Info("Welcome to " + companyname + ", which has just started");
				break;
				case AIEvent.AI_ET_ENGINE_AVAILABLE:
					local eng = AIEventEngineAvailable.Convert(event).GetEngineID();
					local engname = AIEngine.GetName(eng);
					Info("New engine available: " + engname);
				break;
				case AIEvent.AI_ET_ENGINE_PREVIEW:
					AIEventEnginePreview.Convert(event).AcceptPreview();
					Info("Accepted a preview of " + AIEventEnginePreview.Convert(event).GetName());
				break;
				case AIEvent.AI_ET_VEHICLE_CRASHED:
					local veh = AIEventVehicleCrashed.Convert(event).GetVehicleID();
					local vehname = AIVehicle.GetName(veh);
					Warning(vehname + " has crashed");
					//TODO: deal with it
				break;
				case AIEvent.AI_ET_VEHICLE_LOST:
					local veh = AIEventVehicleLost.Convert(event).GetVehicleID();
					local vehname = AIVehicle.GetName(veh);
					Info(vehname + " is lost");
				break;
				case AIEvent.AI_ET_VEHICLE_UNPROFITABLE:
					//TODO: deal with it
				break;
				default:
					//silent ignore the rest for now
				break;
			}
		}
		if(event)
		{
		Info("No more events to manage");
		}
	}

function Manager::Info(string)
	{
		AILog.Info(Util.GameDate() + " [Manager] " + string + ".");
	}


function Manager::Warning(string)
	{
		AILog.Warning(Util.GameDate() + " [Manager] " + string + ".");
	}

function Manager::Error(string)
	{
		AILog.Error(Util.GameDate() + " [Manager] " + string + ".");
	}

function Manager::Debug(string)
	{
		AILog.Warning(Util.GameDate() + " [Manager] DEBUG: " + string + ".");
		AILog.Warning(Util.GameDate() + " [Manager] (if you see this, please inform the AI Dev in charge, as it was supposed to be removed before release)");
	}
