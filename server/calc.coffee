share.consolelog = (collection , obj)->
	console.log "object now is ", collection.findOne( indx: obj.indx )  

getDepartments = ->
	share.Departments.find() 
console.log getDepartments()

share.upsertTo = (collection, obj)-> 
	# each obj should have an indx; return Mongodb object _id
	if true #share.adminLoggedIn
		obj.createdOn = new Date
		collection.update indx: obj.indx ,
			obj, 
			upsert: true
		share.consolelog collection, obj
share.upsertWithId = (collection, obj)-> 
	# each obj should have an indx; return Mongodb object _id
	if share.adminLoggedIn
		obj.createdOn = new Date
		collection.update _id: obj._id ,
			obj, 
			upsert: true

dep = (obj)-> 
	share.upsertWithId share.Departments, obj
	console.log obj.indx


share.recalculate = ->
	
	#a 计算可奖结余即总奖金池, 为各部门可奖结余之和
	kejiangJieyu = ->
		p = 0
		for keshi in getDepartments()
			p += keshi.jieyu
			console.log p
		p
	
	zongJiangjinchi = kejiangJieyu 
	console.log zongJiangjinchi()
	
	#b 计算人均结余
	#b1 计算各自人均结余, 用科室可奖结余除以换算人数,注意换算人数
	renjunJieyu = (keshi)-> 
		keshi.renjunJieyu = keshi.jieyu / keshi.huansuanRenshu
		dep keshi
	
	for keshi in getDepartments()
		renjunJieyu keshi
###
	#b2 计算人均结余小计, 用总奖金池除以各部门实际人数和,注意是实际人数
	shangbanRenshuXiaoji = (geKeshi) -> 
		xj = 0
		for keshi in geKeshi
			xj += keshi.shangbanRenshu
		xj
			
	renjunJieyuXiaoji = zongJiangjinchi() / shangbanRenshuXiaoji( getDepartments())
	
	#c 计算人均结余加保底
	renjunJieyuJiaBaoDi = (keshi) ->
		x = keshi.jieyu / keshi.huansuanRenshu
		avb = Session.get "renjunBaodiJieyu"
		keshi.renjunJieyuJiaBaoDi = if x > avb then x else avb
		Meteor.call "dep", keshi

	for keshi in getDepartments()
		renjunJieyuJiaBaoDi keshi

	#d 计算结余加保底,即各科室各自 换算人数*人均结余加保底
	jieyuJiaBaodi = (keshi) ->
		keshi.jieyuJiaBaodi = keshi.huansuanRenshu * keshi.renjunJieyuJiaBaoDi
		Meteor.call "dep", keshi
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
		keshi.renjunJieyuQuanzhong = keshi.renjunJieyuJiaBaoDi / renjunJieyuJiaBaoDiXiaoji
		Meteor.call "dep", keshi

	for keshi in getDepartments()
		renjunJieyuQuanzhong keshi
	
	#h 计算科室计奖分值, 用科室 绩效分数*换算人数*人均结余权重
	keshiJijiangFenzhi = (keshi) ->
		keshi.keshiJijiangFenzhi = keshi.jixiaoFenshu * keshi.huansuanRenshu * keshi.renjunJieyuQuanzhong
		Meteor.call "dep", keshi

	for keshi in getDepartments()
		keshiJijiangFenzhi keshi

	#i 计算科室计奖分值小计
	keshiJijiangFenzhiXiaoji = do ()->
		xj = 0
		for keshi in getDepartments()
			xj += keshiJijiangFenzhi keshi
		xj

	
	#j 计算科室领奖比例, 用科室计奖分值/科室计奖分值小计
	keshiLingjiangBili = (keshi) ->
		keshi.keshiLingjiangBili = keshi.keshiJijiangFenzhi / keshiJijiangFenzhiXiaoji
		Meteor.call "dep", keshi

	for keshi in getDepartments()
		keshiLingjiangBili keshi

	#k 计算科室奖金, 用 科室领奖比例*总奖金池
	keshiJiangjin = (keshi) ->
		keshi.keshiJiangjin = keshi.keshiLingjiangBili * zongJiangjinchi()
		keshi.renjunJiangjin = keshi.keshiJiangjin / keshi.shangbanRenshu
		Meteor.call "dep", keshi

	for keshi in getDepartments()
		keshiJiangjin keshi


###