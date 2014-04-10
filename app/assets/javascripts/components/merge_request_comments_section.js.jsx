/** @jsx React.DOM */

var MergeRequestCommentsSection = React.createClass({

  getInitialState: function() {
    return {
      comments:                  this.props.comments,
      currentMergeRequestStatus: this.props.currentMergeRequestStatus
    };
  },

  render: function() {
    return <div className="gts-comments">{this.renderChildren()}</div>;
  },

  renderChildren: function() {
    var children = cull.map(function(comment) {
      return <Comment data={comment}
                      includeContext={true} />;
    }, this.state.comments);

    if (this.props.createCommentUrl) {
      var form = <AddMergeRequestCommentForm url={this.props.createCommentUrl}
                                            onSuccess={this.appendComment}
                                            mergeRequestStatuses={this.props.mergeRequestStatuses}
                                            currentMergeRequestStatus={this.state.currentMergeRequestStatus} />

      children = children.concat([form]);
    }

    return children;
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
