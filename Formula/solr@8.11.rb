class SolrAT811 < Formula
  desc "Enterprise search platform from the Apache Lucene project"
  homepage "https://solr.apache.org/"
  url "https://dlcdn.apache.org/lucene/solr/8.11.2/solr-8.11.2.tgz"
  sha256 "54d6ebd392942f0798a60d50a910e26794b2c344ee97c2d9b50e678a7066d3a6"
  license "Apache-2.0"

  keg_only :versioned_formula

  depends_on "openjdk"

  def install
    pkgshare.install "bin/solr.in.sh"
    (var/"lib/solr").install "server/solr/README.txt", "server/solr/solr.xml", "server/solr/zoo.cfg"
    prefix.install "contrib", "dist", "licenses", "server"
    bin.install "bin/solr", "bin/post", "bin/oom_solr.sh"

    env = Language::Java.overridable_java_home_env
    env["SOLR_HOME"] = "${SOLR_HOME:-#{var}/lib/solr}"
    env["SOLR_LOGS_DIR"] = "${SOLR_LOGS_DIR:-#{var}/log/solr}"
    env["SOLR_PID_DIR"] = "${SOLR_PID_DIR:-#{var}/run/solr}"
    bin.env_script_all_files libexec, env

    inreplace libexec/"solr", "/usr/local/share/solr", pkgshare
  end

  def post_install
    (var/"run/solr").mkpath
    (var/"log/solr").mkpath
  end

  service do
    run [opt_bin/"solr", "start", "-f", "-s", HOMEBREW_PREFIX/"var/lib/solr"]
    working_dir HOMEBREW_PREFIX
  end

  test do
    # Test fails in docker, see https://github.com/apache/solr/pull/250
    # Newset solr version has been fixed, this legacy version will not be patched,
    # so just ignore the test.
    return if OS.linux? && ENV["HOMEBREW_GITHUB_ACTIONS"]

    ENV["SOLR_PID_DIR"] = testpath
    port = free_port

    # Info detects no Solr node => exit code 3
    shell_output(bin/"solr -i", 3)
    # Start a Solr node => exit code 0
    shell_output(bin/"solr start -p #{port} -Djava.io.tmpdir=/tmp")
    # Info detects a Solr node => exit code 0
    shell_output(bin/"solr -i")
    # Impossible to start a second Solr node on the same port => exit code 1
    shell_output(bin/"solr start -p #{port}", 1)
    # Stop a Solr node => exit code 0
    # Exit code is 1 without init process in a docker container
    shell_output(bin/"solr stop -p #{port}", (OS.linux? && ENV["HOMEBREW_GITHUB_ACTIONS"]) ? 1 : 0)
    # No Solr node left to stop => exit code 1
    shell_output(bin/"solr stop -p #{port}", 1)
  end
end
