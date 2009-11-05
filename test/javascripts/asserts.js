/*
  #--
  #   Copyright (C) 2009 Christian Johansen <christian@shortcut.no>
  #   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
  #
  #   This program is free software: you can redistribute it and/or modify
  #   it under the terms of the GNU Affero General Public License as published by
  #   the Free Software Foundation, either version 3 of the License, or
  #   (at your option) any later version.
  #
  #   This program is distributed in the hope that it will be useful,
  #   but WITHOUT ANY WARRANTY; without even the implied warranty of
  #   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  #   GNU Affero General Public License for more details.
  #
  #   You should have received a copy of the GNU Affero General Public License
  #   along with this program.  If not, see <http://www.gnu.org/licenses/>.
  #-- 
*/
function assertThrows(msg, callback, error) {
    if (arguments.length == 1) {
        // assertThrows(callback)
        callback = msg;
        msg = "";
    } else if (arguments.length == 2) {
        if (typeof callback != "function") {
            // assertThrows(callback, type)
            error = callback;
            callback = msg;
            msg = "";
        } else {
            // assertThrows(msg, callback)
            msg += " ";
        }
    } else {
        // assertThrows(msg, callback, type)
        msg += " ";
    }

    try {
        callback();
    } catch(e) {
        if (error && e.name != error) {
            fail(msg + "expected " + error + " but was " + e.name);
        }

        jstestdriver.assertCount++;

        return true;
    }

    fail(msg + "expected to throw exception, but didn't");
}
