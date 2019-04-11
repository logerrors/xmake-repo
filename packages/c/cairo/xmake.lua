package("cairo")

    set_homepage("https://cairographics.org/")
    set_description("Vector graphics library with cross-device output support.")

    set_urls("https://cairographics.org/releases/cairo-$(version).tar.xz")
    add_versions("1.16.0", "5e7b29b3f113ef870d1e3ecf8adf21f923396401604bda16d44be45e66052331")
 
    if is_plat("windows") then
        add_deps("make", "libpng", "pixman", "zlib")
    else
        add_deps("pkg-config", "fontconfig", "freetype", "libpng", "pixman")
    end

    if is_plat("macosx") then
        add_frameworks("CoreGraphics", "CoreFoundation", "Foundation")
    elseif is_plat("windows") then
        add_syslinks("gdi32", "msimg32", "user32")
    else
        add_syslinks("pthread")
    end

    on_install("windows", function (package)
        io.gsub("build/Makefile.win32.common", "%-MD", "-" .. package:config("vs_runtime"))
        io.gsub("build/Makefile.win32.common", "mkdir %-p", "xmake l mkdir")
        io.gsub("build/Makefile.win32.common", "dirname", "xmake l path.directory")
        local pacman = package:dep("pacman")
        if pacman then
            print("pacman include", pacman:installdir("include/pixman-1"))
            local a, b = io.gsub("build/Makefile.win32.common", "%$%(PIXMAN_CFLAGS%)", "-I " .. os.args(pacman:installdir("include/pixman-1")))
            print("a", a)
            print("b", b)
        end
        local libpng = package:dep("libpng")
        if libpng then
            print("libpng")
            io.gsub("build/Makefile.win32.common", "%$%(LIBPNG_CFLAGS%)", "-I " .. os.args(libpng:installdir("include")))
        end
        local zlib = package:dep("zlib")
        if zlib then
            print("zlib")
            io.gsub("build/Makefile.win32.common", "%$%(ZLIB_CFLAGS%)", "-I " .. os.args(zlib:installdir("include")))
        end
        io.cat("build/Makefile.win32.common")
        os.vrunv("make", {"-f", "Makefile.win32", "CFG=" .. (package:debug() and "debug" or "release")})
    end)


    on_install("macosx", "linux", function (package)
        local configs = {"--disable-dependency-tracking", "--enable-shared=no"}
        table.insert(configs, "--enable-gobject=no")
        table.insert(configs, "--enable-svg=yes")
        table.insert(configs, "--enable-tee=yes")
        table.insert(configs, "--enable-quartz=no")
        table.insert(configs, "--enable-xlib=" .. (is_plat("macosx") and "no" or "yes"))
        table.insert(configs, "--enable-xlib-xrender=" .. (is_plat("macosx") and "no" or "yes"))
        import("package.tools.autoconf").install(package, configs) 
    end)

    on_test(function (package)
        assert(package:has_cfuncs("cairo_create", {includes = "cairo/cairo.h"}))
    end)