/*
 * This file is part of AroAI.
 *
 * Copyright (C) 2011 - Charles Pigott (aka Lord Aro)
 *
 * AroAI is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 2.
 * AroAI is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with OpenTTD. If not, see <http://www.gnu.org/licenses/>.
 */

class Manager
{
	/* Declare constants */
	LOAN_REDUCE_TO = 0;                ///< Amount of money to reduce loan to
	MONEY_BEFORE_LOAN_REDUCE = 750000; ///< Amount of money to have before reducing loan
}

function Manager::ManageLoan()
{
	/* TODO: Something else...
	 * ...or maybe not; it's all I ever do with my loan */
	if (AICompany.GetLoanAmount() == LOAN_REDUCE_TO) return; //Loan already been reduced to 0
	Util.Debug(0, 2, "Managing loan");
	if (AICompany.GetBankBalance(AICompany.COMPANY_SELF) >= MONEY_BEFORE_LOAN_REDUCE) {
		Util.Debug(0, 2, "The company now has more than £" + MONEY_BEFORE_LOAN_REDUCE + ". Reducing Loan to minimum");
		AICompany.SetLoanAmount(LOAN_REDUCE_TO);
		return;
	}
	AICompany.SetLoanAmount(AICompany.GetMaxLoanAmount()); //Why not?
}

function Manager::ManageEvents()
{
	local dealtWithEvent = null;
	if (AIEventController.IsEventWaiting()) {
		Util.Debug(0, 2, "Managing events");
	}
	while (AIEventController.IsEventWaiting()) {
		dealtWithEvent = true;
		local event = AIEventController.GetNextEvent();
		switch (event.GetEventType()) {
			case AIEvent.AI_ET_COMPANY_BANKRUPT:
				local companyname = AICompany.GetName(AIEventCompanyBankrupt.Convert(event).GetCompanyID());
				/* Can't always get company name because it's already gone */
				if (!companyname) Util.Debug(0, 2, "A company has gone bankrupt. Better luck next time..");
				else Util.Debug(0, 2, companyname + " has gone bankrupt. Better luck next time..");
				break;
			case AIEvent.AI_ET_COMPANY_IN_TROUBLE:
				local companyname = AICompany.GetName(AIEventCompanyInTrouble.Convert(event).GetCompanyID());
				Util.Debug(0, 2, companyname + " is in trouble and may go bankrupt soon");
				break;
			case AIEvent.AI_ET_COMPANY_MERGER:
				local oldcompanyname = AICompany.GetName(AIEventCompanyMerger.Convert(event).GetOldCompanyID());
				local newcompanyname = AICompany.GetName(AIEventCompanyMerger.Convert(event).GetNewCompanyID());
				Util.Debug(0, 2, oldcompanyname + " has been bought by " + newcompanyname);
				break;
			case AIEvent.AI_ET_COMPANY_NEW:
				local companyname = AICompany.GetName(AIEventCompanyNew.Convert(event).GetCompanyID());
				Util.Debug(0, 2, companyname + " has just started");
				break;
			case AIEvent.AI_ET_ENGINE_AVAILABLE:
				local eng = AIEventEngineAvailable.Convert(event).GetEngineID();
				local engname = AIEngine.GetName(eng);
				Util.Debug(0, 2, "New engine available: " + engname);
				VehicleManager.ProcessNewEngine(eng);
				break;
			case AIEvent.AI_ET_ENGINE_PREVIEW:
				AIEventEnginePreview.Convert(event).AcceptPreview();
				Util.Debug(0, 2, "Accepted a preview of " + AIEventEnginePreview.Convert(event).GetName());
				break;
			case AIEvent.AI_ET_VEHICLE_CRASHED:
				local veh = AIEventVehicleCrashed.Convert(event).GetVehicleID();
				local vehname = AIVehicle.GetName(veh);
				Util.Debug(1, 2, vehname + " has crashed");
				Util.Debug(1, 2, "Event is unhandled");
				break;
			case AIEvent.AI_ET_VEHICLE_LOST:
				local veh = AIEventVehicleLost.Convert(event).GetVehicleID();
				local vehname = AIVehicle.GetName(veh);
				Util.Debug(0, 2, vehname + " is lost");
				Util.Debug(1, 2, "Event is unhandled");
				break;
			/* Silent ignore these
			 * STATION_FIRST_VEHICLE will almost certainly never be handled
			 * May deal with the others at some point */
			case AIEvent.AI_ET_VEHICLE_UNPROFITABLE:
			case AIEvent.AI_ET_STATION_FIRST_VEHICLE:
			case AIEvent.AI_ET_INDUSTRY_OPEN:
			case AIEvent.AI_ET_INDUSTRY_CLOSE:
			case AIEvent.AI_ET_SUBSIDY_OFFER:
			case AIEvent.AI_ET_SUBSIDY_OFFER_EXPIRED:
			case AIEvent.AI_ET_SUBSIDY_AWARDED:
			case AIEvent.AI_ET_SUBSIDY_EXPIRED:
			case AIEvent.AI_ET_DISASTER_ZEPPELINER_CRASHED:
			case AIEvent.AI_ET_DISASTER_ZEPPELINER_CLEARED:
				break;
			/* These are unhandled (and will be handled in future) */
			case AIEvent.AI_ET_COMPANY_ASK_MERGER: //TODO: Deal with it depending on amount of money
			default:
				Util.Debug(1, 2, "Event is unhandled");
				break;
		}
	}
	if (dealtWithEvent) {
		Util.Debug(0, 2, "No more events to manage");
	}
}

function Manager::GetEventName(event) //OUT OF USE FOR NOW
{//TODO: Switch round the debug: display when event is unhandled
	/* No function to get the name of events, so: 
	 * False return cases are silent ignores*/
	switch (event) {
		case AIEvent.AI_ET_INVALID:			return "AI_ET_INVALID";
		case AIEvent.AI_ET_TEST:			return "AI_ET_TEST";
		case AIEvent.AI_ET_SUBSIDY_OFFER:		return false;
		case AIEvent.AI_ET_SUBSIDY_OFFER_EXPIRED:	return false;
		case AIEvent.AI_ET_SUBSIDY_AWARDED:		return false;
		case AIEvent.AI_ET_SUBSIDY_EXPIRED:		return false;
		case AIEvent.AI_ET_ENGINE_PREVIEW:		return "AIEventEnginePreview";
		case AIEvent.AI_ET_COMPANY_NEW:			return "AIEventCompanyNew";
		case AIEvent.AI_ET_COMPANY_IN_TROUBLE:		return "AIEventCompanyInTrouble";
		case AIEvent.AI_ET_COMPANY_ASK_MERGER:		return "AIEventCompanyAskMerger";
		case AIEvent.AI_ET_COMPANY_MERGER:		return "AIEventCompanyMerger";
		case AIEvent.AI_ET_COMPANY_BANKRUPT:		return "AIEventCompanyBankrupt";
		case AIEvent.AI_ET_VEHICLE_CRASHED:		return "AIEventVehicleCrashed";
		case AIEvent.AI_ET_VEHICLE_LOST:		return "AIEventVehicleLost";
		case AIEvent.AI_ET_VEHICLE_WAITING_IN_DEPOT:	return "AIEventVehicleWaitingInDepot";
		case AIEvent.AI_ET_VEHICLE_UNPROFITABLE:	return false;
		case AIEvent.AI_ET_INDUSTRY_OPEN:		return false;
		case AIEvent.AI_ET_INDUSTRY_CLOSE:		return false;
		case AIEvent.AI_ET_ENGINE_AVAILABLE:		return "AIEventEngineAvailable";
		case AIEvent.AI_ET_STATION_FIRST_VEHICLE:	return false;
		case AIEvent.AI_ET_DISASTER_ZEPPELINER_CRASHED: return false;
		case AIEvent.AI_ET_DISASTER_ZEPPELINER_CLEARED: return false;
		default:					return "Unknown event name";
	}
}

