#Meteor.subscribe "depsChannel"


departments = -> 
	share.Departments.find({}, {sort: {indx: 1}})

settings = -> 
	share.Settings.findOne()

recalculate = share.recalculate


Template.basicSettings.val = ->
	settings()?.val
Template.basicSettings.ratio = ->
	settings()?.ratio
Template.basicSettings.pown = ->
	settings()?.pown
#Template.basicSettings.ZIchanfa = ->
#	settings()?.ZIchanfa


recalc = (e,t) ->
	obj = settings()
	obj.val = Math.max 0.01, (Math.min 0.8,  1 * t.find('#renjunBaodiJieyu').value.trim())
	obj.ratio = Math.max 0.01, (Math.min 1, 1 * t.find('#jiangjinBili').value.trim())
	obj.pown = Math.max 0.01, (Math.min 1, 1 * t.find('#zhiShu').value.trim())
	#obj.ZIchanfa = t.find('#ZIchanfa').value
	Meteor.call "baodi", obj
	Meteor.call "recalculate"
Template.basicSettings.events
	'keyup input': (e,t) ->
		console.log this, "lost focus"
		recalc e,t
###
	'keydown input': (e,t) ->
		if e.keyCode in [9, 13]
			recalc e, t
###
		
Template.basicTable.departments = ->
	departments()	

		
# !! NOTE: NEVER try again to refactor the following work since the magic @ and this !!
Template.department.events 
	'keyup input': (e,t) ->
	#'keydown input': (e,t) ->
		if true #e.keyCode in [9, 13] #is 13
			@ZaigangrENShu = 1 * t.find('#ZaigangrENShu').value.trim() 
			@HuanSuanrENShu = 1 * t.find('#HuanSuanrENShu').value.trim()
			@jixiaoFenshu = Math.max 0, 1 * t.find('#jixiaoFenshu').value.trim() #could be 0
			@jIEyU = 1 * t.find('#jIEyU').value.trim()
			@GuDingZIchan = 1 * t.find('#GuDingZIchan').value.trim()
			@chayiXishu = Math.max 0.01, 1 * t.find('#chayiXishu').value.trim()
			Meteor.call "dept", this
			Meteor.call "recalculate"
###
	"click #save": (e,t) ->
###			
		
Template.tableView.departments = ->
	departments()


