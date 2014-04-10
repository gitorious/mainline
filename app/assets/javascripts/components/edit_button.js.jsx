/** @jsx React.DOM */

var EditButton = React.createClass({

  render: function() {
    return (
      <a href="#" className="btn" onClick={this.handleClick}><i className="icon icon-edit" /> Edit</a>
    );
  },

  handleClick: function(event) {
    event.preventDefault();

    if (this.props.onClick) {
      this.props.onClick();
    }
  }

});
