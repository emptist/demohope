###
Meteor.publish "depsChannel" , ->
	share.Departments.find()
###

share.adminLoggedIn = true

share.consolelog = (collection , obj)->
	console.log "object now is ", collection.findOne( indx: obj.indx ) 

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



	
Meteor.startup ->
	upsertTo share.Settings, {vari:"renjunBaoDiJieyu", val: 0.5, ratio: 0.3}
	for dep in [
			{indx:1, deptname: 'A', shangbanRenshu: 10, huansuanRenshu: 10, jieyu: 50000, chayiXishu: 1.0, jixiaoFenshu: 99}, 
			{indx:2, deptname: 'B', shangbanRenshu: 10, huansuanRenshu: 10, jieyu: 50000, chayiXishu: 1.0, jixiaoFenshu: 99},
			{indx:3, deptname: 'C', shangbanRenshu: 10, huansuanRenshu: 10, jieyu: 50000, chayiXishu: 1.0, jixiaoFenshu: 99},
			{indx:4, deptname: 'D', shangbanRenshu: 10, huansuanRenshu: 10, jieyu: 50000, chayiXishu: 1.0, jixiaoFenshu: 99}
		]
	 
		Meteor.call "dep", dep

 

getDepartments = ->
	share.Departments.find().fetch() 
	#share.Departments.find() <-- it took a lot of time to find this bug: missing fetch()  




dep = (obj)-> 
	upsertWithId share.Departments, obj
	#console.log obj.indx


recalculate = ->
	console.log "getDepartments", getDepartments()	
	#a 计算可奖结余即总奖金池, 为各部门可奖结余之和
	bdBi = share.Settings.findOne().val
	fjBi = share.Settings.findOne().ratio
	
	kejiangJieyu = ->
		p = 0
		for keshi in getDepartments()
			p += keshi.jieyu
			#console.log p
		Math.max 0, p

	zongJiangjinchi = kejiangJieyu  
	console.log "***** recalculate *****", zongJiangjinchi()
	
	#b 计算换算人均结余
	#b1 计算各自换算人均结余, 用科室可奖结余除以人数,注意 人数
	#huansuanRenjunJieyu = (keshi)-> 
	#	keshi.huansuanRenjunJieyu = keshi.jieyu / keshi.huansuanRenshu
	renjunJieyu = (keshi)-> 
		keshi.renjunJieyu = keshi.jieyu / keshi.shangbanRenshu
		dep keshi
	
	for keshi in getDepartments()
		renjunJieyu keshi
		#huansuanRenjunJieyu keshi
	
		
	#b2 计算人均结余小计, 用总奖金池除以各部门实际人数和,注意是实际人数
	shangbanRenshuXiaoji = (geKeshi) -> 
		xj = 0
		for keshi in geKeshi
			xj += keshi.shangbanRenshu
		xj
			
	renjunJieyuXiaoji = zongJiangjinchi() / shangbanRenshuXiaoji( getDepartments())
	
	#c 计算人均结余加保底
	avb = -> bdBi * renjunJieyuXiaoji #/ fjBi
	
	cnt = 0 # 用于在亏损部门多的情况下,调节保底金额
	for keshi in getDepartments() when keshi.renjunJieyu < avb()
		cnt += 1
	#cnt = 1 #<-- 调整保底金额开关,去掉此处注释,并取1即可随着亏损科室增加,保底奖金快速减少

	renjunJieyuJiaBaodi = (keshi) ->
		#x = keshi.huansuanRenjunJieyu
		x = keshi.renjunJieyu
		
		if x > avb() 
			keshi.renjunJieyuJiaBaodi =	x
		else 
			keshi.renjunJieyuJiaBaodi = avb() * cnt
		dep keshi

	for keshi in getDepartments()
		renjunJieyuJiaBaodi keshi

	#d 计算结余加保底,即各科室各自  人数*人均结余加保底
	jieyuJiaBaodi = (keshi) ->
		keshi.jieyuJiaBaodi = keshi.shangbanRenshu * keshi.renjunJieyuJiaBaodi
		dep keshi
		
	for keshi in getDepartments()
		jieyuJiaBaodi keshi

	#e 计算结余加保底和
	jieyuJiaBaodiXiaoji = (geKeshi) ->
		xj = 0
		for keshi in geKeshi
			xj += keshi.jieyuJiaBaodi
		xj

	jieyuJiaBaodiHe = jieyuJiaBaodiXiaoji getDepartments()	
	
	#f 计算人均结余加保底小计, 用 结余加保底和除以换算人数小计
	huansuanRenshuXiaoji = (geKeshi) ->
		xj = 0
		for keshi in geKeshi 
			xj += keshi.huansuanRenshu
		xj
		
	renjunJieyuJiaBaoDiXiaoji = jieyuJiaBaodiHe / huansuanRenshuXiaoji(getDepartments())
	
	#g 计算人均结余权重, 用 各科室各自 人均结余加保底除以人均结余加保底小计
	renjunJieyuQuanzhong = (keshi) ->
		keshi.renjunJieyuQuanzhong = keshi.renjunJieyuJiaBaodi / renjunJieyuJiaBaoDiXiaoji
		dep keshi

	for keshi in getDepartments()
		renjunJieyuQuanzhong keshi
	
	
	#h 计算科室计奖分值, 用科室 绩效分数*换算人数*人均结余权重
	keshiJijiangFenzhi = (keshi) ->
		keshi.keshiJijiangFenzhi = keshi.chayiXishu * keshi.jixiaoFenshu * keshi.huansuanRenshu * keshi.renjunJieyuQuanzhong
		dep keshi

	for keshi in getDepartments()
		keshiJijiangFenzhi keshi

	#i 计算科室计奖分值小计
	keshiJijiangFenzhiXiaoji = ->
		xj = 0
		for keshi in getDepartments()
			xj += keshi.keshiJijiangFenzhi
		console.log xj
		xj


	#j 计算科室领奖比例, 用科室计奖分值/科室计奖分值小计
	keshiLingjiangBili = (keshi) ->
		keshi.keshiLingjiangBili = keshi.keshiJijiangFenzhi / keshiJijiangFenzhiXiaoji()
		dep keshi

	for keshi in getDepartments()
		keshiLingjiangBili keshi

	#k 计算科室奖金, 用 科室领奖比例*总奖金池
	keshiJiangjin = (keshi) ->
		keshi.keshiJiangjin = keshi.keshiLingjiangBili * zongJiangjinchi() * fjBi
		keshi.renjunJiangjin = keshi.keshiJiangjin / keshi.shangbanRenshu
		dep keshi

	for keshi in getDepartments()
		keshiJiangjin keshi

###	
###

Meteor.methods
	baodi: (obj)-> upsertWithId share.Settings, obj
	dep: (obj)-> upsertTo share.Departments, obj
	#depId: (id, obj)-> upsertToId share.Departments, id, obj
	recalculate: recalculate
