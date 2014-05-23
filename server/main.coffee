###
Meteor.publish "depsChannel" , ->
	share.Departments.find()
###

share.adminLoggedIn = true

share.consolelog = (collection , obj)->
	#console.log "object now is ", collection.findOne( indx: obj.indx ) 

removeFrom = (collection, id)->
	if share.adminLoggedIn
		collection.remove _id: id

upsertTo = (collection, obj)-> 
	# each obj should have an indx; return Mongodb object _id
	if share.adminLoggedIn
		obj.createdOn = new Date
		collection.update indx: obj.indx ,
			obj, 
			upsert: true

upsertWithId = (collection, obj)-> 
	if share.adminLoggedIn
		obj.createdOn = new Date
		collection.update _id: obj._id ,
			obj, 
			upsert: true

upsertToId = (collection, id, obj)-> 
	if share.adminLoggedIn
		obj.createdOn = new Date
		collection.update _id:id ,
			obj, 
			upsert: true

insertInto = (collection, obj)->
		if share.adminLoggedIn
			obj.createdOn = new Date
			collection.insert obj

	

		
#可改进为保存Organization,其中有Departments或Teams:
Meteor.startup -> 
	unless share.Settings.findOne()? # to initialize only once
		class Settings 
		 	constructor: (@indx)-> 
		 	baodibiLi: 0.5 
		 	FENPeibiLi: 0.3 
		 	pown: 1

		insertInto share.Settings, new Settings 1 

		
	unless share.Departments.findOne()? # to initialize only once
		class Department 
			constructor: (@deptname) ->
			GuDingZIchan: 100000
			ZaigangrENShu: 10
			HuanSuanrENShu: 10
			jixiaoFenshu: 99
			CHAYiXiShu: 1
			jIEyU: 50000
			# object methods could not be stored into mongodb so the following doesn't work
			YunXiaohANbaodi: (baodiYunXiao) =>
				YX = @jIEyU / @GuDingZIchan
				bao = Math.max 0, 0.5 * (YX + baodiYunXiao) 
				Math.max YX, bao
		
	 	for deptname in [1..5]
		 	insertInto share.Departments, new Department deptname 
	
	#console.log share.Departments.find().fetch()
	#console.log share.Settings.findOne()
	recalculate()

 
dept = (obj)->
	upsertWithId share.Departments, obj

sett = (obj)->
	upsertWithId share.Settings, obj


recalculate = -> if share.adminLoggedIn
	getDepts = ->
		share.Departments.find().fetch() 
	
	settings = share.Settings.findOne()
	baodibiLi = settings.baodibiLi 
	FENPeibiLi = settings.FENPeibiLi
	pown = settings.pown

	#re-initializing
	settings.ZONGhEFENzhI = 0
	settings.KEShiFENPeibiLi = 0
	settings.KEShijiangJIN = 0
	settings.rENJUNjiangJIN = 0
	
	jy = 0
	zc = 0
	ZaigangrENShu = 0
	for KEShi in getDepts()
		jy += KEShi.jIEyU
		zc += KEShi.GuDingZIchan
		ZaigangrENShu += KEShi.ZaigangrENShu
	
	zongGudingZIchan = Math.max 0, zc
	zongjIEyU = Math.max 0, jy
	zongJiXiaoGONGZIchI = zongjIEyU
	rENJUNjiangJIN = zongJiXiaoGONGZIchI / ZaigangrENShu
	
	# 保底運營效率 保底比例 * 總的資產運營效率
	baodiYunXiao = baodibiLi * zongjIEyU / zongGudingZIchan 
	# 计算科室计奖分值

	for KEShi in getDepts()
    YX = KEShi.jIEyU / KEShi.GuDingZIchan
    bao = Math.max 0, 0.5 * (YX + baodiYunXiao) 
    KEShi.YunXiaohANbaodi =  Math.max YX, bao
    #if KEShi.LishiXiShu? then KEShi.CHAYiXiShu = KEShi.LishiXiShu
    KEShi.ZONGhEFENzhI = KEShi.jixiaoFenshu * KEShi.HuanSuanrENShu * (Math.pow KEShi.YunXiaohANbaodi, 1/pown) * KEShi.CHAYiXiShu
		dept KEShi
		settings.ZONGhEFENzhI += KEShi.ZONGhEFENzhI
	
	
	#i 计算科室计奖分值小计
		
	#j 计算科室领奖比例, 用科室计奖分值/科室计奖分值小计
	
	#k 计算科室绩效分配, 用 科室领奖比例*总绩效分配池
	for KEShi in getDepts()
    KEShi.KEShiFENPeibiLi = KEShi.ZONGhEFENzhI / settings.ZONGhEFENzhI
    KEShi.KEShijiangJIN = KEShi.KEShiFENPeibiLi * zongJiXiaoGONGZIchI * FENPeibiLi
    KEShi.rENJUNjiangJIN = KEShi.KEShijiangJIN / KEShi.ZaigangrENShu
    dept KEShi
    
    ###
    KEShi.LishiFENPeibiLi = KEShi.LishijiangJIN / (zongJiXiaoGONGZIchI * FENPeibiLi)
    KEShi.LishiXiShu = KEShi.CHAYiXiShu * KEShi.LishiFENPeibiLi / KEShi.KEShiFENPeibiLi
    KEShi.CHAYiXiShu = KEShi.LishiXiShu
    dept KEShi
    ###

		settings.KEShiFENPeibiLi += KEShi.KEShiFENPeibiLi
		settings.KEShijiangJIN += KEShi.KEShijiangJIN
		
	settings.rENJUNjiangJIN = settings.KEShijiangJIN / ZaigangrENShu
	sett settings

Meteor.methods
	sett: sett
	dept: dept
	#depId: (id, obj)-> upsertToId share.Departments, id, obj
	recalculate: recalculate
