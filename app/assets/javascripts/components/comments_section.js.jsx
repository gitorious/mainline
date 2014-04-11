/** @jsx React.DOM */

var CommentsSection = React.createClass({

  getInitialState: function() {
    return { comments: this.props.comments };
  },

  render: function() {
    return (
      <div className="gts-comments">
        {this.renderComments()}
        {this.renderForm()}
      </div>
    );
  },

  renderComments: function() {
    var comments = cull.map(function(comment) {
      return <Comment data={comment} />;
    }, this.state.comments);

    return comments;
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
