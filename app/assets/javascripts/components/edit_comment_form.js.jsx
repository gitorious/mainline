/** @jsx React.DOM */

var EditCommentForm = React.createClass({

  getInitialState: function() {
    return { processing: false, error: null };
  },

  render: function() {
    var error;
    if (this.state.error) {
      error = <span className="error">{this.state.error}</span>;
    }

    return (
      <div className="gts-comment-form">
        <h3>Edit comment</h3>
        <MarkdownEditor ref="editor" initialText={this.props.comment.body} initialFocus={true} />
        <div className="row">
          {error}
          <div className="form-actions">
            <SubmitButton text="Update" onClick={this.handleSubmit} processing={this.state.processing} />
            <button type="button" className="btn" onClick={this.handleCancel}>Cancel</button>
          </div>
        </div>
      </div>
    );
  },

  handleSubmit: function() {
    this.setError(null);

    var body = this.refs.editor.getText();

    if (!body.match(/^\s*$/)) {
      this.setProcessing(true);

      var comment = { body: body };
      var data = { comment: comment, utf8: "✓" };

      var req = $.ajax({
        url:      this.props.comment.updateUrl,
        method:   "put",
        dataType: 'json',
        data:     data
      });

      req.done(function(data) {
        this.setProcessing(false);
        this.props.onSuccess(data);
      }.bind(this));

      req.fail(function(jqXHR, textStatus, errorThrown) {
        var message;

        if (jqXHR.responseText[0] == '{') {
          try {
            var json = JSON.parse(jqXHR.responseText);
            if (json.error) {
              message = json.error;
            }
          } catch (e) {
          }
        }

        if (!message) {
          message = "Communication with the server failed. Please try again in a minute.";
        }

        this.setError(message);
        this.setProcessing(false);
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
