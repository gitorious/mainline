/*
#--
#   Copyright (C) 2007-2009 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2009 Marius Mathiesen <marius.mathiesen@gmail.com>
#   Copyright (C) 2010 Christian Johansen <christian@shortcut.no>
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
/*jslint eqeqeq: false, plusplus: false, onevar: false*/
/*global $, document*/

$(document).ready(function () {
    // Message actions
    $(".message_actions a.mark_as_unread").click(function (event) {
        var link = $(this);

        $.post(link.attr("href"), "_method=put", function (data, response) {
            if (response === "success") {
                var parts = link.attr("href").split("/");
                $("#message_" + parts[parts.length - 2]).removeClass("unread");
                link.parent().slideUp();
            }              
        });

        event.preventDefault();
    });

    // Message selection toggling
    $("a#toggle_all_messages_checked").click(function (e) {
        $(".select_msg").each(function () {
            this.checked = (this.checked ? '' : 'checked');
        });

        e.preventDefault();
    });

    $("a#toggle_all_unread_messages_checked").click(function (e) {
        $(".select_msg").each(function () {
            this.checked = '';
        });

        $(".unread .select_msg").each(function () {
            this.checked = (this.checked ? '' : 'checked');
        });

        e.preventDefault();
    });
});
