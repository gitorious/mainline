/** @jsx React.DOM */

var SubmitButton = React.createClass({

  render: function() {
    var spinner;

    if (this.props.processing) {
      spinner = <span className="spinner"></span>;
    }

    return <button className="btn btn-primary"
                   onClick={this.handleClick}
                   disabled={this.props.processing}>{this.props.text}{spinner}</button>
  },

  handleClick: function(event) {
    event.preventDefault();
    this.props.onClick();
  }

});
