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
/*global gitorious, jQuery, document, window*/

(function (jQuery, g) {
    function changeClass(toggler, id) {
        var el = toggler.element;
        var cn = toggler.classNames;

        if (id != "between") {
            el.removeClass(cn.enabled).removeClass(cn.between).removeClass(cn.disabled);
        }

        el.addClass(cn[id]);
    }

    g.resourceToggler = {
        enabled: true,
        classNames: {
            enabled: "enabled",
            between: "waiting",
            disabled: "disabled"
        },

        toggleResource: function () {
            changeClass(this, "between");
            var toggler = this;

            jQuery.ajax({
                url: this.url,
                type: "post",
                data: { "_method": this.enabled ? "delete" : "post" },

                complete: function (xhr) {
                    toggler.url = xhr.getResponseHeader("Location");
                },

                success: this.toggleState.bind(this)
            });
        },

        toggleState: function () {
            var id = this.enabled ? "disabled" : "enabled";
            changeClass(this, id);
            this.enabled = !this.enabled;

            if (this.texts && this.element) {
                this.element.text(this.texts[id]);
            }
        }
    };

    g.toggleResource = function (element, opt) {
        element = jQuery(element);

        var toggler = jQuery.extend(g.create(g.resourceToggler), opt || {}, {
            enabled: element.attr("data-request-method") == "delete",
            element: element,
            url: element.attr("href")
        });

        element.click(function (e) {
            toggler.toggleResource();
            this.blur();
            e.preventDefault();
        });

        return toggler;
    };

    jQuery.fn.toggleResource = function (opt) {
        return this.each(function () {
            g.toggleResource(this, opt);
        });
    };
}(jQuery, gitorious));
