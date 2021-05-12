font_green = [[<font color="green">]]
font_red = [[<font color="red">]]
font_off = [[</font>]]
bold_on  = [[<strong>]]
bold_off = [[</strong>]]

m=Map("chinternet",translate("Reboot schedule"),translate("A plug-in that makes planning tasks easier to use, you can use-to indicate a continuous time range, use to indicate multiple discontinuous time points, and use */ to indicate cyclic execution. You can use \"Add\" to add multiple scheduled task commands. You can use \"--Custom--\" to add other parameters yourself.") .. "</br>" ..
translate("*All time parameters refer to the time point in the natural unit, not the cumulative count. For example, the month can only be 1-12, the date can only be 1 to 31, the week can only be 0-6, and the hour can only be 0. -23, the minutes can only be 0-59, and the cumulative counting notation of 50 days and 48 hours cannot be used.") .. "</br>" ..
translate("* All values can be used-Connection means continuous range, such as week: 1-5 means Monday to Friday; use, means non-continuous point, such as week: 1, 3, 5 means only Monday, Wednesday, and Friday. The month, date, and time are used in the same way.") .."</br>" ..
translate("<input class=\"cbi-button cbi-button-apply\" type=\"button\" value=\"" ..
translate("View usage example") ..
" \" onclick=\"window.open('http://'+window.location.hostname+'/reboothelp.jpg')\"/>") ..
translate("&nbsp;&nbsp;&nbsp;<input class=\"cbi-button cbi-button-apply\" type=\"button\" value=\"" ..
 translate("View crontab usage") ..
" \" onclick=\"window.open('https://tool.lu/crontab/')\"/>")
)

s=m:section(TypedSection,"crontab","")
s.anonymous = true
s.addremove = true
s.sortable = false
s.template = "cbi/tblsection"
s.rmempty = false

p=s:option(Flag,"enable",translate("Enable"))
p.rmempty = false
p.default=0

month=s:option(Value,"month",translate("月 <font color=\" red\">(数值范围1～12)</font>"),
translate("<font color=\"gray\">*表示每个月，*/n表示每n个月</br>n1-n5连续，n1,n3,n5不连续</font>"))
month.rmempty = false
month.default = '*'

day=s:option(Value,"day",translate("日 <font color=\" red\">(数值范围1～31)</font>"),
translate("<font color=\"gray\">*表示每天，*/n表示每n天</br>n1-n5连续，n1,n3,n5不连续</font>"))
day.rmempty = false
day.default = '*'

week=s:option(Value,"week",translate("星期 <font color=\" red\">(数值范围0～6)</font>"),
translate("<font color=\"gray\">和日期是逻辑“与”关系</br>n1-n5连续，n1,n3,n5不连续</font>"))
week.rmempty = true
week:value('*',translate("Everyday"))
week:value(0,translate("Sunday"))
week:value(1,translate("Monday"))
week:value(2,translate("Tuesday"))
week:value(3,translate("Wednesday"))
week:value(4,translate("Thursday"))
week:value(5,translate("Friday"))
week:value(6,translate("Saturday"))
week.default='*'

hour=s:option(Value,"hour",translate("时 <font color=\" red\">(数值范围0～23)</font>"),
translate("<font color=\"gray\">*表示每小时，*/n表示每n小时</br>n1-n5连续，n1,n3,n5不连续</font>"))
hour.rmempty = false
hour.default = '5'

minute=s:option(Value,"minute",translate("分 <font color=\" red\">(数值范围0～59)</font>"),
translate("<font color=\"gray\">*表示每分钟，*/n表示每n分钟</br>n1-n5连续，n1,n3,n5不连续</font>"))
minute.rmempty = false
minute.default = '0'

command=s:option(Value,"command",translate("执行命令 <font color=\" red\">(多条用 && 连接)</font>"),
translate("<font color=\"gray\">按“--自定义--”可进行修改</br>(亦可添加后到计划任务中修改)</font>"))
command:value('sleep 5 && touch /etc/banner && reboot',translate("1.重启系统"))
command:value('/etc/init.d/network restart',translate("2.重启网络"))
command:value('ifdown wan && ifup wan',translate("3.重启wan"))
command:value('killall -q pppd && sleep 5 && pppd file /tmp/ppp/options.wan', translate("4.重新拨号"))
command:value('ifdown wan',translate("5.关闭联网"))
command:value('ifup wan',translate("6.打开联网"))
command:value('wifi down',translate("7.关闭WIFI"))
command:value('wifi up',translate("8.打开WIFI"))
command:value('sync && echo 3 > /proc/sys/vm/drop_caches', translate("9.释放内存"))
command:value('poweroff',translate("0.关闭电源"))
command.default='sleep 5 && touch /etc/banner && reboot'

local e=luci.http.formvalue("cbi.apply")
if e then
  io.popen("/etc/init.d/chinternet restart")
end

return m
