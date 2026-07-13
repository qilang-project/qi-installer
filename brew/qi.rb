# Homebrew Formula —— 奇语言 (qilang)
#
# 用法：
#   brew install --formula ./qi.rb          # 本地直接装
#   # 或建 tap 后：brew tap qilang-project/qi && brew install qi
#
# 说明：release 包是「原生二进制 + 静态 runtime」，解压即用。
#   编译产物零运行时依赖；qi 自身编译代码时需系统 clang（macOS 自带 Xcode CLT）。
#
# 每次发新版：跑 qi-installer/scripts/更新安装清单.sh <tag> 自动刷版本号与 sha256。
class Qi < Formula
  desc "奇语言 —— 100% 中文关键字的原生编译语言（LLVM 后端，AI 原语内置）"
  homepage "https://github.com/qilang-project/qi"
  version "2026.07.13-1"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/qilang-project/qi/releases/download/2026.07.13-1/qi-2026.07.13-1-macos-arm64.tar.gz"
      sha256 "5b44c097f1ac964993d626dbafd5c72ddc623aef5e8c5a67afc39c97696eb3ae"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/qilang-project/qi/releases/download/2026.07.13-1/qi-2026.07.13-1-linux-x64.tar.gz"
      sha256 "c9ada4d383dc6dca96f2a94541873a52d245a644ae09a96fcde87f2e50f43d17"
    end
  end

  def install
    # release 包布局：bin/qi + lib/qi/（libqi_runtime.a + 捆绑动态库）
    # 装到 Homebrew prefix 后 bin 与 lib 同级，qi 按 <prefix>/lib/qi 自动找运行时库
    bin.install "bin/qi"
    (lib/"qi").install Dir["lib/qi/*"]
  end

  def caveats
    <<~EOS
      qi 编译代码时需要系统 clang 做链接：
        macOS：xcode-select --install
      编译产物（qi compile 出的可执行文件）零运行时依赖，可独立分发。
    EOS
  end

  test do
    (testpath/"你好.qi").write <<~QI
      包 主程序;
      导入 标准库.输入输出 作为 IO;
      函数 入口() { IO.打印行("brew ok"); }
    QI
    assert_match "brew ok", shell_output("#{bin}/qi run #{testpath}/你好.qi")
  end
end
