/** @jsx React.DOM */

var CommentHeader = React.createClass({

  getInitialState: function() {
    return { editable: !!this.props.comment.updateUrl };
  },

  render: function() {
    var comment = this.props.comment;
    var editButton;
    var contextLink;
    var statusChange;

    if (this.state.editable) {
      editButton = <EditButton onClick={this.handleEdit} />;
    }

    if (this.props.includeContext) {
      if (comment.firstLine !== null) {
        contextLink = <InlineCommentContext comment={comment} />;
      }

      if (comment.statusChangedTo) {
        statusChange = <MergeRequestStatusChange comment={comment} />;
      }
    }

    return (
      <div className="gts-comment-header">
        <CommentAuthor author={comment.author} />
        {contextLink}
        {statusChange}
        <div className="gts-comment-meta">
          <CommentTime comment={comment} /> {editButton}
        </div>
      </div>
    );
  },

  componentDidMount: function() {
    var comment = this.props.comment;

    if (comment.editableUntil) {
      var editableUntil = timeago.parse(comment.editableUntil);
      var now = new Date;
      var millis = editableUntil.getTime() - now.getTime();
      this.timeoutId = setTimeout(this.makeNotEditable, millis);
    }
  },

  componentWillUnmount: function() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId);
    }
  },

  makeNotEditable: function() {
    this.setState({ editable: false });
  },

  handleEdit: function() {
    this.props.onEdit();
  }

});
