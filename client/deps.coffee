for dep in [
		{deptname: '胸心2', shangbanRenshu: 3, huansuanRenshu: 3, jieyu: 5000, diff: 1, jixiaoFenshu: 99}, 
		{deptname: '消化内', shangbanRenshu:3, huansuanRenshu: 3, jieyu: 5000, diff: 1, jixiaoFenshu: 99},
		{deptname: '肝胆内', shangbanRenshu:3, huansuanRenshu: 3, jieyu: 5000, diff: 1, jixiaoFenshu: 99}
	]

	share.Departments.insert dep 
 
Session.set "departments", share.Departments.find {}
