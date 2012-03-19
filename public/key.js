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

