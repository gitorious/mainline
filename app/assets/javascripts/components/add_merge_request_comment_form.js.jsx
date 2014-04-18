/** @jsx React.DOM */

var AddMergeRequestCommentForm = React.createClass({

  getInitialState: function() {
    return {
      processing:         false,
      error:              false,
      mergeRequestStatus: this.props.currentMergeRequestStatus,
      watch:              false
    };
  },

  render: function() {
    var error;
    var statusSelect;
    var addToFavorites;

    if (this.props.mergeRequestStatuses.length > 0) {
      var options = [<option value=""></option>];
      options = options.concat(cull.map(function(status) {
        return <option value={status}>{status}</option>
      }.bind(this), this.props.mergeRequestStatuses));

      statusSelect =
        <div className="control-group">
          <div className="controls">
            <label className="control-label">State</label>
            <select ref="status" value={this.state.mergeRequestStatus} onChange={this.handleStatusChange}>{options}</select>
          </div>
        </div>;
    }

    if (this.props.showAddToFavorites) {
      addToFavorites =
        <label className="checkbox">
          <input type="checkbox" checked={this.state.watch} onChange={this.handleWatchChange} />
          Start watching (to stop watching this merge request later simply click the "Unwatch" button at the top of this page)
        </label>;
    }

    if (this.state.error) {
      error = <span className="error">Communication with the server failed. Please try again in a minute.</span>;
    }

    return (
      <div className="gts-new-comment">
        <div className="gts-comment-form">
          <h3>Add comment</h3>
          <MarkdownEditor ref="editor" />
          <div className="row">
            {statusSelect}
            {addToFavorites}
            {error}
            <div className="form-actions">
              <SubmitButton text="Comment" onClick={this.handleSubmit} processing={this.state.processing} />
            </div>
          </div>
        </div>
      </div>
    );
  },

  handleStatusChange: function(event) {
    this.setState({ mergeRequestStatus: event.target.value });
  },

  handleWatchChange: function(event) {
    this.setState({ watch: event.target.checked });
  },

  handleSubmit: function() {
    this.setError(false);

    var body = this.refs.editor.getText();

    if (!body.match(/^\s*$/) || this.state.mergeRequestStatus && this.state.mergeRequestStatus !== this.props.currentMergeRequestStatus) {
      this.setProcessing(true);

      var comment = { body: body, state: this.state.mergeRequestStatus };
      var data = { comment: comment, utf8: "✓" };

      if (this.state.watch) {
        data.add_to_favorites = '1';
      }

      var req = $.ajax({
        url:      this.props.url,
        method:   "post",
        dataType: 'json',
        data:     data
      });

      req.done(function(data) {
        this.setProcessing(false);
        this.props.onSuccess(data);
      }.bind(this));

      req.fail(function() {
        this.setProcessing(false);
        this.setError(true);
      }.bind(this));
    }
  },

  setProcessing: function(processing) {
    this.setState({ processing: processing });
  },

  setError: function(error) {
    this.setState({ error: error });
  },

  handleCancel: function(event) {
    event.preventDefault();
    this.props.onClose();
  }

});
