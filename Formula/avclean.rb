class Avclean < Formula
  desc "On-demand ClamAV menu for macOS with a private scanning engine"
  homepage "https://github.com/koomean/avclean"
  url "https://github.com/koomean/avclean/archive/refs/tags/v2.1.0.tar.gz"
  sha256 "91119c72294c03eb68e71a4a9dd40ba9dc6e217fc907a89276ca68b23f698d9f"
  license all_of: ["MIT", "GPL-2.0-or-later", "curl"]

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on arch: :arm64
  depends_on "ca-certificates"
  depends_on "json-c"
  depends_on :macos
  depends_on "openssl@3"
  depends_on "pcre2"
  depends_on "python@3.14"

  uses_from_macos "bzip2"
  uses_from_macos "libxml2"
  uses_from_macos "ncurses"
  uses_from_macos "zlib"

  resource "curl" do
    url "https://curl.se/download/curl-8.23.0.tar.bz2"
    sha256 "95b22eb32bf6d1fa6e3e9463bdb61cece3efc56d86576a9b3cbd428246a6d854"
  end

  resource "clamav" do
    url "https://github.com/Cisco-Talos/clamav/releases/download/clamav-1.5.4/clamav-1.5.4.tar.gz"
    sha256 "1af1117a228f1b5bc7fa91a0dabc37848a99e7d25188e9be8043332ce721dfd3"
  end

  def install
    # The verified ClamAV release includes its complete locked Cargo vendor tree.
    ENV["CARGO_NET_OFFLINE"] = "true"

    runtime = libexec/"runtime"
    # Keep dependency path access compatible with Homebrew versions before 7.
    openssl = Formula["openssl@3"].opt_prefix
    openssl_args = %W[
      -DOPENSSL_ROOT_DIR=#{openssl}
      -DOPENSSL_INCLUDE_DIR=#{openssl}/include
      -DOPENSSL_CRYPTO_LIBRARY=#{openssl}/lib/libcrypto.3.dylib
      -DOPENSSL_SSL_LIBRARY=#{openssl}/lib/libssl.3.dylib
    ]
    private_rpath = "@loader_path/../lib"

    # FreshClam's SSL context callback requires curl and ClamAV to use OpenSSL.
    resource("curl").stage do
      system "cmake", "-S", ".", "-B", "build", *std_cmake_args(install_prefix: runtime),
             *openssl_args,
             "-DCMAKE_INSTALL_RPATH=#{private_rpath}",
             "-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=OFF",
             "-DBUILD_CURL_EXE=ON",
             "-DBUILD_EXAMPLES=OFF",
             "-DBUILD_LIBCURL_DOCS=OFF",
             "-DBUILD_MISC_DOCS=OFF",
             "-DBUILD_SHARED_LIBS=ON",
             "-DBUILD_STATIC_LIBS=OFF",
             "-DENABLE_CURL_MANUAL=OFF",
             "-DCURL_USE_OPENSSL=ON",
             "-DUSE_APPLE_SECTRUST=OFF",
             "-DCURL_CA_BUNDLE=#{Formula["ca-certificates"].pkgetc}/cert.pem",
             "-DCURL_USE_LIBPSL=OFF",
             "-DUSE_LIBIDN2=OFF",
             "-DUSE_NGHTTP2=OFF",
             "-DCURL_BROTLI=OFF",
             "-DCURL_ZSTD=OFF",
             "-DCURL_ZLIB=ON",
             "-DCURL_USE_LIBSSH2=OFF",
             "-DCURL_USE_GSSAPI=OFF",
             "-DCURL_DISABLE_LDAP=ON",
             "-DCURL_DISABLE_LDAPS=ON"
      system "cmake", "--build", "build"
      system "cmake", "--install", "build"
      (pkgshare/"licenses/curl").install "COPYING"
    end

    resource("clamav").stage do
      system "cmake", "-S", ".", "-B", "build", *std_cmake_args(install_prefix: runtime),
             *openssl_args,
             "-DCMAKE_INSTALL_RPATH=#{private_rpath}",
             "-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=OFF",
             "-DCURL_NO_CURL_CMAKE=TRUE",
             "-DCURL_INCLUDE_DIR=#{runtime}/include",
             "-DCURL_LIBRARY_RELEASE=#{runtime}/lib/libcurl.dylib",
             "-DCURL_LIBRARY_DEBUG=#{runtime}/lib/libcurl.dylib",
             "-DAPP_CONFIG_DIRECTORY=#{runtime}/etc",
             "-DDATABASE_DIRECTORY=#{runtime}/share/clamav",
             "-DENABLE_JSON_SHARED=ON",
             "-DENABLE_STATIC_LIB=OFF",
             "-DENABLE_SHARED_LIB=ON",
             "-DENABLE_EXAMPLES=OFF",
             "-DENABLE_TESTS=OFF",
             "-DENABLE_MILTER=OFF",
             "-DENABLE_MAN_PAGES=OFF",
             "-DENABLE_CLAMONACC=OFF",
             "-DENABLE_SYSTEMD=OFF"
      system "cmake", "--build", "build"
      system "cmake", "--install", "build"
      (pkgshare/"licenses/clamav").install "COPYING.txt", "COPYING"
      (pkgshare/"licenses/clamav/unrar").install "libclamunrar/license.txt"
      (pkgshare/"licenses/clamav/mspack").install "libclammspack/COPYING.LIB"
    end

    libexec.install "bin/av"
    (libexec/"lib").install "lib/av_engine.py"
    prefix.install "README.md", "LICENSE"
    bin.mkpath
    # The wrapper must also build on Homebrew versions before the new path helpers.
    (bin/"av").write <<~SH
      #!/bin/zsh
      export AV_ENGINE_PATH="#{libexec}/lib/av_engine.py"
      export AV_CLAMD_BIN="#{runtime}/sbin/clamd"
      export AV_CLAMSCAN_BIN="#{runtime}/bin/clamscan"
      export AV_FRESHCLAM_BIN="#{runtime}/bin/freshclam"
      export AV_PYTHON="#{Formula["python@3.14"].opt_libexec}/bin/python3"
      exec "#{libexec}/av" "$@"
    SH
    chmod 0555, bin/"av"
  end

  def caveats
    <<~EOS
      Run `av` to open the menu, or `av --self-test` to verify the private engine.
      The first scan downloads ClamAV signatures into your own user data folder.
      Scans, logs and quarantine are managed per user, outside the Homebrew keg.
      macOS may require Full Disk Access for your terminal to read protected files.
    EOS
  end

  test do
    ENV["AV_SELF_TEST_TMPDIR"] = testpath.to_s
    assert_match "avclean #{version} (av)", shell_output("#{bin}/av --version")
    assert_match "Usage:", shell_output("#{bin}/av --help")
    system bin/"av", "--self-test"
  end
end
