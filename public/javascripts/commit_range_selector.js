function CommitRangeSelector(commitListUrl, targetBranchesUrl, statusElement) {
    this.commitListUrl = commitListUrl;
    this.targetBranchesUrl = targetBranchesUrl;
    this.statusElement = statusElement;
    this.endsAt = null;
    this.sourceBranchName = null;
    this.targetBranchName = null;
    this.REASONABLY_SANE_RANGE_SIZE = 50;

    this.endSelected = function (el) {
        this.endsAt = $(el);
        this.update();
    };

    this.onSourceBranchChange = function (event) {
        var sourceBranch = $("#merge_request_source_branch");

        if (sourceBranch) {
            this.sourceBranchSelected(sourceBranch);
        }
    };

    this.onTargetRepositoryChange = function (event) {
        $("#spinner").fadeIn();
        var serialized = $("#new_merge_request").serialize();

        $.post(this.targetBranchesUrl, serialized,
                function (data, responseText) {
                    if (responseText == "success") {
                        $("#target_branch_selection").html(data);
                        $("#spinner").fadeOut();
                    }
                }
              );

        this._updateCommitList();
    };

    this.onTargetBranchChange = function (event) {
        var targetBranch = $("#merge_request_target_branch").val();

        if (targetBranch) {
            this.targetBranchSelected(targetBranch);
        }
    };

    this.targetBranchSelected = function (branchName) {
        if (branchName != this.targetBranchName) {
            this.targetBranchName = branchName;
            this._updateCommitList();
        }
    };

    this.sourceBranchSelected = function (branchName) {
        if (branchName != this.sourceBranchName) {
            this.sourceBranchName = branchName;
            this._updateCommitList();
        }
    };

    this.update = function () {
        if (this.endsAt) {
            $(".commit_row").each(function () {
                $(this).removeClass("selected");
            });

            var selectedTr = this.endsAt.parent().parent();
            selectedTr.addClass("selected");
            var selectedTrCount = 1;

            selectedTr.nextAll().each(function () {
                $(this).addClass("selected");
                selectedTrCount++;
            });

            if (selectedTrCount > this.REASONABLY_SANE_RANGE_SIZE) {
                $("#large_selection_warning").slideDown();
            } else {
                $("#large_selection_warning").slideUp();
            }

            // update the status field with the selected range
            var to = selectedTr.find(".sha-abbrev a").html();
            var from = $(".commit_row:last .sha-abbrev a").html();
            $("." + this.statusElement).each(function () {
                $(this).html(from + ".." + to);
            });
        }
    };

    this._updateCommitList = function () {
        $("#commit_table").replaceWith('<p class="hint">Loading commits&hellip; ' +
                                       '<img src="/images/spinner.gif"/></p>');
        var serialized = $("#new_merge_request").serialize();
        $.post(this.commitListUrl, serialized,
               function (data, responseText) {
                    if (responseText === "success") {
                        $("#commit_selection").html(data);
                    }
                });
    };
}
