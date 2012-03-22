$(window).load(function() {
  Key = {
    key_a: 65,
    key_b: 66,
    key_c: 67,
    key_d: 68,
    key_e: 69,
    key_f: 70,
    key_g: 71,
    key_h: 72,
    key_i: 73,
    key_j: 74,
    key_k: 75,
    key_l: 76,
    key_m: 77,
    key_n: 78,
    key_o: 79,
    key_p: 80,
    key_q: 81,
    key_r: 82,
    key_s: 83,
    key_t: 84,
    key_u: 85,
    key_v: 86,
    key_w: 87,
    key_x: 88,
    key_y: 89,
    key_z: 90,
    key_up: 38,
    key_down: 40,
    key_left: 37,
    key_right: 39,
    key_fslash: 191,
    key_enter: 13
  }

  function gotoURL(link) {
    window.location = link;
  }

  function min(x, y) {
    return x > y ? y : x;
  }

  function max(x, y) {
    return x > y ? x : y;
  }

  function isMoveKey(e) {
    if (e.keyCode == Key.key_a ||
        e.keyCode == Key.key_s ||
        e.keyCode == Key.key_d ||
        e.keyCode == Key.key_w ||
        e.keyCode == Key.key_up ||
        e.keyCode == Key.key_down ||
        e.keyCode == Key.key_left ||
        e.keyCode == Key.key_right) {
      return true;
    } else {
      return false;
    }
  }

  // fix sub nav on scroll
  var $win = $(window)
    , $nav = $('.subnav')
    , navTop = $('.subnav').length && $('.subnav').offset().top - 40
    , isFixed = 0

  function processScroll() {
    var i, scrollTop = $win.scrollTop()
    if (scrollTop >= navTop && !isFixed) {
      isFixed = 1
      $nav.addClass('subnav-fixed')
    } else if (scrollTop <= navTop && isFixed) {
      isFixed = 0
      $nav.removeClass('subnav-fixed')
    }
  }

  processScroll();
  $win.on('scroll', processScroll);

  // function for gallery 
  var mode = 0; // naviagation mode
  var row = 0;
  var col = 0;

  function handleNavigationMode(e) {
    if(e.keyCode == Key.key_left || e.keyCode == Key.key_a) { // left
      var page = <%= @page.to_i %>;
      if (page > 1)
        gotoURL('<%= "/gallery/#{@sex}/#{@page - 1}" %>');
    }
    else if(e.keyCode == Key.key_right || e.keyCode == Key.key_d) { // right
      gotoURL('<%= "/gallery/#{@sex}/#{@page + 1}" %>');
    }
  }

  function getSelectedItem() {
    return $("#item" + (row * 10 + col));
  }

  function handleMoveMode(e) {
    var isMove = isMoveKey(e);
    
    // remove old selected item
    if (isMove) 
      getSelectedItem().removeClass("selected").addClass("item");

    // handle move
    if (e.keyCode == Key.key_a || e.keyCode == Key.key_left) {  // a
      col = max(col - 1, 0);
    } else if (e.keyCode == Key.key_s || e.keyCode == Key.key_down) { // s
      row = min(row + 1, 9);
    } else if (e.keyCode == Key.key_w || e.keyCode == Key.key_up) { // w
      row = max(row - 1, 0);
    } else if (e.keyCode == Key.key_d || e.keyCode == Key.key_right) { // d
      col = min(col + 1, 9);
    } else if (e.keyCode == Key.key_enter) { // enter
      gotoURL('/vote/<%= @sex %>/' + getSelectedItem().attr('userid'));
    }
    
    // show new selected item 
    if (isMove) {
      getSelectedItem().removeClass("item").addClass("selected");
    }
  }

  $("body").keydown(function(e) {
    if (mode == 0)
      handleNavigationMode(e);
    else if (mode == 1)
      handleMoveMode(e);

    if (e.keyCode == Key.key_fslash) {// '/' to change mode
      mode = 1 - mode;
      if (mode == 1) {
        getSelectedItem().removeClass("item").addClass("selected");
      } else {
        getSelectedItem().removeClass("selected").addClass("item");
      }
    } 
  });

  // function for vote
});
