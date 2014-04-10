/** @jsx React.DOM */

var MarkdownPreview = React.createClass({

  render: function() {
    var converter = new Showdown.converter();
    var html = converter.makeHtml(this.props.text);

    return (
      <div className="gts-markdown-preview" dangerouslySetInnerHTML={{__html: html}} />
    )
  },

});
