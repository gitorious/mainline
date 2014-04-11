/** @jsx React.DOM */

var InlineCommentsSection = React.createClass({

  getInitialState: function() {
    return { comments: this.props.comments, formVisible: false };
  },

  render: function() {
    var style = {};
    if (this.state.comments.length === 0 && !this.state.formVisible) {
      style.display = 'none';
    }

    return (
      <div className="gts-comments" style={style}>
        <CommentsList comments={this.state.comments} />
        {this.renderForm()}
      </div>
    )
  },

  renderForm: function() {
    if (this.props.createCommentUrl) {
      if (this.state.formVisible) {
        return <AddCommentForm url={this.props.createCommentUrl}
                               lines={this.props.lines}
                               context={this.props.context}
                               path={this.props.path}
                               onSuccess={this.appendComment}
                               onClose={this.closeForm}
                               initialFocus={true} />;
      } else {
        return <AddCommentButton onClick={this.openForm} />;
      }
    }
  },

  openForm: function() {
    this.setState({ formVisible: true });
  },

  closeForm: function() {
    this.setState({ formVisible: false });
  },

  appendComment: function(comment) {
    var comments = this.state.comments.concat([comment]);
    this.setState({ comments: comments, formVisible: false });
  },

});
