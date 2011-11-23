// Load fragments with XMLHttpRequest
(function () {
    function loadPage(url, target, errorMessage) {
        jQuery.ajax({
            url: url,
            success: function (responseText) {
                target.html(responseText);

                target.find("[data-gts-target]").click(function () {
                    var attr = $(this).attr("data-gts-target");
                    loadPage(this.href, attr == "parent" ? target : $(attr));

                    return false;
                });
            },
            error: function () {
                if (errorMessage) {
                    target.html(errorMessage);
                }
            }
        });
    }

    $("[data-gts-source]").each(function () {
        var el = $(this);
        loadPage(el.attr("data-gts-source"), el, el.attr("data-gts-source-error"));
    });
}());
