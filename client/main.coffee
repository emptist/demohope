###
getDeps = ->
	Session.get "deps" 

getDepartments = ->
	getDeps().departments
###

#Meteor.subscribe "depsChannel"


departments = -> 
	share.Departments.find({}, {sort: {indx: 1}})

settings = -> 
	share.Settings.findOne()

setDeps = (deps)->
	Session.set "deps", deps 

recalculate = share.recalculate


Template.setRenjunBaodiJieyu.val = ->
	settings()?.val
Template.setRenjunBaodiJieyu.ratio = ->
	settings()?.ratio

recalc = (e,t) ->
	obj = settings()
	obj.val = 1 * t.find('#renjunBaodiJieyu').value.trim()
	obj.ratio = 1 * t.find('#jiangjinBili').value.trim()
	Meteor.call "baodi", obj
	Meteor.call "recalculate"

Template.setRenjunBaodiJieyu.events
	'keypress input': (e,t) ->
		if e.keyCode is 13
			recalc e, t
	'click #save': (e,t) ->
		recalc e,t

		
Template.basicTable.departments = ->
	departments()	

Template.basicTable.events 
	'click #recalc': (e, t) ->
		recalculate()

Template.department.shangbanRenshu = -> 
	@shangbanRenshu

		
	
Template.department.events 
	"click #save": (e,t) ->
		@shangbanRenshu = 1 * t.find('#shangbanRenshu').value.trim() 
		@huansuanRenshu = 1 * t.find('#huansuanRenshu').value.trim()
		@jixiaoFenshu = 1 * t.find('#jixiaoFenshu').value.trim()
		@jieyu = 1 * t.find('#jieyu').value.trim()
		@chayiXishu = 1 * t.find('#chayiXishu').value.trim()
		Meteor.call "dep", this
		Meteor.call "recalculate"

	'keypress input': (e,t)->
		if e.keyCode is 13
			@shangbanRenshu = 1 * t.find('#shangbanRenshu').value.trim() 
			@huansuanRenshu = 1 * t.find('#huansuanRenshu').value.trim()
			@jixiaoFenshu = 1 * t.find('#jixiaoFenshu').value.trim()
			@jieyu = 1 * t.find('#jieyu').value.trim()
			@chayiXishu = 1 * t.find('#chayiXishu').value.trim()
			Meteor.call "dep", this
			Meteor.call "recalculate"
		
Template.tableView.departments = ->
	departments()


