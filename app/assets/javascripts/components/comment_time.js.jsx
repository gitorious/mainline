/** @jsx React.DOM */

var CommentTime = React.createClass({

  render: function() {
    var comment = this.props.comment;

    var children = [<TimeAgo time={comment.createdAt} />];

    if (comment.updatedAt !== comment.createdAt) {
      children = children.concat([" (edited ", <TimeAgo time={comment.updatedAt} />, ")"]);
    }

    return <span><a href={"#c" + comment.id}>{children}</a></span>;
  }

});
