/** @jsx React.DOM */

var CommentsSection = React.createClass({

  getInitialState: function() {
    return { comments: this.props.comments };
  },

  render: function() {
    return (
      <div className="gts-comments">
        <CommentsList comments={this.state.comments} />
        {this.renderForm()}
      </div>
    );
  },

  renderForm: function() {
    if (this.props.createCommentUrl) {
      return (
        <div className="gts-new-comment">
          <AddCommentForm url={this.props.createCommentUrl}
                          onSuccess={this.appendComment} />
        </div>
      );
    }
  },

  appendComment: function(comment) {
    var comments = this.state.comments.concat([comment]);
    this.setState({ comments: comments });
  },

});
