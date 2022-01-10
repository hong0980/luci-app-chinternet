# Copyright (C) 2019 Jianpeng Xiang (1505020109@mail.hnust.edu.cn)

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-softwarecenter
PKG_VERSION=2.2.1
PKG_RELEASE:=20220106

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  DEPENDS:=@(aarch64||arm||x86_64||mipsel) +parted +e2fsprogs +lsof
  TITLE:=LuCI Support for Software Center
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/softwarecenter
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/* $(1)/etc/init.d/

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./root/etc/uci-defaults/* $(1)/etc/uci-defaults/

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./root/etc/config/* $(1)/etc/config/

	$(INSTALL_DIR) $(1)/usr/bin/softwarecenter
	$(INSTALL_BIN) ./root/usr/bin/softwarecenter/* $(1)/usr/bin/softwarecenter/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
