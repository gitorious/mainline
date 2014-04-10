/** @jsx React.DOM */

var MergeRequestStatus = React.createClass({

  render: function() {
    var klass = "label label-" + (this.props.isOpen ? "success" : "inverse");
    return <span className={klass}>{this.props.status}</span>;
  }

});
