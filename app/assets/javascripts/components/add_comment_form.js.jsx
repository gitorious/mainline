/** @jsx React.DOM */

var AddCommentForm = React.createClass({

  getInitialState: function() {
    return { processing: false, error: false };
  },

  render: function() {
    var cancelButton;
    var error;

    if (this.props.onClose) {
      cancelButton = <button type="button" className="btn" onClick={this.handleCancel}>Cancel</button>;
    }

    if (this.state.error) {
      error = <span className="error">Communication with the server failed. Please try again in a minute.</span>;
    }

    return (
      <div className="gts-new-comment">
        <div className="gts-comment-form">
          <h3>Add comment</h3>
          <MarkdownEditor ref="editor" initialFocus={this.props.initialFocus} />
          <div className="row">
            {error}
            <div className="form-actions">
              <SubmitButton text="Comment" onClick={this.handleSubmit} processing={this.state.processing} />
              {cancelButton}
            </div>
          </div>
        </div>
      </div>
    );
  },

  handleSubmit: function() {
    this.setError(false);

    var body = this.refs.editor.getText();

    if (!body.match(/^\s*$/)) {
      this.setProcessing(true);

      var comment = {
        body: body,
        lines: this.props.lines,
        context: this.props.context,
        path: this.props.path
      }

      var data = { comment: comment, utf8: "✓" };

      var req = $.ajax({
        url:      this.props.url,
        method:   "post",
        dataType: 'json',
        data:     data
      });

      req.done(function(data) {
        this.setProcessing(false);
        this.clear();
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

  clear: function() {
    this.refs.editor.setText('');
  },

  handleCancel: function(event) {
    event.preventDefault();
    this.props.onClose();
  }

});
