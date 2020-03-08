include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-dockerman
PKG_VERSION:=v0.4.2
PKG_RELEASE:=beta
PKG_MAINTAINER:=lisaac <https://github.com/lisaac/luci-app-dockerman>
PKG_LICENSE:=AGPL-3.0

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/lisaac/luci-app-dockerman.git
PKG_SOURCE_VERSION:=$(PKG_VERSION)

PKG_SOURCE_SUBDIR:=$(PKG_NAME)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR)-$(PKG_SOURCE_VERSION).tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)/config
config PACKAGE_$(PKG_NAME)_INCLUDE_docker_ce
	bool "Include Docker-CE"
	default n
config PACKAGE_$(PKG_NAME)_INCLUDE_ttyd
	bool "Include ttyd"
	default y
endef

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=Docker Manager interface for LuCI
	PKGARCH:=all
	DEPENDS:=+luci-lib-docker \
	+PACKAGE_$(PKG_NAME)_INCLUDE_docker_ce:docker-ce \
	+PACKAGE_$(PKG_NAME)_INCLUDE_ttyd:ttyd
endef

define Package/$(PKG_NAME)/description
	Docker Manager interface for LuCI
endef

define Build/Prepare
	tar -xzvf $(DL_DIR)/$(PKG_SOURCE) -C $(BUILD_DIR)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	uci set uhttpd.main.script_timeout="600" >/dev/null 2>&1
	uci commit uhttpd >/dev/null 2>&1
	uci delete ucitrack.@dockerd[-1] >/dev/null 2>&1
	uci add ucitrack dockerd >/dev/null 2>&1
	uci set ucitrack.@dockerd[-1].init=dockerd >/dev/null 2>&1
	uci commit ucitrack >/dev/null 2>&1
	rm -fr /tmp/luci-indexcache /tmp/luci-modulecache >/dev/null 2>&1
	chmod +x /etc/init.d/dockerd >/dev/null 2>&1
	/etc/init.d/uhttpd restart >/dev/null 2>&1
fi
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	cp -pR $(PKG_BUILD_DIR)/root/* $(1)/
	# $(INSTALL_DIR) $(1)/www
	# cp -pR $(PKG_BUILD_DIR)/htdoc/* $(1)/www
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR $(PKG_BUILD_DIR)/luasrc/* $(1)/usr/lib/lua/luci/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$$(foreach po,$$(shell find $(PKG_BUILD_DIR)/po/*/*.po), \
		po2lmo $$(po) \
		$(1)/usr/lib/lua/luci/i18n/dockerman.$$(shell echo $$(po) | awk -F'/' '{print $$$$(NF-1)}').lmo;)
	#po2lmo $(PKG_BUILD_DIR)/po/zh-cn/dockerman.po $(1)/usr/lib/lua/luci/i18n/dockerman.zh-cn.lmo
endef

$(eval $(call BuildPackage,$(PKG_NAME)))