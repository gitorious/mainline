/*global dome, cull*/
this.gts = this.gts || {};

gts.mergeRequest = (function (e) {
    function addDeleteStatusButton(parent, action) {
        action = typeof action === "string" ? action : "delete";
        parent.innerHTML += "<a href=\"#\" data-gts-action=\"" + action +
            "\"><i class=\"icon icon-remove\"></i> Remove</a>";
    }

    function addStatusButton() {
        return e.a({
            href: "#",
            data: { "gts-action": "add" },
            className: "btn"
        }, "Add status");
    }

    function addRow(parent, tpl) {
        var id = new Date().getTime();
        var tr = e.tr();
        tr.innerHTML = tpl.replace(/MRSID/g, id).replace(/<\/?tr>/g, "");
        parent.appendChild(tr);
        var cells = parent.getElementsByTagName("td");
        addDeleteStatusButton(cells[cells.length - 1], "undo-new");
    }

    function handleClick(action, link, table, tpl) {
        var containingCell = link.parentNode;
        var containingRow = containingCell.parentNode;

        if (action === "undo-new") {
            dome.remove(containingRow);
        }

        if (action === "delete") {
            containingRow.style.display = "none";
            containingCell.getElementsByTagName("input")[0].value = "1";
        }

        if (action === "add") {
            addRow(table, tpl);
        }
    }

    function editStatuses(element, tpl) {
        cull.doall(addDeleteStatusButton, dome.byClass("gts-mrs-remove", element));
        dome.replace(dome.byClass("gts-mrs-add-ph", element)[0], addStatusButton());
        var table = element.getElementsByTagName("tbody")[0];

        // Add click listener
        dome.on(element, "click", function (e) {
            var action = dome.data.get("gts-action", e.target);
            if (!e.target.href || !action) { return; }
            e.preventDefault();
            e.stopPropagation();
            handleClick(action, e.target, table, tpl);
        });
    };

    return {
        editStatuses: editStatuses
    };
}(dome.el));
