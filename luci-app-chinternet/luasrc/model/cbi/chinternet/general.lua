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

month=s:option(Value,"month",translate("�� <font color=\" red\">(��ֵ��Χ1��12)</font>"),
translate("<font color=\"gray\">*��ʾÿ���£�*/n��ʾÿn����</br>n1-n5������n1,n3,n5������</font>"))
month.rmempty = false
month.default = '*'

day=s:option(Value,"day",translate("�� <font color=\" red\">(��ֵ��Χ1��31)</font>"),
translate("<font color=\"gray\">*��ʾÿ�죬*/n��ʾÿn��</br>n1-n5������n1,n3,n5������</font>"))
day.rmempty = false
day.default = '*'

week=s:option(Value,"week",translate("���� <font color=\" red\">(��ֵ��Χ0��6)</font>"),
translate("<font color=\"gray\">���������߼����롱��ϵ</br>n1-n5������n1,n3,n5������</font>"))
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

hour=s:option(Value,"hour",translate("ʱ <font color=\" red\">(��ֵ��Χ0��23)</font>"),
translate("<font color=\"gray\">*��ʾÿСʱ��*/n��ʾÿnСʱ</br>n1-n5������n1,n3,n5������</font>"))
hour.rmempty = false
hour.default = '5'

minute=s:option(Value,"minute",translate("�� <font color=\" red\">(��ֵ��Χ0��59)</font>"),
translate("<font color=\"gray\">*��ʾÿ���ӣ�*/n��ʾÿn����</br>n1-n5������n1,n3,n5������</font>"))
minute.rmempty = false
minute.default = '0'

command=s:option(Value,"command",translate("ִ������ <font color=\" red\">(������ && ����)</font>"),
translate("<font color=\"gray\">����--�Զ���--���ɽ����޸�</br>(�����Ӻ󵽼ƻ��������޸�)</font>"))
command:value('sleep 5 && touch /etc/banner && reboot',translate("1.����ϵͳ"))
command:value('/etc/init.d/network restart',translate("2.��������"))
command:value('ifdown wan && ifup wan',translate("3.����wan"))
command:value('killall -q pppd && sleep 5 && pppd file /tmp/ppp/options.wan', translate("4.���²���"))
command:value('ifdown wan',translate("5.�ر�����"))
command:value('ifup wan',translate("6.������"))
command:value('wifi down',translate("7.�ر�WIFI"))
command:value('wifi up',translate("8.��WIFI"))
command:value('sync && echo 3 > /proc/sys/vm/drop_caches', translate("9.�ͷ��ڴ�"))
command:value('poweroff',translate("0.�رյ�Դ"))
command.default='sleep 5 && touch /etc/banner && reboot'

local e=luci.http.formvalue("cbi.apply")
if e then
  io.popen("/etc/init.d/chinternet restart")
end

return m
