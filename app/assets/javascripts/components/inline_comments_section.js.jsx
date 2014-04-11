/** @jsx React.DOM */

var InlineCommentsSection = React.createClass({

  getInitialState: function() {
    return { comments: this.props.comments, formVisible: false };
  },

  render: function() {
    return (
      <div className="gts-comments">
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

  componentDidMount: function() {
    if (this.shouldParentBeHidden()) {
      this.hideParentRow();
    }
  },

  componentDidUpdate: function() {
    if (this.shouldParentBeHidden()) {
      this.hideParentRow();
    } else {
      this.showParentRow();

      // re-focus - workaround for the fact that showParentRow is called after textarea got focus
      var textarea = this.getDOMNode().querySelector('textarea');
      if (textarea) {
        textarea.focus();
      }
    }
  },

  hideParentRow: function() {
    // hide whole gts-diff-comment <tr>
    this.getDOMNode().parentNode.parentNode.style.display = 'none';
  },

  showParentRow: function() {
    // show gts-diff-comment <tr>
    this.getDOMNode().parentNode.parentNode.style.display = '';
  },

  shouldParentBeHidden: function() {
    return this.state.comments.length === 0 && !this.state.formVisible;
  },

  toggleForm: function() {
    this.setState({ formVisible: !this.state.formVisible });
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
