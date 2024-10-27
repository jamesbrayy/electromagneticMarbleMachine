local s = 30
local table = {}

showconsole()
clearconsole()

mydir="./"
open(mydir .. "coilgun.fem")
mi_saveas(mydir .. "temp.fem")
mi_seteditmode("group")

for n = 0, s do
	mi_analyze()
	mi_loadsolution()
	mo_groupselectblock(1)
	fz = mo_blockintegral(19)
	print((s-n)/10,fz)
	table[(s-n)/10] = fz
	if (n < s) then
		mi_selectgroup(1)
    	mi_movetranslate(0,0.1)
	end
end

print(table)

mo_close()
mi_close()