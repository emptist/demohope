#Meteor.subscribe "depsChannel"


departments = -> 
	share.Departments.find({}, {sort: {indx: 1}})

settings = -> 
	share.Settings.find(indx:1)

Template.basicTable.departments = ->
	departments()	

Template.tableView.departments = ->
	departments()

Template.tableView.settings = ->
	settings()


Template.tablefootRow.settings = ->
	settings()


Template.basicSettings.settings = ->
	settings()

Template.basicSettings.events
	'keyup input': (e,t) ->
		@baodibiLi = Math.max 0.01, (Math.min 0.8,  1 * t.find('#baodibiLi').value.trim())
		@FENPeibiLi = Math.max 0.01, (Math.min 1, 1 * t.find('#jiangJINbiLi').value.trim())
		@pown = Math.max 1, (Math.min 10, 1 * t.find('#zhiShu').value.trim())
		Meteor.call "sett", this
		Meteor.call "recalculate"
			

		
Template.department.events 
	'keyup input': (e,t) ->
		@ZaigangrENShu = 1 * t.find('#ZaigangrENShu').value.trim() 
		@HuanSuanrENShu = 1 * t.find('#HuanSuanrENShu').value.trim()
		@jixiaoFenshu = Math.max 0, 1 * t.find('#jixiaoFenshu').value.trim() #could be 0
		@jIEyU = 1 * t.find('#jIEyU').value.trim()
		@GuDingZIchan = Math.max 1, 1 * t.find('#GuDingZIchan').value.trim()
		@CHAYiXiShu = Math.max 0.01, 1 * t.find('#CHAYiXiShu').value.trim()
		Meteor.call "dept", this
		Meteor.call "recalculate"
		

