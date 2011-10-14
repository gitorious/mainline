(function () {
    var el = document.getElementById("capillary-log");
    if (!el) return;

    var $el = jQuery(el);
    $el.addClass("loading");
    el.innerHTML = "";

    var text = document.createElement("span");
    text.innerHTML = "Loading data...";

    var spinner = new Spinner({
        lines: 8,
        length: 2,
        width: 2,
        radius: 3,
        color: "#000",
        speed: 1,
        trail: 100,
        shadow: false
    }).spin();

    spinner.el.style.top = "10px";
    el.appendChild(spinner.el);
    el.appendChild(text);

    jQuery.ajax(el.getAttribute("data-capillary-url"), {
        beforeSend: function(jqXHR, settings) {},
        success: function (data) {
            $el.removeClass("loading");
            el.innerHTML = "";

            graphData(el, data, {
                idUrl: el.getAttribute("data-id-url"),
                messageUrl: el.getAttribute("data-message-url")
            });
        },
        error: function () {
            el.innerHTML = "Failed fetching graph data. Please try again or report the problem if it persists";
        }
    });

    function graphData(view, data, options) {
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
        var canvas = new Raphael(view, (data.length + 1) * scale, commits * scale);

        var dotRadius = 6;
        var colors = ["#3d4250", "#5ea861", "#d36c6d", "#5b82d2", "#ccc62e", "#d28e23",
                      "#917549", "#9198aa", "#5bbad2", "#65ccab", "#92de2f", "#8a2c2c",
                      "#855bd2", "#c157c8"];

        var scaled = F.scale.bindGraph(graph, {
            scale: scale,
            offset: { x: 30, y: 10 }
        });

        F.raphael.bindGraph(F.svgData.bindGraph(scaled), {
            dotRadius: dotRadius,
            canvas: canvas,
            dotColors: colors
            /*,lineColors: colors*/
        });

        F.messageMarkup.bindGraph(scaled, {
            offset: [0, -(dotRadius + 2)],
            root: view,
            idUrl: options.idUrl,
            messageUrl: options.messageUrl
            /*,renderRefTypes: ["tags", "heads"]*/
        });

        graph.graphBranches(capillary.branch.fromArray(data));
    }
}());