getDeps = Session.get "departments"

recalculate = ->
	console.log 'recalculating'
	#a 计算可奖结余即总奖金池, 为各部门可奖结余之和
	kejiangJieyu = (geKeshi)->
		p = 0
		for keshi in geKeshi
			p += keshi.jieyu
		p
	
	zongJiangjinchi = ->
		kejiangJieyu getDeps
		
	#b 计算人均结余
	#b1 计算各自人均结余, 用科室可奖结余除以换算人数,注意换算人数
	renjunJieyu = (keshi)-> 
		keshi.renjunJieyu = keshi.jieyu / keshi.huansuanRenshu
	
	for keshi in getDeps
		renjunJieyu keshi

	#b2 计算人均结余小计, 用总奖金池除以各部门实际人数和,注意是实际人数
	shangbanRenshuXiaoji = -> 
		xj = 0
		for keshi in getDeps
			xj += keshi.shangbanRenshu
		xj
			
	renjunJieyuXiaoji = zongJiangjinchi() / shangbanRenshuXiaoji()
	
	#c 计算人均结余加保底
	renjunJieyuJiaBaoDi = (keshi) ->
		x = keshi.jieyu / keshi.huansuanRenshu
		avb = Session.get "renjunBaodiJieyu"
		keshi.renjunJieyuJiaBaoDi = if x > avb then x else avb

	#d 计算结余加保底,即各科室各自 换算人数*人均结余加保底
	jieyuJiaBaodi = (keshi) ->
		keshi.jieyuJiaBaodi = keshi.huansuanRenshu * keshi.renjunJieyuJiaBaoDi

	#e 计算结余加保底和
	jieyuJiaBaodiXiaoji = (geKeshi) ->
		xj = 0
		for keshi in geKeshi
			xj += keshi.jieyuJiaBaodi
		xj
	jieyuJiaBaodiHe = jieyuJiaBaodiXiaoji getDeps	
	
	#f 计算人均结余加保底小计, 用 结余加保底和除以换算人数小计
	huansuanRenshuXiaoji = (geKeshi) ->
		xj = 0
		for keshi in geKeshi 
			xj += keshi.huansuanRenshu
		xj
		
	renjunJieyuJiaBaoDiXiaoji = jieyuJiaBaodiHe / huansuanRenshuXiaoji(getDeps)

	#g 计算人均结余权重, 用 各科室各自 人均结余加保底除以人均结余加保底小计
	renjunJieyuQuanzhong = (keshi) ->
		keshi.renjunJieyuQuanzhong = keshi.renjunJieyuJiaBaoDi / renjunJieyuJiaBaoDiXiaoji

	for keshi in getDeps
		renjunJieyuQuanzhong keshi
	
	#h 计算科室计奖分值, 用科室 绩效分数*换算人数*人均结余权重
	keshiJijiangFenzhi = (keshi) ->
		keshi.keshiJijiangFenzhi = keshi.jixiaoFenshu * keshi.huansuanRenshu * keshi.renjunJieyuQuanzhong


	#i 计算科室计奖分值小计
	keshiJijiangFenzhiXiaoji = do ()->
		xj = 0
		for keshi in getDeps
			xj += keshiJijiangFenzhi keshi
		xj

	
	#j 计算科室领奖比例, 用科室计奖分值/科室计奖分值小计
	keshiLingjiangBili = (keshi) ->
		keshi.keshiLingjiangBili = keshi.keshiJijiangFenzhi / keshiJijiangFenzhiXiaoji
	
	#k 计算科室奖金, 用 科室领奖比例*总奖金池
	keshiJiangjin = (keshi)->
		keshi.keshiJiangjin = keshi.keshiLingjiangBili * zongJiangjinchi()

###
Session.set "departments", [
		(deptname: '胸心2'), 
		(deptname: '消化内'),
		(deptname: '肝胆内')
	]

for keshi in getDeps
	keshi.shangbanRenshu = 3
	keshi.huansuanRenshu = 3
	keshi.jieyu = 50000
	keshi.diff = 1
###
departments = -> getDeps

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
		console.log @

Template.tableView.departments = ->
	getDeps
