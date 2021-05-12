font_green = [[<font color="green">]]
font_red = [[<font color="red">]]
font_off = [[</font>]]
bold_on  = [[<strong>]]
bold_off = [[</strong>]]

m=Map("chinternet",translate("Reboot schedule"),translate("<font color=\"green\"><b>A plug-in that makes planning tasks easier to use, you can use-to indicate a continuous time range, use to indicate multiple discontinuous time points, and use */ to indicate cyclic execution. You can use \"Add\" to add multiple scheduled task commands. You can use \"--Custom--\" to add other parameters yourself.</font></b>") .. "</br>" ..
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

month=s:option(Value,"month",translate("Month <font color=\" red\">(numerical range 1~12)</font>"),
translate("<font color=\"gray\">* means every month, */n means every n months</br>n1-n5 are continuous, n1, n3, n5 are not continuous</font>"))
month.rmempty = false
month.default = '*'

day=s:option(Value,"day",translate("Day <font color=\" red\">(numerical range 1~31)</font>"),
translate("<font color=\"gray\">* means every day, */n means every n days</br>n1-n5 are continuous, n1, n3, n5 are not continuous</font>"))
day.rmempty = false
day.default = '*'

week=s:option(Value,"week",translate("week <font color=\" red\">(Numerical range0~6)</font>"),
translate("<font color=\"gray\">* and date is a logical AND relationship</br>n1-n5 are continuous, n1, n3, n5 are not continuous</font>"))
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

hour=s:option(Value,"hour",translate("hour <font color=\" red\">(Numerical range0~23)</font>"),
translate("<font color=\"gray\">* means every hour, */n means every n hours</br>n1-n5 are continuous, n1, n3, n5 are not continuous</font>"))
hour.rmempty = false
hour.default = '5'

minute=s:option(Value,"minute",translate("minute <font color=\" red\">(Numerical range0~59)</font>"),
translate("<font color=\"gray\">* means every minute, */n means every n minutes</br>n1-n5 continuous, n1, n3, n5 not continuous</font>"))
minute.rmempty = false
minute.default = '0'

command=s:option(Value,"command",translate("Execute the command <font color=\" red\">(multiple items connected with &&)</font>"),
translate("<font color=\"gray\">Press \"--Custom--\" to modify it</br> (it can also be added and modified in the scheduled task)</font>"))
command:value('sleep 5 && touch /etc/banner && reboot',translate("Reboots"))
command:value('/etc/init.d/network restart',translate("Restart network"))
command:value('ifdown wan && ifup wan',translate("Restart wan"))
command:value('killall -q pppd && sleep 5 && pppd file /tmp/ppp/options.wan', translate("Redial"))
command:value('ifdown wan',translate("Turn off networking"))
command:value('ifup wan',translate("Turn on networking"))
command:value('wifi down',translate("Turn off WIFI"))
command:value('wifi up',translate("Turn on WIFI"))
command:value('sync && echo 3 > /proc/sys/vm/drop_caches', translate("Free up memory"))
command:value('poweroff',translate("Turn off the power"))
command.default='sleep 5 && touch /etc/banner && reboot'

local e=luci.http.formvalue("cbi.apply")
if e then
  io.popen("/etc/init.d/chinternet restart")
end

return m
