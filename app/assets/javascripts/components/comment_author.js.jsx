/** @jsx React.DOM */

var CommentAuthor = React.createClass({

  render: function() {
    var author = this.props.author;

    return (
      <span>
        <img src={author.avatarUrl} width="24" height="24" className="gts-avatar" />
        <a href={author.profilePath}>{author.name || author.login}</a>
      </span>
    );
  }

});
