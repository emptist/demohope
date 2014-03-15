#Meteor.subscribe "depsChannel"


departments = -> 
	share.Departments.find({}, {sort: {indx: 1}})

settings = -> 
	share.Settings.findOne()

recalculate = share.recalculate


Template.setRenjunBaodiJieyu.val = ->
	settings()?.val
Template.setRenjunBaodiJieyu.ratio = ->
	settings()?.ratio

recalc = (e,t) ->
	obj = settings()
	obj.val = Math.max 0.01, (Math.min 0.8,  1 * t.find('#renjunBaodiJieyu').value.trim())
	obj.ratio = Math.max 0.01, (Math.min 1, 1 * t.find('#jiangjinBili').value.trim())
	Meteor.call "baodi", obj
	Meteor.call "recalculate"
Template.setRenjunBaodiJieyu.events
	'keydown input': (e,t) ->
		if e.keyCode in [9, 13]
			recalc e, t
	'click #save': (e,t) ->
		recalc e,t

		
Template.basicTable.departments = ->
	departments()	

		
# !! NOTE: NEVER try again to refactor the following work since the magic @ and this !!
Template.department.events 

	'keydown input': (e,t) ->
		if e.keyCode in [9, 13] #is 13
			@shangbanRenshu = 1 * t.find('#shangbanRenshu').value.trim() 
			@huansuanRenshu = 1 * t.find('#huansuanRenshu').value.trim()
			@jixiaoFenshu = Math.max 0, 1 * t.find('#jixiaoFenshu').value.trim() #could be 0
			@jieyu = 1 * t.find('#jieyu').value.trim()
			@chayiXishu = Math.max 0.01, 1 * t.find('#chayiXishu').value.trim()
			Meteor.call "dep", this
			Meteor.call "recalculate"
###
	"click #save": (e,t) ->
###			
		
Template.tableView.departments = ->
	departments()


