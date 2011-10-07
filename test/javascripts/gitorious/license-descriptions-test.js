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
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#--
*/

function optionsSetUp() {
    /*:DOC select = <select>
        <option value="A">A</option>
        <option value="B" data-description="Second">B</option>
        <option value="C" data-description="<strong>Third</strong>">C</option>
      </select>*/

    this.options = jQuery(this.select).find("option");
}

TestCase("ParseLicenseDetailsTest", {
    setUp: optionsSetUp,

    "test should return array of licenses": function () {
        var licenses = gitorious.parseLicenseDetails(this.options);

        assertEquals(3, licenses.length);
    },

    "test should get name and description of license": function () {
        var licenses = gitorious.parseLicenseDetails(this.options);

        assertEquals("B", licenses[1].name);
        assertEquals("Second", licenses[1].description);
    }
});

TestCase("RenderLicenseDescriptionsTest", {
    setUp: function () {
        this.licenses = [
            { name: "BSD", description: "Keep the copyright" },
            { name: "MIT", description: "<strong>No guarantees, no strings attached</strong>" }];
    },

    "test should return markup as a string": function () {
        var markup = gitorious.renderLicenseDescriptions(this.licenses);

        assertMatch(/BSD/, markup);
        assertMatch(/MIT/, markup);
    },

    "test should format markup as definition list": function () {
        var markup = gitorious.renderLicenseDescriptions(this.licenses);

        assertMatch(/<dl class="licenses">/, markup);
        assertMatch(/<dt>BSD/, markup);
        assertMatch(/<dd>Keep the copyright/, markup);
        assertMatch(/<dd><strong>No guarantees/, markup);
    },

    "test should render empty list as blank string": function () {
        var markup = gitorious.renderLicenseDescriptions([]);

        assertEquals("", markup);
    },

    "test should render no list as blank string": function () {
        var markup = gitorious.renderLicenseDescriptions();

        assertEquals("", markup);
    }
});

TestCase("DisplayDescriptionsOnChangeTest", {
    setUp: function () {
        optionsSetUp.call(this);
        this.container = document.createElement("div");
        this.container.appendChild(this.select);
        this.select = jQuery(this.select);
    },

    "test should add element to parent on change": function () {
        gitorious.renderLicenseDescriptionOnChange(this.options);

        this.options[1].selected = true;
        this.select.trigger("change");

        assertEquals(2, this.container.childNodes.length);
        assertTagName("div", this.container.childNodes[1]);
        assertClassName("license-description", this.container.childNodes[1]);
        assertEquals("Second", this.container.childNodes[1].innerHTML);
    },

    "test should replace content in previously added element": function () {
        gitorious.renderLicenseDescriptionOnChange(this.options);

        this.options[1].selected = true;
        this.select.trigger("change");
        this.options[2].selected = true;
        this.select.trigger("change");

        assertEquals(2, this.container.childNodes.length);
        assertEquals("Third", this.container.childNodes[1].firstChild.innerHTML);
    },

    "test should remove meta element if option has no description": function () {
        gitorious.renderLicenseDescriptionOnChange(this.options);

        this.options[1].selected = true;
        this.select.trigger("change");
        this.options[0].selected = true;
        this.select.trigger("change");

        assertEquals(1, this.container.childNodes.length);
    },

    "test should re-add meta element": function () {
        gitorious.renderLicenseDescriptionOnChange(this.options);

        this.options[1].selected = true;
        this.select.trigger("change");
        this.options[0].selected = true;
        this.select.trigger("change");
        this.options[2].selected = true;
        this.select.trigger("change");

        assertEquals(2, this.container.childNodes.length);
        assertEquals("Third", this.container.childNodes[1].firstChild.innerHTML);
    }
});
