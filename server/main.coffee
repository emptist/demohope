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
			{indx:1, deptname: 'A', gudingzichan: 1, shangbanRenshu: 10, huansuanRenshu: 10, jieyu: 50000, chayiXishu: 1.0, jixiaoFenshu: 99}, 
			{indx:2, deptname: 'B', gudingzichan: 1, shangbanRenshu: 10, huansuanRenshu: 10, jieyu: 50000, chayiXishu: 1.0, jixiaoFenshu: 99},
			{indx:3, deptname: 'C', gudingzichan: 1, shangbanRenshu: 10, huansuanRenshu: 10, jieyu: 50000, chayiXishu: 1.0, jixiaoFenshu: 99},
			{indx:4, deptname: 'D', gudingzichan: 1, shangbanRenshu: 10, huansuanRenshu: 10, jieyu: 50000, chayiXishu: 1.0, jixiaoFenshu: 99}
		]
	 
		Meteor.call "dep", dep
	recalculate()

 


#以下算法可以改进为 OOP 将部分functions放到部门Object内,可能更清晰
recalculate = -> if share.adminLoggedIn
	settings = share.Settings.findOne()
	#保底奖金比例之上限,为1时约为人均奖金数额.已经在client/main.coffee中设置不得大于0.8.否则保底会高于正常奖金
	baodibiLi = settings.val 
	#从单位结余中提取多少比例发放奖金
	FAjiangbiLi = settings.ratio
	#採用資產法 此checkbox似乎没有正常工作原因不知
	ZIchanfa = true #settings.ZIchanfa

	getDepartments = ->
		share.Departments.find().fetch() 
		#share.Departments.find() <-- it took a lot of time to find this bug: missing fetch()  

	dep = (obj)->
		upsertWithId share.Departments, obj

	#a 计算可奖结余即总奖金池, 为各部门可奖结余之和
	#- --> 對於採用資產運營效率算法的則計算科室資產運營效率
	#- --> 無需計算人均資產運營效率,原因是人均收支結餘/人均固定資產,分子分母抵消
	#- --> 但由於要對虧損科室設置保底,故需計算科室資產運營效率加保底
	zongjiangJINchI = ->
		p = 0
		for KEShi in getDepartments()
			KEShi.YunXiao = KEShi.jieyu / KEShi.gudingzichan
			p += KEShi.jieyu
		Math.max 0, p

	
	#b 计算人均结余,
	
	#b1 计算各自人均结余, 用科室可奖结余除以人数,注意 人数
	do ->
		renjunJieyu = (KEShi)-> 
			KEShi.renjunJieyu = KEShi.jieyu / KEShi.shangbanRenshu
			KEShi.renjunGudingzichan = KEShi.gudingzichan / KEShi.shangbanRenshu
			dep KEShi
		
		for KEShi in getDepartments()
			renjunJieyu KEShi
	
		
	#b2 计算人均结余小计, 用总奖金池除以各部门实际人数和,注意是实际人数
	rENJUNjIEyUxiaoJi = do ->
		ShangBANrENShuxiaoJi = (GeKEShi) -> 
			xj = 0
			for KEShi in GeKEShi
				xj += KEShi.shangbanRenshu
			xj
		zongjiangJINchI() / ShangBANrENShuxiaoJi( getDepartments())
			

	#c 计算人均结余加保底
	do ->
		avb = -> baodibiLi * rENJUNjIEyUxiaoJi 
		
		rejust = true #<-- 调整保底金额开关
		if rejust is false
			cnt = 1 # 用于在亏损部门多的情况下,调节保底金额
		else
			cnt = 0.3 # 初始時cnt取0.3 是配合增加一個科室加0.7,亦即之後逐步減少補貼 
			for KEShi in getDepartments() when KEShi.renjunJieyu < avb()
				cnt += 0.7

		renjunJieyuJiaBaodi = (KEShi) ->
			#x = KEShi.huansuanRenjunJieyu
			x = KEShi.renjunJieyu
			
			if x > avb() 
				KEShi.renjunJieyuJiaBaodi =	x
			else 
				KEShi.renjunJieyuJiaBaodi = avb() * cnt
			
			dep KEShi

		for KEShi in getDepartments()
			renjunJieyuJiaBaodi KEShi

	#d 计算结余加保底,即各科室各自  人数*人均结余加保底
	#- --> 對於資產效率指標法,虧損科室設置保底故,須計算科室資產運營效率加保底
	do ->
		jieyuJiaBaodi = (KEShi) ->
			KEShi.jieyuJiaBaodi = KEShi.shangbanRenshu * KEShi.renjunJieyuJiaBaodi
			KEShi.YunXiaoJIAbaodi = KEShi.jieyuJiaBaodi / KEShi.gudingzichan
			dep KEShi
			
		for KEShi in getDepartments()
			jieyuJiaBaodi KEShi

	#e 计算结余加保底和
	jieyuJiaBaodiHe = do ->
		jieyuJiaBaodiXiaoji = (GeKEShi) ->
			xj = 0
			for KEShi in GeKEShi
				xj += KEShi.jieyuJiaBaodi
			xj

		jieyuJiaBaodiXiaoji getDepartments()	
	
	#f 计算人均结余加保底小计, 用 结余加保底和除以换算人数小计
	renjunJieyuJiaBaoDiXiaoji = ->
		huansuanRenshuXiaoji = (GeKEShi) ->
			xj = 0
			for KEShi in GeKEShi 
				xj += KEShi.huansuanRenshu
			xj
			
		jieyuJiaBaodiHe / huansuanRenshuXiaoji(getDepartments())
	
	#g 计算人均结余权重, 用 各科室各自 人均结余加保底除以人均结余加保底小计
	do ->
		renjunJieyuQuanzhong = (KEShi) ->
			KEShi.renjunJieyuQuanzhong = KEShi.renjunJieyuJiaBaodi / renjunJieyuJiaBaoDiXiaoji()

			dep KEShi

		for KEShi in getDepartments()
			renjunJieyuQuanzhong KEShi
	#明天将此改为人均资产运营指数
	
	#h 计算科室计奖分值, 
	#h1 對於採用人均結餘權重者,用科室 绩效分数 * 换算人数 * 人均结余权重 * 科室差异系数
	#h2 對於採用資產運營效率者,用科室 绩效分数 * 换算人数 * 資產效率加保底 * 科室差异系数
	do ->
		keshiJijiangFenzhi = (KEShi) ->
			qUANZhong = if ZIchanfa then KEShi.YunXiaoJIAbaodi else KEShi.renjunJieyuQuanzhong
			KEShi.keshiJijiangFenzhi = KEShi.chayiXishu * KEShi.jixiaoFenshu * 
				KEShi.huansuanRenshu * qUANZhong

			dep KEShi

		for KEShi in getDepartments()
			keshiJijiangFenzhi KEShi

	#i 计算科室计奖分值小计
	keshiJijiangFenzhiXiaoji = ->
		xj = 0
		for KEShi in getDepartments()
			xj += KEShi.keshiJijiangFenzhi
		xj


	#j 计算科室领奖比例, 用科室计奖分值/科室计奖分值小计
	do ->
		keshiLingjiangBili = (KEShi) ->
			KEShi.keshiLingjiangBili = KEShi.keshiJijiangFenzhi / keshiJijiangFenzhiXiaoji()
			dep KEShi

		for KEShi in getDepartments()
			keshiLingjiangBili KEShi

	#k 计算科室奖金, 用 科室领奖比例*总奖金池
	do ->
		keshiJiangjin = (KEShi) ->
			KEShi.keshiJiangjin = KEShi.keshiLingjiangBili * zongjiangJINchI() * FAjiangbiLi
			KEShi.renjunJiangjin = KEShi.keshiJiangjin / KEShi.shangbanRenshu
			dep KEShi

		for KEShi in getDepartments()
			keshiJiangjin KEShi



Meteor.methods
	baodi: (obj)-> upsertWithId share.Settings, obj
	dep: (obj)-> upsertTo share.Departments, obj
	#depId: (id, obj)-> upsertToId share.Departments, id, obj
	recalculate: recalculate
