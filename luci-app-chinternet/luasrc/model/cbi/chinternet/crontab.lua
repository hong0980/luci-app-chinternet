local fs = require "nixio.fs"
local cronfile = "/etc/crontabs/root" 

f = SimpleForm("crontab", translate(""),
	translate("Scheduled tasks in system crontab.<br/>You can also edit or add commands directly here."))

t = f:field(TextValue, "crons")
t.rmempty = true
t.rows = 10
function t.cfgvalue()
	return fs.readfile(cronfile) or ""
end

function f.handle(self, state, data)
	if state == FORM_VALID then
		if data.crons then
			fs.writefile(cronfile, data.crons:gsub("\r\n", "\n"))
			luci.sys.call("/usr/bin/crontab %q" % cronfile)
		else
			fs.writefile(cronfile, "")
		end
	end
	return true
end

return f