/*global cull, dome, console, gts*/
function uinitLogger(app, level) {
    if (typeof level === "string") {
        level = uinitLogger.levels.indexOf((level || "info").toLowerCase());
    }

    if (typeof level !== "number") {
        level = uinitLogger.DEBUG;
    }

    if (level <= uinitLogger.INFO) {
        app.on("init", function () {
            console.log("===========================");
            console.log("Attempting to load features");
            console.log("===========================");
        });
    }

    if (level <= uinitLogger.DEBUG) {
        app.on("loading", function (feature) {
            console.log("[Loading:", feature.name + "]");
        });

        app.on("reloading", function (feature) {
            console.log("[Re-loading:", feature.name + "]");
        });
    }

    if (level <= uinitLogger.INFO) {
        app.on("pending", function (feature) {
            var name = cull.prop("name");
            var reason, pending = cull.map(name, cull.select(function (f) {
                return !f.loaded;
            }, feature.dependencies()));

            if (pending.length > 0) {
                reason = "Waiting for ";
                reason += pending.length === 1 ? "dependency" : "dependencies";
                reason += " [" + pending.join(", ") + "]";
            }

            if (!reason && feature.elements) {
                if (dome.byClass(feature.elements).length === 0) {
                    reason = "No matching elements for selector ." +
                        feature.elements;
                }
            }

            if (!reason && !feature.nullable) {
                reason = "Feature produced null/undefined but is not nullable";
            }

            console.log("[Pending:", feature.name + "]", reason);
        });
    }

    if (level <= uinitLogger.INFO) {
        app.on("skip", function (feature) {
            console.log("[Skip:", feature.name + "]",
                        "Reload triggered, but input was unchanged");
        });
    }

    if (level <= uinitLogger.INFO) {
        app.on("loaded", function (feature, result) {
            console.log("[Load:", feature.name + "] =>", result);
        });
    }

    if (level <= uinitLogger.ERROR) {
        app.on("error", function (feature, err) {
            console.log("Error while loading", feature.name);
            console.log("  " + err.message);
            console.log("  " + err.stack);
        });
    }
}

uinitLogger.levels = ["debug", "info", "warn", "error"];

cull.doall(function (level, i) {
    uinitLogger[level.toUpperCase()] = i;
}, uinitLogger.levels);

uinitLogger(this.gts.app, uinitLogger.INFO);
