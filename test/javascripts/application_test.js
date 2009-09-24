ArrayTest = TestCase("ArrayTest");

ArrayTest.prototype.testMap = function() {
  var arr = ["foo","bar"];
  assertEquals("foos", arr.map(function(e){return e + "s"})[0]);
};

BookmarkableMergeRequestTest = TestCase("Bookmark merge requests");

BookmarkableMergeRequestTest.prototype.testMap = function() {
  var shaSpec = Gitorious.ShaSpec.parseLocationHash("aab00199..bba00199");
  assertEquals("aab00199", shaSpec.firstSha().sha());
  assertEquals("bba00199", shaSpec.lastSha().sha());
}

