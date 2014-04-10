/** @jsx React.DOM */

var InlineCommentContext = React.createClass({

  render: function() {
    var comment = this.props.comment;
    var shortSha = comment.sha1.substring(0, 7);

    return <span> commented on <a href={comment.htmlUrl}>{shortSha}</a></span>;
  }

});
