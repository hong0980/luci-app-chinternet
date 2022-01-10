m = Map("softwarecenter", translate("网站管理"),
translate("在正常运行 Nginx/PHP/MySQL 后再选择要部署的网站。可以自动部署PHP探针，phpMyAdmin，可道云，Typecho等。"))
m:section(SimpleSection).template = "softwarecenter/website_status"

s = m:section(TypedSection, "website", translate("网站部署"), 
translate("自动快速的部署网站。自动获取端口是在 2100 以上的空闲端口，自定义建议1024--5000之间。"))
s.anonymous = true
s.addremove = false
s.sortable = true
s.rmempty = false
s.template = "cbi/tblsection"

p = s:option(Flag, "autodeploy_enable", translate("部署 / 删除"))

p = s:option(Flag, "website_enabled", translate("启用"))

p = s:option(DummyValue, "website_name", translate(" "))

p = s:option(Value, "port", translate("访问端口,留空自动获取。"))

-- p = s:option(Flag,"redis_enabled", translate("启用Redis"), translate("Nextcloud<br>Owncloud"))

remarks = s:option(Value, "remarks", translate("备注"))
remarks.size = 8

return m
