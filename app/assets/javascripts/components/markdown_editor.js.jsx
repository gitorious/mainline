/** @jsx React.DOM */

var MarkdownEditor = React.createClass({

  getInitialState: function() {
    return { currentText: this.props.initialText || "", preview: false };
  },

  render: function() {
    var tabContent;

    if (this.state.preview) {
      tabContent = <MarkdownPreview text={this.state.currentText} />;
    } else {
      tabContent =
        <div>
          <textarea ref="input" value={this.state.currentText} onChange={this.handleTextChange}></textarea>
          <span className="hint">Markdown supported</span>
        </div>;
    }

    return (
      <div className="gts-markdown-editor">
        <ul className="nav nav-tabs">
          <li className={this.state.preview ? "" : "active"} onClick={this.handleWriteClick}><a href="#">Write</a></li>
          <li className={this.state.preview ? "active" : ""} onClick={this.handlePreviewClick}><a href="#">Preview</a></li>
        </ul>
        {tabContent}
      </div>
    );
  },

  componentDidMount: function() {
    if (this.props.initialFocus) {
      this.focusTextarea();
    }
  },

  componentDidUpdate: function(prevProps, prevState) {
    if (prevState.preview && !this.state.preview) {
      this.focusTextarea();
    }
  },

  focusTextarea: function() {
    var textarea = this.refs.input.getDOMNode();
    textarea.innerHTML = '';
    textarea.focus();
    textarea.innerHTML = this.state.currentText;
  },

  handleWriteClick: function(event) {
    event.preventDefault();
    this.setState({ preview: false });
  },

  handlePreviewClick: function(event) {
    event.preventDefault();
    this.setState({ preview: true });
  },

  handleTextChange: function(event) {
    var text = this.refs.input.getDOMNode().value;
    this.setText(text);
  },

  getText: function() {
    return this.state.currentText;
  },

  setText: function(text) {
    this.setState({ currentText: text });
  },

});
