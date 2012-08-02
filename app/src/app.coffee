###

Copyright (c) 2012 Jichao Ouyang http://geogeo.github.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

###

lng = LUNGO
HOST = "http://127.0.0.1:8000"
API = '/api/v1/'
App = null
userinfo =
  username:''
  key:''
  login:false
  id:''
  
ScrollView = Em.View.extend
  didInsertElement:->
    element = this.$().closest('.scrollable').attr('id')
    Em.run.once ->
      console.log element
      LUNGO.View.Scroll.init(element)

eventBinding = ->
  $('#login-form').submit (evt)->
    evt.preventDefault()
    form = $(this)
    $.post HOST+'/getapi/', $(this).serialize(),(data)->
      # console.log data
      if data.login
        lng.Router.back()
        lng.Data.Storage.persistent('userinfo',data)
        lng.Data.Cache.set('userinfo', data)
        Hdd.checkAuth()
      else
        form.find('.error').removeClass 'hide'
  $('#newoffer-btn').click ->
    data = {"category": '', "image": null, "images": [], "like": 0, "offering": "", "state": 1, "tags": "", "user": '/api/v1/user/'+userinfo.id+'/', "want": ""}
    $.each $('#newoffer-form').serializeArray(),(i,v)->
      data[v.name]=v.value
    data['category']='/api/v1/category/'+Hdd.categoriesView.get('selection').id+'/'
    console.log data
    Hdd.newOffer(data)
  $('#newswap-btn').click ->
    data = {}
    data['proposing_offer']='/api/v1/offer/'+Hdd.offerSelectView.get('selection').id+'/'
    data['responding_offer']='/api/v1/offer/'+Hdd.offerController.get('currentItem').id+'/'
    console.log data
    Hdd.newSwap(data)
Hdd = Em.Application.create
  ready:-> 
    @_super()
    @checkAuth()
    @getOffers()
    @getCategories()
    
    App=((lng) ->
      lng.App.init
        name: 'HuanDuoDuo'
        version: '1.0'
      {}
    )(LUNGO)
    Hdd.offerSelectView.appendTo('#swap-select-container')
    eventBinding()
  getOffers:(api)->
    if not api
      api = '/api/v1/offer/?format=json'
    $.getJSON HOST+api+'&username='+userinfo.username+'&api_key='+userinfo.key,(data)->
      if data.objects
        data.objects.forEach (item)->
          item.image = HOST+item.image
          item.images.forEach (i) -> i.image = HOST+i.image
          Hdd.offerDataController.addItem Hdd.Offer.create item
        # Hdd.offerController.set 'next20', data.meta.next
        Hdd.offerController.showDefult() 
        #
  mySwaps:()->
    $.getJSON HOST+'/api/v1/swap/?format=json&username='+userinfo.username+'&api_key='+userinfo.key,(data)->
      if data.objects
        data.objects.forEach (item)->
          Hdd.swapController.addItem Hdd.Swap.create item
        # Hdd.offerController.set 'next20', data.meta.next
        
  checkAuth:->
    if lng.Data.Cache.get('userinfo')
      userinfo= LUNGO.Data.Cache.get('userinfo')
      Hdd.userController.set 'user',Hdd.User.create userinfo
      return userinfo
    if lng.Data.Storage.persistent('userinfo')
      userinfo=lng.Data.Storage.persistent('userinfo')
      Hdd.userController.set 'user',Hdd.User.create userinfo
      return userinfo
    return false

  newOffer:(offer)->
    $.ajax
          url:HOST+'/api/v1/offer/?username='+userinfo.username+'&api_key='+userinfo.key
          type:'POST'
          contentType: 'application/json'
          data:JSON.stringify(offer)
          dataType:'json'
          processData:false
          statusCode:
            401: ->
              console.log 'login first'
              lng.Router.section 'login'
            201: ->
              lng.Router.back()
              Hdd.getOffers()
              # update
  newSwap:(swap)->
    $.ajax
          url:HOST+'/api/v1/swap/?username='+userinfo.username+'&api_key='+userinfo.key
          type:'POST'
          contentType: 'application/json'
          data:JSON.stringify(swap)
          dataType:'json'
          processData:false
          statusCode:
            401: ->
              console.log 'login first'
              lng.Router.section 'login'
            201: ->
              lng.Router.back()
              Hdd.getOffers()
              # update
  getCategories:->
    $.getJSON HOST+'/api/v1/category/', (data)->
      Hdd.categoriesView.set 'content',data.objects
      Hdd.categoriesView.appendTo('#categories')
  
Hdd.categoriesView = Em.Select.create
  content:[]
  # attributeBindings: ['name']
  # name:'categoriy'
  optionLabelPath:'content.name'
  optionValuePath:'content.id'

  
Hdd.User = Em.Object.extend
  username:null
  api:null

Hdd.userController = Em.Object.create
  user:null

Hdd.SideView = ScrollView.extend
  userBinding:'Hdd.userController.user'
  myswap:->
    Hdd.offerController.filterBy 'username',userinfo.username
  
Hdd.Offer = Em.Object.extend
  short_description:null
  state:null
  id:null
  offering:null
  want:null
  category:null
  image:null
  images:null
  like:0
  offerer:null
  offered_time:null
  username:(->
    @get('offerer')?.username
  ).property 'offerer'
  
Hdd.Swap = Em.Object.extend
 
  proposing_offer:null
  responding_offer:null
  state:null
  proposing_offerer:(->
    @get('proposing_offer').offerer.username
  ).property 'proposing_offer'
  responding_offerer:(->
    @get('responding_offer').offerer.username
  ).property 'responding_offer'
  
Hdd.DataController = Em.ArrayController.extend
  content:[]
  addItem:(item) ->
    exists = @filterProperty('id',item.id).length
    if exists is 0
      @pushObject item
      return true
    else
      return false

Hdd.swapDataController = Hdd.DataController.create()

Hdd.offerDataController = Hdd.DataController.create()

Hdd.offerController = Em.ArrayController.create
  content:[]
  next20:null
  currentItem:null
  clearFilter:->
    @set 'content',Hdd.offerDataController.get 'content'
  filterBy: (key,value)->
    @set 'content', Hdd.offerDataController.filterProperty key,value
  itemCount:(->
    @get 'length'
  ).property '@each'

  showDefult:->
    @clearFilter()
    @get('content').sort (item1,item2)->
      console.log item1.offered_time,item2.offered_time
      if item1.offered_time > item2.offered_time
        return 1
      else if item1.offered_time < item2.offered_time
        return -1
      return 0

  showPopular:->
    @get('content').sort (item1,item2) ->
      return item1.like-item2.like

  showMyOffer:->
    @filterBy 'username', userinfo.username


Hdd.swapController = Em.ArrayController.create
  content:[]
  offerBinding:Em.Binding.oneWay('Hdd.offerController.content')
  currentItem:null
  clearFilter:->
    @set 'content', Hdd.swapDataController.get 'content'
  filterBy: (key,value)->
    @set 'content', Hdd.swapDataController.filterProperty key,value
  
  itemCount:(->
    @get 'length'
  ).property '@each'
  
  proposeSwap:->
    @filterBy('proposing_offerer',userinfo.username)

  respondingSwap:->
    @filterBy('proposing_offerer',userinfo.username)

  

Hdd.offerSelectView = Em.Select.create
  contentBinding:'Hdd.offerController.content'
  optionLabelPath:'content.short_description'
  optionValuePath:'content.id'
  
Hdd.OfferView = Em.CollectionView.extend
  contentBinding:'Hdd.offerController.content'
  tagName:'ul'
  itemViewClass:ScrollView.extend
    classNames:['selectable']
    tagName:'li'
    click:->
      Hdd.offerController.set 'currentItem', @get 'content'
      console.log @get 'content'

Hdd.SwapView = Em.CollectionView.extend
  contentBinding: 'Hdd.swapController.content'
  tagName:'ul'
  itemViewClass:ScrollView.extend
    className:['selectable']
    tagName:'li'
    click:->
      Hdd.swapController.set 'currentItem', @get 'content'

Hdd.SwapDetailView = ScrollView.extend
  currentItemBinding:'Hdd.swapController.currentItem' 
  accept:->
    console.log 'accepted'
  decline:->
    console.log 'decline'
Hdd.DetailView = ScrollView.extend
  currentItemBinding: 'Hdd.offerController.currentItem'
  imageScrollWidth:(->
    # 'width:2012px;height:200px;'
    if @get('currentItem') then 'width:'+@get('currentItem').images.length*200+'px;' else 'width:0px;'
  ).property 'currentItem'

  onChangeItem:(->
    
    element = this.$().closest('.scrollable').attr('id')
    imagescroll = this.$().find('scroll').attr('id')
    # console.log this.$().find('img')
    if element
      Em.run.next ->
        # console.log element,imagescroll
        LUNGO.View.Scroll.init(element)
    if imagescroll
      Em.run.next ->
        LUNGO.View.Scroll.init(imagescroll)
  ).observes 'currentItem'
