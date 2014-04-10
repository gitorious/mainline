/** @jsx React.DOM */

var TimeAgo = React.createClass({

  render: function() {
    var time = timeago.parse(this.props.time);
    return <span title={this.props.time}>{timeago.relative(time)}</span>;
  },

  componentDidMount: function() {
    this.intervalId = setInterval(this.update, 1000);
  },

  componentWillUnmount: function() {
    clearInterval(this.intervalId);
  },

  update: function() {
    this.setState({});
  }

});
