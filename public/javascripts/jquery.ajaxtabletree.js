function createTree(descriptor) {
  $(descriptor).filter('.collapsable').each(function(i, e){
    $(e).children('td:first').prepend(
    $('<span class="expander"> </span>').click(function(){
      var tr = $(this).closest('tr.collapsable').toggleClass('opened')
      var node = tr.attr('data-node-id')
      var level = parseInt(tr.attr('data-level') || 0) + 1
      if (!children_nodes[node]) $.getJSON(tree_list_nodes_url + node, function(data){
        children_nodes[node] = []
        var current_tr = tr
        $.each(data, function(i, n){
            var dir = n.shift()
            var id = n.shift()
            children_nodes[node].push(id)
            current_tr = $('<tr'+(dir ? ' class="collapsable"' : '') + ' data-node-id="' + id + '"' +
              ' data-level="' + level + '"><td style="padding-left: ' + level + 'em">' +
              n.join('</td><td>')+'</td></tr>').insertAfter(current_tr)
            createTree(current_tr)
        })
      })
      else collapse(node, tr.hasClass('opened'))
    }))
  })
}

function collapse(node, expand) {
  $.each(children_nodes[node] || [], function(i, n) {
    var tr = $('tr[data-node-id="' + n + '"]')[expand ? 'show' : 'hide']()
    if (tr.hasClass(expand ? 'opened' : 'collapsable')) collapse(n, expand)
  })
}

children_nodes = {}
$(function(){
  tree_list_nodes_url = $('table.tree').attr('data-list-files-url')
  createTree('table.tree tr')
})

