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
        <AddCommentForm url={this.props.createCommentUrl}
                        onSuccess={this.appendComment} />
      );
    }
  },

  appendComment: function(comment) {
    var comments = this.state.comments.concat([comment]);
    this.setState({ comments: comments });
  },

});
