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

dept = (obj)->
	upsertWithId share.Departments, obj

sett = (obj)->
	upsertWithId share.Settings, obj
	

#可改进为保存Organization,其中有Departments或Teams:
#Departments可先制作Objects

Meteor.startup -> unless share.Settings.findOne()?.pown? # to initialize only once
	upsertTo share.Settings, {indx:1, val: 0.5, ratio: 0.3, pown:1, ZIchanfa: true}
	for dept in [
			{indx:1, deptname: 'A', GuDingZIchan: 100000, ZaigangrENShu: 10, HuanSuanrENShu: 10, jIEyU: 50000, chayiXishu: 1.0, jixiaoFenshu: 99}, 
			{indx:2, deptname: 'B', GuDingZIchan: 100000, ZaigangrENShu: 10, HuanSuanrENShu: 10, jIEyU: 50000, chayiXishu: 1.0, jixiaoFenshu: 99},
			{indx:3, deptname: 'C', GuDingZIchan: 100000, ZaigangrENShu: 10, HuanSuanrENShu: 10, jIEyU: 50000, chayiXishu: 1.0, jixiaoFenshu: 99},
			{indx:4, deptname: 'D', GuDingZIchan: 100000, ZaigangrENShu: 10, HuanSuanrENShu: 10, jIEyU: 50000, chayiXishu: 1.0, jixiaoFenshu: 99}
		]
	 
		upsertTo share.Departments, dept
	recalculate()

 


#以下算法純為演示步驟.若欲實用,可以改进为 OOP 将部分functions放到部门Object内,可能更清晰
recalculate = -> if share.adminLoggedIn
	settings = share.Settings.findOne()
	
	#保底绩效分配比例之上限,为1时约为人均绩效分配数额.已经在client/main.coffee中设置不得大于0.8.否则保底会高于正常绩效分配
	baodibiLi = settings.val 
	#从单位结余中提取多少比例发放绩效分配
	FENPeibiLi = settings.ratio
	pown = settings.pown

	getDepts = ->
		share.Departments.find().fetch() 
		#share.Departments.find() <-- it took a lot of time to find this bug: missing fetch()  

	
		
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
		dept KEShi
		KEShi.ZONGhEFENzhI = KEShi.jixiaoFenshu * KEShi.HuanSuanrENShu * (Math.pow KEShi.YunXiaohANbaodi, 1/pown) * KEShi.chayiXishu
		dept KEShi
		
	
	#i 计算科室计奖分值小计
	settings.ZONGhEFENzhI = 0
	for KEShi in getDepts()
		settings.ZONGhEFENzhI += KEShi.ZONGhEFENzhI
	
	
	#j 计算科室领奖比例, 用科室计奖分值/科室计奖分值小计
	settings.KEShiFENPeibiLi = 0
	settings.KEShijiangJIN = 0
	settings.rENJUNjiangJIN = 0
	#k 计算科室绩效分配, 用 科室领奖比例*总绩效分配池
	for KEShi in getDepts()
		KEShi.KEShiFENPeibiLi = KEShi.ZONGhEFENzhI / settings.ZONGhEFENzhI
		dept KEShi
		settings.KEShiFENPeibiLi += KEShi.KEShiFENPeibiLi
		
		KEShi.KEShijiangJIN = KEShi.KEShiFENPeibiLi * zongJiXiaoGONGZIchI * FENPeibiLi
		dept KEShi
		settings.KEShijiangJIN += KEShi.KEShijiangJIN
		
		KEShi.rENJUNjiangJIN = KEShi.KEShijiangJIN / KEShi.ZaigangrENShu
		dept KEShi

	settings.rENJUNjiangJIN = settings.KEShijiangJIN / ZaigangrENShu

	sett settings

Meteor.methods
	sett: sett
	dept: dept
	#depId: (id, obj)-> upsertToId share.Departments, id, obj
	recalculate: recalculate
