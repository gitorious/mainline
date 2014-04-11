/** @jsx React.DOM */

var CommentsList = React.createClass({

  render: function() {
    var comments = cull.map(function(comment) {
      return <Comment data={comment} includeContext={this.props.includeContext} />;
    }.bind(this), this.props.comments);

    return <div className="gts-comments-list">{comments}</div>;
  }

});
