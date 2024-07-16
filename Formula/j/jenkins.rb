class Jenkins < Formula
  desc "Extendable open source continuous integration server"
  homepage "https://www.jenkins.io/"
  url "https://get.jenkins.io/war/2.468/jenkins.war"
  sha256 "d0f6dfc74dd2baa6ad17d8654d457197af500ab33420bcc6d4d941f80beacb71"
  license "MIT"

  livecheck do
    url "https://www.jenkins.io/download/"
    regex(%r{href=.*?/war/v?(\d+(?:\.\d+)+)/jenkins\.war}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "cf00e674ba8e766df164e70bb9aa3859fe31e45f6fe710d1c0578cdb061db401"
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "cf00e674ba8e766df164e70bb9aa3859fe31e45f6fe710d1c0578cdb061db401"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "cf00e674ba8e766df164e70bb9aa3859fe31e45f6fe710d1c0578cdb061db401"
    sha256 cellar: :any_skip_relocation, sonoma:         "cf00e674ba8e766df164e70bb9aa3859fe31e45f6fe710d1c0578cdb061db401"
    sha256 cellar: :any_skip_relocation, ventura:        "cf00e674ba8e766df164e70bb9aa3859fe31e45f6fe710d1c0578cdb061db401"
    sha256 cellar: :any_skip_relocation, monterey:       "cf00e674ba8e766df164e70bb9aa3859fe31e45f6fe710d1c0578cdb061db401"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "186add715eff52b3f3040b53eec52a2e8ae97a780a54c1aa988b3820aa78b64e"
  end

  head do
    url "https://github.com/jenkinsci/jenkins.git", branch: "master"
    depends_on "maven" => :build
  end

  depends_on "openjdk@21"

  def install
    if build.head?
      system "mvn", "clean", "install", "-pl", "war", "-am", "-DskipTests"
    else
      system "#{Formula["openjdk@21"].opt_bin}/jar", "xvf", "jenkins.war"
    end
    libexec.install Dir["**/jenkins.war", "**/cli-#{version}.jar"]
    bin.write_jar_script libexec/"jenkins.war", "jenkins", java_version: "21"
    bin.write_jar_script libexec/"cli-#{version}.jar", "jenkins-cli", java_version: "21"

    (var/"log/jenkins").mkpath
  end

  def caveats
    <<~EOS
      Note: When using launchctl the port will be 8080.
    EOS
  end

  service do
    run [opt_bin/"jenkins", "--httpListenAddress=127.0.0.1", "--httpPort=8080"]
    keep_alive true
    log_path var/"log/jenkins/output.log"
    error_log_path var/"log/jenkins/error.log"
  end

  test do
    ENV["JENKINS_HOME"] = testpath
    ENV.prepend "_JAVA_OPTIONS", "-Djava.io.tmpdir=#{testpath}"

    port = free_port
    fork do
      exec "#{bin}/jenkins --httpPort=#{port}"
    end
    sleep 60

    output = shell_output("curl localhost:#{port}/")
    assert_match(/Welcome to Jenkins!|Unlock Jenkins|Authentication required/, output)
  end
end
