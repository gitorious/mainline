$(function () {
  $("#toggle_all_messages_checked").click(function() {
    $('table tr input[type=checkbox]').prop('checked', true);
    return false;
  });

  $("#toggle_all_unread_messages_checked").click(function() {
    $('table tr.unread input[type=checkbox]').prop('checked', true);
    return false;
  });
});
