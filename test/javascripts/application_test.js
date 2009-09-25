ArrayTest = TestCase("ArrayTest");

ArrayTest.prototype.testMap = function() {
  var arr = ["foo","bar"];
  assertEquals("foos", arr.map(function(e){return e + "s"})[0]);
};

BookmarkableMergeRequestTest = TestCase("Bookmark merge requests",  {
  testShasOnly: function() {
    var shaSpec = Gitorious.ShaSpec.parseLocationHash("aab00199..bba00199");
    assertEquals("aab00199", shaSpec.firstSha().sha());
    assertEquals("bba00199", shaSpec.lastSha().sha());
    assertFalse(shaSpec.hasVersion());
  },
  
  testShasAndVersion: function() {
    var shaSpec = Gitorious.ShaSpec.parseLocationHash("aab00199..bba00199@2");
    assertTrue(shaSpec.hasVersion());
    assertEquals("2", shaSpec.getVersion());
  },

  testWithLeadingHash: function() {
    var shaSpec = Gitorious.ShaSpec.parseLocationHash("#aab00199..bba00199@2");
    assertEquals("aab00199", shaSpec.firstSha().sha());
  },
  
  testWithEmptyHash: function() {
    var shaSpec = Gitorious.ShaSpec.parseLocationHash("");
    assertNull(shaSpec);
  }

  /*
    TODO: 
    - query the current version from the location hash on load
    - set the current version on selection
    - extract the functionality for selecting commits, versions etc to a single, testable place
   */
})

