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
        var colors = ["#f00", "#0f0", "#00f", "#ff0", "#0ff", "#f0f"];

        F.raphael.bindGraph(F.svgData.bindGraph(F.scale.bindGraph(graph, {
            scale: scale,
            offset: { x: 30, y: 10 }
        })), {
            dotRadius: 6,
            canvas: canvas,
            colors: colors
        });

        graph.graphBranches(capillary.branch.fromArray(data));
    }
}());