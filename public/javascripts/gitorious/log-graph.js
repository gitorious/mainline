(function () {
    var el = document.getElementById("capillary-log");
    if (!el) return;

    jQuery.ajax(el.getAttribute("data-capillary-url"), {
        beforeSend: function(jqXHR, settings) {},
        success: function (data) {
            el.innerHTML = "";
            graphData(el, data);
        }
    });

    el.innerHTML = "Loading data...";

    function graphData(view, data) {
        view.style.position = "relative";
        var scale = 25;
        var i, j, k, l, commits = 0, used = {};

        for (i = 0, l = data.length; i < l; ++i) {
            for (j = 0, k = data[i].length; j < k; ++j) {
                if (!used[data[i][j].id]) {
                    commits += 1;
                    used[data[i][j].id] = true;
                }
            }
        }

        var F = capillary.formatters;
        var graph = capillary.graph.create();
        var canvas = new Raphael(view, 600 /*data.length * scale*/, commits * scale);

        var colors = ["#18fd00", "#ffee33", "#29d0d0", "#dc0f0f", "#ff9233", "#1d38ab", "#e9debb",
                      "#a0a0a0", "#ffcdf3", "#10a600", "#8126c0", "#ffffff", "#575757"];

        var dotRadius = 6;

        var scaled = F.scale.bindGraph(graph, {
            scale: scale,
            offset: { x: 30, y: 10 }
        });

        F.raphael.bindGraph(F.svgData.bindGraph(scaled), {
            dotRadius: dotRadius,
            canvas: canvas,
            colors: colors
        });

        F.messageMarkup.bindGraph(scaled, {
            offset: [0, -(dotRadius + 2)],
            root: view,
            idUrl: "/gitorious/mainline/graph/{{id}}",
            messageUrl: "/gitorious/mainline/commit/{{id}}"
        });

        graph.graphBranches(capillary.branch.fromArray(data));
    }
}());