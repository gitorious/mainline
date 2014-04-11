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

    return <div className="gts-comments" style={style}>{this.renderChildren()}</div>;
  },

  renderChildren: function() {
    var children = cull.map(function(comment) {
      return <Comment data={comment} />;
    }, this.state.comments);

    if (this.props.createCommentUrl) {
      var element;

      if (this.state.formVisible) {
        element = <AddCommentForm url={this.props.createCommentUrl}
                                  lines={this.props.lines}
                                  context={this.props.context}
                                  path={this.props.path}
                                  onSuccess={this.appendComment}
                                  onClose={this.closeForm} />;
      } else {
        element = <AddCommentButton onClick={this.openForm} />;
      }

      children = children.concat([<div className="gts-new-comment">{element}</div>]);
    }

    return children;
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
