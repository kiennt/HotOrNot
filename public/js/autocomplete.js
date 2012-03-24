// encode: UTF-8 
String.prototype.convert_vi2en = function() {
  if (this.vidict == null) {
    this.vidict = {
      'á' : 'a', 'à' : 'a', 'ả' : 'a', 'ã' : 'a', 'ạ' : 'a',
      'â' : 'a', 'ấ' : 'a', 'ầ' : 'a', 'ẩ' : 'a', 'ẫ' : 'a', 'ậ' : 'a',
      'ă' : 'a', 'ắ' : 'a', 'ằ' : 'a', 'ẳ' : 'a', 'ẵ' : 'a', 'ặ' : 'a',
      'é' : 'e', 'è' : 'e', 'ẻ' : 'e', 'ẽ' : 'e', 'ẹ' : 'e',
      'ê' : 'e', 'ế' : 'e', 'ề' : 'e', 'ể' : 'e', 'ễ' : 'e', 'ệ' : 'e',
      'í' : 'i', 'ì' : 'i', 'ỉ' : 'i', 'ĩ' : 'i', 'ị' : 'i',
      'ó' : 'o', 'ò' : 'o', 'ỏ' : 'o', 'õ' : 'o', 'ọ' : 'o', 
      'ô' : 'o', 'ồ' : 'o', 'ố' : 'o', 'ổ' : 'o', 'ỗ' : 'o', 'ộ' : 'o',
      'ơ' : 'o', 'ờ' : 'o', 'ớ' : 'o', 'ở' : 'o', 'ỡ' : 'o', 'ợ' : 'o',
      'ú' : 'u', 'ù' : 'u', 'ủ' : 'u', 'ũ' : 'u', 'ụ' : 'u',
      'ư' : 'u', 'ừ' : 'u', 'ứ' : 'u', 'ử' : 'u', 'ữ' : 'u', 'ự' : 'u',
      'ý' : 'y', 'ỳ' : 'y', 'ỷ' : 'y', 'ỹ' : 'y', 'ỵ' : 'y', 'đ' : 'd'
    }
    
    this.viregex= /[áàảãạâấầẩẫậăắằẳẵặéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ]/g
  }
  that = this;
  return this.toLowerCase().replace(that.viregex, function(key) {
    return that.vidict[key]
  })
}


!function( $ ){

  "use strict"

  var Typeahead = function ( element, options ) {
    this.$element = $(element)
    this.options = $.extend({}, $.fn.typeahead.defaults, options)
    this.matcher = this.options.matcher || this.matcher
    this.sorter = this.options.sorter || this.sorter
    this.highlighter = this.options.highlighter || this.highlighter
    this.$menu = $(this.options.menu).appendTo('body')
    this.source = this.options.source
    this.shown = false
    this.listen()
  }

  Typeahead.prototype = {

    constructor: Typeahead

  , select: function () {
      var link = this.$menu.find('.active').find('a').attr('href')
      window.location = link
    }

  , show: function () {
      var pos = $.extend({}, this.$element.offset(), {
        height: this.$element[0].offsetHeight
      })

      this.$menu.css({
        top: pos.top + pos.height
      , left: pos.left
      })

      this.$menu.show()
      this.shown = true
      return this
    }

  , hide: function () {
      this.$menu.hide()
      this.shown = false
      return this
    }

  , lookup: function(event) {
      var that = this
        , items
      
      var tokens = this.$element.val().convert_vi2en().trim().split(' ')
      var i = 0;
      while (i < tokens.length) {
        if (tokens[i].length == 0) {
          tokens.splice(i, 1);
        } else {
          i++;
        }
      } 
      this.query = tokens.join('&')
      if (!this.query || this.query.length < 2) {
        return this.shown ? this.hide() : this
      }
       
      var link = "/search/1/" + this.query
      that = this
      $.getJSON(link, function(data) {
        items = data.users
        if (!items.length) {
          return that.shown ? that.hide() : that
        }
        return that.render(items).show()
      })

    }

  , highlighter: function (item) {
      // get all index matches
      var itemEN = item.convert_vi2en()
      var matches = {}
      var reQuery = this.query.replace(/&/g, function(key) { return '|' })
      itemEN.replace(new RegExp('(' + reQuery + ')', 'ig'), function (key1, key2, index) {
        matches[index] = key1
      })

      // create hightlight item
      var highlightItem = ''
      var currentPos = 0
      for (var i in matches) {
        var index = parseInt(i)
        if (index < currentPos) continue;
        highlightItem += item.substring(currentPos, index)  + '<strong>' + item.substr(index, matches[index].length) + '</strong>'
        currentPos = index + matches[index].length
      }
      highlightItem += item.substr(currentPos)
      return highlightItem
    }

  , render: function (items) {
      var that = this

      items = $(items).map(function (index, item) {
        var i = $(that.options.item).attr('data-value', item.name)
        i.find('a').html(that.highlighter(item.name)).attr('href', '/vote/girls/' + item.id)
        /*i.find('img').attr('src', item.pic).attr('width', 50).attr('heigh', 50)*/
        /*i.find('img').attr('src', '/img/test_image.png').attr('width', 50).attr('heigh', 50)*/
        return i[0]
      })

      items.first().addClass('active')
      this.$menu.html(items)
      return this
    }

  , next: function (event) {
      var active = this.$menu.find('.active').removeClass('active')
        , next = active.next()

      if (!next.length) {
        next = $(this.$menu.find('li')[0])
      }

      next.addClass('active')
    }

  , prev: function (event) {
      var active = this.$menu.find('.active').removeClass('active')
        , prev = active.prev()

      if (!prev.length) {
        prev = this.$menu.find('li').last()
      }

      prev.addClass('active')
    }

  , listen: function () {
      this.$element
        .on('blur',     $.proxy(this.blur, this))
        .on('keypress', $.proxy(this.keypress, this))
        .on('keyup',    $.proxy(this.keyup, this))

      if ($.browser.webkit || $.browser.msie) {
        this.$element.on('keydown', $.proxy(this.keypress, this))
      }

      this.$menu
        .on('click', $.proxy(this.click, this))
        .on('mouseenter', 'li', $.proxy(this.mouseenter, this))
    }

  , keyup: function (e) {
      e.stopPropagation()
      e.preventDefault()

      switch(e.keyCode) {
        case 40: // down arrow
        case 38: // up arrow
          break

        case 9: // tab
        case 13: // enter
          if (!this.shown) return
          this.select()
          break

        case 27: // escape
          this.hide()
          break

        default:
          this.lookup()
      }

  }

  , keypress: function (e) {
      e.stopPropagation()
      if (!this.shown) return

      switch(e.keyCode) {
        case 9: // tab
        case 13: // enter
        case 27: // escape
          e.preventDefault()
          break

        case 38: // up arrow
          e.preventDefault()
          this.prev()
          break

        case 40: // down arrow
          e.preventDefault()
          this.next()
          break
      }
    }

  , blur: function (e) {
      var that = this
      e.stopPropagation()
      e.preventDefault()
      setTimeout(function () { that.hide() }, 150)
    }

  , click: function (e) {
      e.stopPropagation()
      e.preventDefault()
      this.select()
    }

  , mouseenter: function (e) {
      this.$menu.find('.active').removeClass('active')
      $(e.currentTarget).addClass('active')
    }

  }


  /* TYPEAHEAD PLUGIN DEFINITION
   * =========================== */

  $.fn.typeahead = function ( option ) {
    return this.each(function () {
      var $this = $(this)
        , data = $this.data('typeahead')
        , options = typeof option == 'object' && option
      if (!data) $this.data('typeahead', (data = new Typeahead(this, options)))
      if (typeof option == 'string') data[option]()
    })
  }

  $.fn.typeahead.defaults = {
    source: []
  , items: 15
  , menu: '<ul class="typeahead dropdown-menu"></ul>'
  , item: '<li><a href="#"></a></li>'
  }

  $.fn.typeahead.Constructor = Typeahead


 /* TYPEAHEAD DATA-API
  * ================== */

  $(function () {
    $('body').on('focus.typeahead.data-api', '[data-provide="autocomplete"]', function (e) {
      var $this = $(this)
      if ($this.data('autocomplete')) return
      e.preventDefault()
      $this.typeahead($this.data())
    })
  })

}( window.jQuery )
