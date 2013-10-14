$(function() {

  $('.watched').each(function () {
    var $this = $(this);

    var makeCurrent = function (newCurrent, current) {
      $this.find(".filters a").removeClass("current");
      $(newCurrent).addClass("current");
    };

    var swapAndMakeCurrent = function (klass, current) {
      $this.find(".favorite." + klass).show();
      $this.find(".favorite:not(." + klass + ")").hide();
      makeCurrent(current);
    };

    $this.find(".filters a.all").addClass("current");
    $this.find(".filters a").css({"outline": "none"});

    $this.find(".filters a.all").click(function () {
      $this.find(".favorite").show();
      makeCurrent(this);
      return false;
    });

    $this.find(".filters a.repositories").click(function () {
      swapAndMakeCurrent("repository", this);
      return false;
    });

    $this.find(".filters a.merge-requests").click(function () {
      swapAndMakeCurrent("merge_request", this);
      return false;
    });

    $this.find(".filters a.mine").click(function () {
      swapAndMakeCurrent("mine", this);
      return false;
    });

    $this.find(".filters a.foreign").click(function () {
      swapAndMakeCurrent("foreign", this);
      return false;
    });
  });

});
