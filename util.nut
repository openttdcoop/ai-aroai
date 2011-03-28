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


class Util
{
	DATE_2_DIGITS = 10;	///< Make sure the date always has 2 digits
}

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

function Util::Sqrt(i) //From Rondje
{
	if (i == 0) return 0; //Avoid divide by zero	
	local n = (i / 2) + 1; //Initial estimate, never low
	local n1 = (n + (i / n)) / 2;
	while (n1 < n) {
		n = n1;
		n1 = (n + (i / n)) / 2;
	}
	return n;
}

function Util::ClearAllSigns()
{
	local sign_list = AISignList();
	for(local i = sign_list.Begin(); !sign_list.IsEnd(); i = sign_list.Next()) {
		AISign.RemoveSign(i);
	}
}
