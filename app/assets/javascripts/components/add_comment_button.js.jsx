/** @jsx React.DOM */

var AddCommentButton = React.createClass({

  render: function() {
    return (
      <div className="gts-new-comment">
        <button className="btn btn-default" onClick={this.handleClick}>Add comment</button>
      </div>
    );
  },

  handleClick: function(event) {
    event.preventDefault();
    this.props.onClick();
  }

});
