/*
#--
#   Copyright (C) 2011 Gitorious AS
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
#   along with this program. If not, see <http://www.gnu.org/licenses/>.
#--
*/

(function (G) {
    G.parseLicenseDetails = function (options) {
        var licenses = [];

        options.each(function () {
            licenses.push({
                name: this.innerHTML,
                description: this.getAttribute("data-description")
            });
        });

        return licenses;
    };

    G.renderLicenseDescriptions = function (licenses) {
        if (!licenses || licenses.length == 0) return "";
        var html = "<dl class=\"licenses\">";

        for (var i = 0, l = licenses.length; i < l; ++i) {
            html += "<dt>" + licenses[i].name + "</dt><dd>" +
                licenses[i].description + "</dd>";
        }

        return html + "</dl>";
    };

    G.renderLicenseDescriptionOnChange = function (options) {
        var parent = options[0].parentNode.parentNode, el;
        if (!parent) return;

        options.parent().change(function () {
            if (!el) {
                el = document.createElement("div");
                el.className = "license-description";
                parent.appendChild(el);
            }

            var desc = options[this.selectedIndex].getAttribute("data-description");

            if (!desc) {
                parent.removeChild(el);
                el = null;
            } else {
                el.innerHTML = desc;
            }
        });
    };
}(gitorious));