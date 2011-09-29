/*
 * This file is part of AroAI.
 *
 * Copyright (C) 2011 - Charles Pigott (aka Lord Aro)
 *
 * AroAI is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 2.
 * AroAI is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with OpenTTD. If not, see <http://www.gnu.org/licenses/>.
 */

/** @file util.nut Some utility functions, including debugs. */

class Util
{
	/* Declare constants */
	DATE_2_DIGITS = 10; ///< Make sure the date always has 2 digits
}

/**
 * Print a debug message to the AI debug window.
 * @param debug_level The specific debug function to use, e.g. Info or Error.
 * @param classname Which class anme to output with the debug statement, so you know where the debug has come from.
 * @param string Specific string to print.
 * @param fullstop Should a fullstop be printed on the end? Default = true.
 * @todo Move classnamestr table to global scope.
 */
function Util::Debug(debug_level, classname, string, fullstop = true)
{
	local fullstopstr = ".";
	if (fullstop = false) fullstopstr = "";

	local classnamestr = [
		"AroAI",
		"Bus Route Builder",
		"Manager",
		"Vehicle Manager",
		"END"
		];

	switch (debug_level) {
		case 0: // Info
			AILog.Info(GameDate() + " [" + classnamestr[classname] + "] " + string + fullstopstr);
			break;
		case 1: // Warning
			AILog.Warning(GameDate() + " [" + classnamestr[classname] + "] " + string + fullstopstr);
			break;
		case 2: // Error
			AILog.Error(GameDate() + " [" + classnamestr[classname] + "] " + string + fullstopstr);
			break;
		case 3: // Debug
		default:
			AILog.Warning(GameDate() + " [" + classnamestr[classname] + "] " + string + fullstopstr);
			AILog.Warning(GameDate() + " [" + classnamestr[classname] + "] (If you see this, please inform an AI dev, as it was supposed to be removed before release)");
			break;
	}

}

/**
 * Get the game date, as a string, in the format dd/mm/yyyy.
 */
function Util::GameDate()
{
	local date = AIDate.GetCurrentDate();
	local year = AIDate.GetYear(date);
	local month = AIDate.GetMonth(date);
	if(month < DATE_2_DIGITS) {
		month = "0" + month;
	}
	local day = AIDate.GetDayOfMonth(date);
	if(day < DATE_2_DIGITS) {
		day = "0" + day;
	}
	return day + "/" + month + "/" + year;
}

/**
 * Simpler Sqrt function.
 * Originally from Rondje Om De Kerk.
 * @param i Number to get Sqrt of.
 * @return Sqrt of \c i.
 * @todo Check if it is actually needed, and act accordingly.
 */
function Util::Sqrt(i)
{
	if (i == 0) return 0; // Avoid divide by zero
	local n = (i / 2) + 1; // Initial estimate, never low
	local n1 = (n + (i / n)) / 2;
	while (n1 < n) {
		n = n1;
		n1 = (n + (i / n)) / 2;
	}
	return n;
}

/**
 * Remove all signs from the map
 */
function Util::ClearAllSigns()
{
	local sign_list = AISignList();
	for (local i = sign_list.Begin(); !sign_list.IsEnd(); i = sign_list.Next()) {
		AISign.RemoveSign(i);
	}
}
