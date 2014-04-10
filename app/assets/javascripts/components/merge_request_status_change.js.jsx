/** @jsx React.DOM */

var MergeRequestStatusChange = React.createClass({

  render: function() {
    var comment = this.props.comment;
    var from = <MergeRequestStatus status={comment.statusChangedFrom}
                                   isOpen={comment.statusChangedFromIsOpen} />;
    var to = <MergeRequestStatus status={comment.statusChangedTo}
                                 isOpen={comment.statusChangedToIsOpen} />;

    return <span>→ Status changed from {from} to {to} </span>;
  }

});
