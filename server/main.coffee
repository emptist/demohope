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
		share.consolelog collection, obj

upsertWithId = (collection, obj)-> 
	# each obj should have an indx; return Mongodb object _id
	if share.adminLoggedIn
		obj.createdOn = new Date
		collection.update _id: obj._id ,
			obj, 
			upsert: true
		share.consolelog collection, obj

upsertToId = (collection, id, obj)-> 
	# each obj should have an indx; return Mongodb object _id
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
#Departments可先制作Objects	
Meteor.startup ->
	upsertTo share.Settings, {indx:1, vari:"renjunBaoDiJieyu", val: 0.5, ratio: 0.3, ZIchanfa: true}
	for dep in [
			{indx:1, deptname: 'A', GuDingZIchan: 100000, ZaigangrENShu: 10, HuanSuanrENShu: 10, jIEyU: 50000, chayiXishu: 1.0, jixiaoFenshu: 99}, 
			{indx:2, deptname: 'B', GuDingZIchan: 100000, ZaigangrENShu: 10, HuanSuanrENShu: 10, jIEyU: 50000, chayiXishu: 1.0, jixiaoFenshu: 99},
			{indx:3, deptname: 'C', GuDingZIchan: 100000, ZaigangrENShu: 10, HuanSuanrENShu: 10, jIEyU: 50000, chayiXishu: 1.0, jixiaoFenshu: 99},
			{indx:4, deptname: 'D', GuDingZIchan: 100000, ZaigangrENShu: 10, HuanSuanrENShu: 10, jIEyU: 50000, chayiXishu: 1.0, jixiaoFenshu: 99}
		]
	 
		Meteor.call "dep", dep
	recalculate()

 


#以下算法純為演示步驟.若欲實用,可以改进为 OOP 将部分functions放到部门Object内,可能更清晰
recalculate = -> if share.adminLoggedIn
	settings = share.Settings.findOne()
	#保底绩效分配比例之上限,为1时约为人均绩效分配数额.已经在client/main.coffee中设置不得大于0.8.否则保底会高于正常绩效分配
	baodibiLi = settings.val 
	#从单位结余中提取多少比例发放绩效分配
	FENPeibiLi = settings.ratio
	#採用資產法 此checkbox似乎没有正常工作原因不知
	#ZIchanfa = true #settings.ZIchanfa

	getDepartments = ->
		share.Departments.find().fetch() 
		#share.Departments.find() <-- it took a lot of time to find this bug: missing fetch()  

	dep = (obj)->
		upsertWithId share.Departments, obj

	gz = 0
	zc = 0
	for KEShi in getDepartments()
		gz += KEShi.jIEyU
		zc += KEShi.GuDingZIchan
	zongJiXiaoGONGZIchI = Math.max 0, gz
	zongGudingZIchan = Math.max 0, zc
	# 保底運營效率 保底比例 * 總的資產運營效率
	baodiYUNXiao = baodibiLi * zongJiXiaoGONGZIchI / zongGudingZIchan 
	for KEShi in getDepartments()
		KEShi.YunXiaoJIAbaodi = Math.max KEShi.jIEyU / KEShi.GuDingZIchan, baodiYunXiao 
		dep KEShi
		
	# 计算科室计奖分值
	for KEShi in getDepartments()
		KEShi.KEShiJijiangFENzhI = KEShi.chayiXishu * KEShi.jixiaoFenshu * 
			KEShi.HuanSuanrENShu * KEShi.YunXiaoJIAbaodi
		dep KEShi

	#i 计算科室计奖分值小计
	keshiJijiangFenzhiXiaoji = ->
		xj = 0
		for KEShi in getDepartments()
			xj += KEShi.KEShiJijiangFENzhI
		xj


	#j 计算科室领奖比例, 用科室计奖分值/科室计奖分值小计
	#k 计算科室绩效分配, 用 科室领奖比例*总绩效分配池
	do ->
		keshiLingjiangBili = (KEShi) ->
			KEShi.keshiLingjiangBili = KEShi.KEShiJijiangFENzhI / keshiJijiangFenzhiXiaoji()
			KEShi.keshiJiangjin = KEShi.keshiLingjiangBili * zongJiXiaoGONGZIchI * FENPeibiLi
			KEShi.renjunJiangjin = KEShi.keshiJiangjin / KEShi.ZaigangrENShu
			dep KEShi

		for KEShi in getDepartments()
			keshiLingjiangBili KEShi

	

Meteor.methods
	baodi: (obj)-> upsertWithId share.Settings, obj
	dep: (obj)-> upsertTo share.Departments, obj
	#depId: (id, obj)-> upsertToId share.Departments, id, obj
	recalculate: recalculate
