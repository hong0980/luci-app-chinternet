module("luci.controller.chinternet", package.seeall)

function index()
	local fs = require "nixio.fs"
--	if not nixio.fs.access("/etc/config/chinternet") then
--		return
--	end

	entry({"admin", "services", "chinternet"},
		alias("admin", "services", "chinternet", "general"),
		_("Reboot schedule"), 10)

	entry({"admin", "services", "chinternet", "general"},
		cbi("chinternet/general"),
		_("General Settings"), 20).leaf = true

	entry({"admin", "services", "chinternet", "crontab"},
		cbi("chinternet/crontab"),
		_("Scheduled Tasks"), 30).leaf = true
end