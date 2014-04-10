/** @jsx React.DOM */

var CommentContext = React.createClass({

  render: function() {
    return (
      <div className="gts-comment-context">
        <blockquote>
          <pre className="diff-comment-context">
            <code>{this.props.comment.context}</code>
          </pre>
        </blockquote>
      </div>
    );
  },

});
