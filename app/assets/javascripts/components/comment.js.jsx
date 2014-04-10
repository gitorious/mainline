/** @jsx React.DOM */

var Comment = React.createClass({

  getInitialState: function() {
    return { comment: this.props.data, editing: false };
  },

  render: function() {
    var comment = this.state.comment;
    var children = [];

    if (this.state.editing) {
      children = children.concat([
        <EditCommentForm comment={comment}
                         onSuccess={this.handleUpdate}
                         onClose={this.handleEditClose} />
      ]);
    } else {
      var context;

      if (this.props.includeContext && comment.context) {
        context = <CommentContext comment={comment} />;
      }

      children = children.concat([
        <CommentHeader comment={comment}
                       includeContext={this.props.includeContext}
                       onEdit={this.handleEdit} />,
        context,
        <div className="gts-comment-body"
             dangerouslySetInnerHTML={{__html: comment.bodyHtml}} />
      ]);
    }

    return <div className="gts-comment">{children}</div>;
  },

  handleEdit: function() {
    this.setState({ editing: true });
  },

  handleEditClose: function() {
    this.setState({ editing: false });
  },

  handleUpdate: function(comment) {
    this.setState({ comment: comment, editing: false });
  }

});
