m=Map("softwarecenter",translate("Nginx日志"),translate("Nginx的运行和错误日志"))
m:section(SimpleSection).template = "softwarecenter/access_log"
m:section(SimpleSection).template = "softwarecenter/error_log"
return m