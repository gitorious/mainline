$(function () {
  $("#toggle_all_messages_checked").click(function() {
    $('table tr.message input[type=checkbox]').prop('checked', true);
    return false;
  });

  $("#toggle_all_unread_messages_checked").click(function() {
    $('table tr.message.unread input[type=checkbox]').prop('checked', true);
    return false;
  });
});
