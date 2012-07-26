// Generated by CoffeeScript 1.3.3
/*

Copyright (c) 2012 Jichao Ouyang http://geogeo.github.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

var API, App, HOST, Hdd, ScrollView, eventBinding, lng, userinfo;

lng = LUNGO;

HOST = "http://127.0.0.1:8000";

API = '/api/v1/';

App = null;

userinfo = {
  username: '',
  key: '',
  login: false,
  id: ''
};

ScrollView = Em.View.extend({
  didInsertElement: function() {
    var element;
    element = this.$().closest('.scrollable').attr('id');
    return Em.run.once(function() {
      console.log(element);
      return LUNGO.View.Scroll.init(element);
    });
  }
});

eventBinding = function() {
  $('#login-form').submit(function(evt) {
    var form;
    evt.preventDefault();
    form = $(this);
    return $.post(HOST + '/getapi/', $(this).serialize(), function(data) {
      if (data.login) {
        lng.Router.back();
        lng.Data.Storage.persistent('userinfo', data);
        lng.Data.Cache.set('userinfo', data);
        return Hdd.checkAuth();
      } else {
        return form.find('.error').removeClass('hide');
      }
    });
  });
  $('#newoffer-btn').click(function() {
    var data;
    data = {
      "category": '',
      "image": null,
      "images": [],
      "like": 0,
      "offering": "",
      "state": 1,
      "tags": "",
      "user": '/api/v1/user/' + userinfo.id + '/',
      "want": ""
    };
    $.each($('#newoffer-form').serializeArray(), function(i, v) {
      return data[v.name] = v.value;
    });
    data['category'] = '/api/v1/category/' + Hdd.categoriesView.get('selection').id + '/';
    console.log(data);
    return Hdd.newOffer(data);
  });
  return $('#newswap-btn').click(function() {
    var data;
    data = {};
    data['proposing_offer'] = '/api/v1/offer/' + Hdd.offerSelectView.get('selection').id + '/';
    data['responding_offer'] = '/api/v1/offer/' + Hdd.offerController.get('currentItem').id + '/';
    console.log(data);
    return Hdd.newSwap(data);
  });
};

Hdd = Em.Application.create({
  ready: function() {
    this._super();
    this.checkAuth();
    this.getOffers();
    this.getCategories();
    App = (function(lng) {
      lng.App.init({
        name: 'HuanDuoDuo',
        version: '1.0'
      });
      return {};
    })(LUNGO);
    Hdd.offerSelectView.appendTo('#swap-select-container');
    return eventBinding();
  },
  getOffers: function(api) {
    if (!api) {
      api = '/api/v1/offer/?format=json';
    }
    return $.getJSON(HOST + api + '&username=' + userinfo.username + '&api_key=' + userinfo.key, function(data) {
      if (data.objects) {
        data.objects.forEach(function(item) {
          item.image = HOST + item.image;
          item.images.forEach(function(i) {
            return i.image = HOST + i.image;
          });
          return Hdd.offerController.addItem(Hdd.Offer.create(item));
        });
        return Hdd.offerController.set('next20', data.meta.next);
      }
    });
  },
  mySwaps: function() {
    return $.getJSON(HOST + '/api/v1/swap/?format=json&username=' + userinfo.username + '&api_key=' + userinfo.key, function(data) {
      if (data.objects) {
        data.objects.forEach(function(item) {
          item.image = HOST + item.image;
          item.images.forEach(function(i) {
            return i.image = HOST + i.image;
          });
          return Hdd.offerController.addItem(Hdd.Offer.create(item));
        });
        return Hdd.offerController.set('next20', data.meta.next);
      }
    });
  },
  checkAuth: function() {
    if (lng.Data.Cache.get('userinfo')) {
      userinfo = LUNGO.Data.Cache.get('userinfo');
      Hdd.userController.set('user', Hdd.User.create(userinfo));
      return userinfo;
    }
    if (lng.Data.Storage.persistent('userinfo')) {
      userinfo = lng.Data.Storage.persistent('userinfo');
      Hdd.userController.set('user', Hdd.User.create(userinfo));
      return userinfo;
    }
    return false;
  },
  newOffer: function(offer) {
    return $.ajax({
      url: HOST + '/api/v1/offer/?username=' + userinfo.username + '&api_key=' + userinfo.key,
      type: 'POST',
      contentType: 'application/json',
      data: JSON.stringify(offer),
      dataType: 'json',
      processData: false,
      statusCode: {
        401: function() {
          console.log('login first');
          return lng.Router.section('login');
        },
        201: function() {
          lng.Router.back();
          return Hdd.getOffers();
        }
      }
    });
  },
  newSwap: function(swap) {
    return $.ajax({
      url: HOST + '/api/v1/swap/?username=' + userinfo.username + '&api_key=' + userinfo.key,
      type: 'POST',
      contentType: 'application/json',
      data: JSON.stringify(swap),
      dataType: 'json',
      processData: false,
      statusCode: {
        401: function() {
          console.log('login first');
          return lng.Router.section('login');
        },
        201: function() {
          lng.Router.back();
          return Hdd.getOffers();
        }
      }
    });
  },
  getCategories: function() {
    return $.getJSON(HOST + '/api/v1/category/', function(data) {
      Hdd.categoriesView.set('content', data.objects);
      return Hdd.categoriesView.appendTo('#categories');
    });
  }
});

Hdd.categoriesView = Em.Select.create({
  content: [],
  optionLabelPath: 'content.name',
  optionValuePath: 'content.id'
});

Hdd.User = Em.Object.extend({
  username: null,
  api: null
});

Hdd.userController = Em.Object.create({
  user: null
});

Hdd.SideView = ScrollView.extend({
  userBinding: 'Hdd.userController.user'
});

Hdd.Offer = Em.Object.extend({
  short_description: null,
  state: null,
  id: null,
  offering: null,
  want: null,
  category: null,
  image: null,
  images: null,
  like: 0,
  user: null,
  offered_time: null
});

Hdd.offerController = Em.ArrayController.create({
  content: [],
  next20: null,
  currentItem: null,
  addItem: function(item) {
    var exists;
    exists = this.filterProperty('id', item.id).length;
    if (exists === 0) {
      this.pushObject(item);
      return true;
    } else {
      return false;
    }
  },
  itemCount: (function() {
    return this.get('length');
  }).property('@each'),
  showDefult: function() {
    return this.get('content').sort(function(item1, item2) {
      console.log(item1.offered_time, item2.offered_time);
      if (item1.offered_time > item2.offered_time) {
        return 1;
      } else if (item1.offered_time < item2.offered_time) {
        return -1;
      }
      return 0;
    });
  },
  showPopular: function() {
    return this.get('content').sort(function(item1, item2) {
      return item1.like - item2.like;
    });
  }
});

Hdd.offerSelectView = Em.Select.create({
  contentBinding: 'Hdd.offerController.content',
  optionLabelPath: 'content.short_description',
  optionValuePath: 'content.id'
});

Hdd.OfferView = Em.CollectionView.extend({
  contentBinding: 'Hdd.offerController.content',
  tagName: 'ul',
  itemViewClass: ScrollView.extend({
    classNames: ['selectable'],
    tagName: 'li',
    click: function() {
      Hdd.offerController.set('currentItem', this.get('content'));
      return console.log(this.get('content'));
    }
  })
});

Hdd.DetailView = ScrollView.extend({
  currentItemBinding: 'Hdd.offerController.currentItem',
  imageScrollWidth: (function() {
    if (this.get('currentItem')) {
      return 'width:' + this.get('currentItem').images.length * 200 + 'px;';
    } else {
      return 'width:0px;';
    }
  }).property('currentItem'),
  onChangeItem: (function() {
    var element, imagescroll;
    element = this.$().closest('.scrollable').attr('id');
    imagescroll = this.$().find('scroll').attr('id');
    if (element) {
      Em.run.next(function() {
        return LUNGO.View.Scroll.init(element);
      });
    }
    if (imagescroll) {
      return Em.run.next(function() {
        return LUNGO.View.Scroll.init(imagescroll);
      });
    }
  }).observes('currentItem')
});
