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
                                    onSuccess={this.handleCommentCreated}
                                    mergeRequestStatuses={this.props.mergeRequestStatuses}
                                    currentMergeRequestStatus={this.state.currentMergeRequestStatus}
                                    showAddToFavorites={this.props.showAddToFavorites} />
      )
    }
  },

  handleCommentCreated: function(comment) {
    window.location.reload();
  },

});
