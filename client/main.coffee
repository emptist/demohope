#Meteor.subscribe "depsChannel"


departments = -> 
	share.Departments.find({}, {sort: {indx: 1}})

settings = -> 
	share.Settings.find(indx:1)

Template.departments.departments = ->
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

Template.departments.events
	'click #addDept': (e,t) ->
		Meteor.call "newDept"	

Template.department.events 
	'click #removeDept': (e,t) ->
		Meteor.call "removeDept", this._id

	'keyup input': (e,t) ->
		v = 1 * e.target.value.trim() 
		this["#{e.target.id}"] = switch e.target.id
			when "ZaigangrENShu" then v
			when "HuanSuanrENShu" then v
			when "jixiaoFenshu" then Math.max 0, v #could be 0
			when "jIEyU" then v
			when "GuDingZIchan" then Math.max 1, v
			when "CHAYiXiShu" then Math.max 0.01, v
			when "LishiXiShu" then Math.max 0, v
			when "LishijiangJIN" then Math.max 0, v
			else e.target.value.trim() # could be department name now
      
		Meteor.setTimeout ( => # must use => instead of -> here to keep this level this
			Meteor.call "dept", this
			Meteor.call "recalculate"), 1500 # wait until input finished
			
		

