###
getDeps = ->
	Session.get "deps" 

getDepartments = ->
	getDeps().departments
###

#Meteor.subscribe "depsChannel"


departments = -> 
	share.Departments.find() 

setDeps = (deps)->
	Session.set "deps", deps 

recalculate = share.recalculate


Template.setRenjunBaodiJieyu.events
	'click #save': (e,t)->
		Session.set "renjunBaodiJieyu", t.find('#renjunBaodiJieyu').value.trim()
		console.log Session.get "renjunBaodiJieyu"

Template.basicTable.departments = ->
	departments()	

Template.basicTable.events 
	'click #recalc': (e, t) ->
		recalculate()

Template.department.shangbanRenshu = -> 
	@shangbanRenshu
#getValue = (id) -> t.find(id).value.trim()
Template.department.events 
	"click #save": (e,t) ->
		@shangbanRenshu = t.find('#shangbanRenshu').value.trim()
		@huansuanRenshu = t.find('#huansuanRenshu').value.trim()
		@jixiaoFenshu = t.find('#jixiaoFenshu').value.trim()
		@jieyu = t.find('#jieyu').value.trim()
		@diff = t.find('#diff').value.trim()
		Meteor.call "dep", this
		Meteor.call "recalculate"
		#console.log @, departments().fetch() 

Template.tableView.departments = ->
	departments()


