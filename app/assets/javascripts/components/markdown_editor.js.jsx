/** @jsx React.DOM */

var MarkdownEditor = React.createClass({

  getInitialState: function() {
    return { currentText: this.props.initialText || "" };
  },

  render: function() {
    return (
      <div className="row-fluid gts-markdown-editor">
        <div className="span6">
          <textarea ref="input" onChange={this.handleTextChange}></textarea>
          <span className="hint">Markdown supported</span>
        </div>
        <div className="span6">
          <p><strong>Preview:</strong></p>
          <MarkdownPreview text={this.state.currentText} />
        </div>
      </div>
    );
  },

  componentDidMount: function() {
    var textarea = this.refs.input.getDOMNode();
    textarea.focus();
    textarea.innerHTML = this.state.currentText;
  },

  handleTextChange: function(event) {
    var text = this.refs.input.getDOMNode().value;
    this.setState({ currentText: text });
  },

  getText: function() {
    return this.state.currentText;
  }

});
