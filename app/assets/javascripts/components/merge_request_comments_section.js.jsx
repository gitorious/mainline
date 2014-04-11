/** @jsx React.DOM */

var MergeRequestCommentsSection = React.createClass({

  getInitialState: function() {
    return {
      comments:                  this.props.comments,
      currentMergeRequestStatus: this.props.currentMergeRequestStatus
    };
  },

  render: function() {
    return (
      <div className="gts-comments">
        <CommentsList comments={this.state.comments} includeContext={true} />
        {this.renderForm()}
      </div>
    )
  },

  renderForm: function() {
    if (this.props.createCommentUrl) {
      return (
        <AddMergeRequestCommentForm url={this.props.createCommentUrl}
                                    onSuccess={this.appendComment}
                                    mergeRequestStatuses={this.props.mergeRequestStatuses}
                                    currentMergeRequestStatus={this.state.currentMergeRequestStatus} />
      )
    }
  },

  appendComment: function(comment) {
    if (comment.statusChangedTo) {
      window.location.reload();
    } else {
      var comments = this.state.comments.concat([comment]);
      this.setState({ comments: comments });
    }
  },

});
